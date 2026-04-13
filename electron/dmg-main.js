// ========== v1.1.67: 统一日志系统 - electron-log ==========
// 立即初始化electron-log（在所有require之前）
const electronLog = require('electron-log');

// 配置基础日志（不依赖app对象）
electronLog.transports.file.level = 'debug';
electronLog.transports.console.level = 'debug';

// ⭐ 使用electron-log的catchErrors捕获所有错误
electronLog.catchErrors({
  showDialog: false,
  onError(error, versions, submitIssue) {
    electronLog.error('========================================');
    electronLog.error('❌ FATAL ERROR CAUGHT:');
    electronLog.error('Error:', error);
    electronLog.error('Stack:', error.stack);
    electronLog.error('Versions:', versions);
    electronLog.error('========================================');
  }
});

electronLog.info('========================================');
electronLog.info('DMG品牌化工具启动');
electronLog.info(`Node版本: ${process.version}`);
electronLog.info(`Electron版本: ${process.versions.electron}`);
electronLog.info(`环境: ${process.env.NODE_ENV}`);
electronLog.info(`__dirname: ${__dirname}`);
electronLog.info('========================================');

const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const fsSync = require('fs'); // 添加同步fs用于设置功能
const { configureLog, getLogPath } = require('./log-config');

// 使用electron-log
let log = electronLog;

const execAsync = promisify(exec);
let mainWindow;

// 配置常量（避免硬编码）
const DMG_CONFIG = {
  FINDER_RESTART_DELAY: 2000,  // Finder重启后等待时间（毫秒）
  DS_STORE_WRITE_DELAY: 3000,  // .DS_Store写入等待时间（毫秒）
};

// ========== electron-log配置延迟到app ready ==========
// 暂时只用console，等app.whenReady()后再配置electron-log
console.log('=== Electron应用启动 ===');
console.log(`Node版本: ${process.version}`);
console.log(`Electron版本: ${process.versions.electron}`);
console.log(`环境: ${process.env.NODE_ENV}`);
console.log(`__dirname: ${__dirname}`);

function createWindow() {
  // 图标路径：开发模式和打包模式不同
  let iconPath;
  if (app.isPackaged) {
    // 打包后：使用Resources目录的icon.icns
    iconPath = path.join(process.resourcesPath, 'icon.icns');
  } else {
    // 开发模式：使用public目录的icon.png
    iconPath = path.join(__dirname, '../public/icon.png');
  }
  
  mainWindow = new BrowserWindow({
    width: 900,
    height: 700,
    minWidth: 800,
    minHeight: 600,
    title: '闲鱼工具箱 - DMG品牌化工具',
    icon: iconPath,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'dmg-preload.js'),
    },
    // macOS样式
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 10, y: 10 },
  });

  // 加载本地HTML
  mainWindow.loadFile(path.join(__dirname, 'dmg-ui.html'));

  // 开发模式打开DevTools
  if (process.env.NODE_ENV !== 'production') {
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// 获取templates目录路径（统一函数，兼容开发和打包环境）
function getTemplatesDir() {
  if (app.isPackaged) {
    return path.join(process.resourcesPath, 'tools/dmg-modifier/templates');
  } else {
    return path.join(__dirname, '../tools/dmg-modifier/templates');
  }
}

// 获取临时DMG路径（统一函数，兼容开发和打包环境）
function getTempDmgPath() {
  if (app.isPackaged) {
    // 打包后：使用系统临时目录
    const os = require('os');
    return path.join(os.tmpdir(), 'dmg-tool-temp-layout-edit.dmg');
  } else {
    // 开发环境：使用项目目录
    return path.join(__dirname, '../tools/dmg-modifier/temp-layout-edit.dmg');
  }
}

// 递归扫描目录，收集DMG与非DMG文件（保持相对路径）
async function collectFolderFiles(rootDir) {
  const dmgFiles = [];
  const otherFiles = [];
  const emptyDirs = [];

  async function walk(currentDir) {
    const entries = await fs.readdir(currentDir, { withFileTypes: true });
    if (entries.length === 0) {
      emptyDirs.push(currentDir);
      return;
    }

    for (const entry of entries) {
      const absPath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        await walk(absPath);
      } else if (entry.isFile()) {
        const relativePath = path.relative(rootDir, absPath);
        if (entry.name.toLowerCase().endsWith('.dmg')) {
          dmgFiles.push({ absPath, relativePath });
        } else {
          otherFiles.push({ absPath, relativePath });
        }
      }
    }
  }

  await walk(rootDir);
  return { dmgFiles, otherFiles, emptyDirs };
}

// 注册IPC处理器
function registerIpcHandlers() {
// 选择DMG文件
ipcMain.handle('select-dmg-file', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: '选择DMG文件',
    filters: [
      { name: 'DMG文件', extensions: ['dmg'] }
    ],
    properties: ['openFile']
  });

  if (result.canceled) {
    return null;
  }

  return result.filePaths[0];
});

// 选择输出目录
ipcMain.handle('select-output-dir', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: '选择输出目录',
    properties: ['openDirectory', 'createDirectory']
  });

  if (result.canceled) {
    return null;
  }

  return result.filePaths[0];
});

// 选择源根目录（目录镜像模式）
ipcMain.handle('select-source-folder', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: '选择上家根目录',
    properties: ['openDirectory']
  });

  if (result.canceled || !result.filePaths[0]) {
    return null;
  }

  return result.filePaths[0];
});

// 处理DMG
ipcMain.handle('process-dmg', async (event, inputPath, outputDir) => {
  try {
    // 获取脚本路径（兼容开发模式和打包模式）
    let scriptPath;
    
    if (app.isPackaged) {
      // 打包模式：使用process.resourcesPath（extraResources目录）
      scriptPath = path.join(process.resourcesPath, 'tools/dmg-modifier/scripts/modify-dmg.sh');
    } else {
      // 开发模式：使用项目根目录
      scriptPath = path.join(__dirname, '../tools/dmg-modifier/scripts/modify-dmg.sh');
    }
    
    console.log('[单文件处理] 脚本路径:', scriptPath);
    console.log('[单文件处理] app.isPackaged:', app.isPackaged);

    
    // 生成输出文件名（避免重复-macsiwen）
    const inputFileName = path.basename(inputPath, '.dmg');
    let outputFileName;
    if (inputFileName.endsWith('-macsiwen')) {
      // 如果已经包含-macsiwen，不重复添加
      outputFileName = `${inputFileName}.dmg`;
    } else {
      outputFileName = `${inputFileName}-macsiwen.dmg`;
    }

    // 发送进度更新
    event.sender.send('progress-update', { progress: 10, message: '开始处理...' });

    // 检查脚本是否存在
    try {
      await fs.access(scriptPath);
    } catch (error) {
      throw new Error(`处理脚本不存在: ${scriptPath}`);
    }

    event.sender.send('progress-update', { progress: 20, message: '转换DMG格式...' });

    // 执行脚本（使用正确的引号避免空格问题）
    const { stdout, stderr } = await execAsync(
      `"${scriptPath}" "${inputPath}" "${outputFileName}"`,
      { 
        cwd: path.dirname(scriptPath),
        maxBuffer: 10 * 1024 * 1024 // 10MB buffer
      }
    );



    console.log('[DMG处理] 脚本输出:', stdout);
    if (stderr) console.error('[DMG处理] 脚本错误:', stderr);

    event.sender.send('progress-update', { progress: 80, message: '移动文件到输出目录...' });

    // 脚本输出文件在 tools/dmg-modifier/output/ 目录
    const scriptOutputPath = path.join(
      path.dirname(scriptPath),
      '../output',
      outputFileName
    );
    
    // 移动到用户选择的目录
    const finalOutputPath = path.join(outputDir, outputFileName);

    try {
      await fs.copyFile(scriptOutputPath, finalOutputPath);
      await fs.unlink(scriptOutputPath); // 删除脚本输出的原文件
    } catch (error) {
      console.error('[DMG处理] 移动文件失败:', error);
      // 如果移动失败，返回脚本输出路径
      return {
        success: true,
        outputPath: scriptOutputPath,
        message: `处理完成！文件保存在: ${scriptOutputPath}`
      };
    }

    event.sender.send('progress-update', { progress: 100, message: '处理完成！' });

    return {
      success: true,
      outputPath: finalOutputPath,
      message: `处理完成！文件保存在: ${finalOutputPath}`
    };

  } catch (error) {
    console.error('[DMG处理] 处理失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// 目录镜像处理：仅修改根目录名，子目录结构与文件名保持不变
ipcMain.handle('process-folder-mirror', async (event, payload) => {
  try {
    const sourceRoot = (payload?.sourceRoot || '').trim();
    const outputParentDir = (payload?.outputParentDir || '').trim();
    const targetRootName = (payload?.targetRootName || '').trim();

    if (!sourceRoot || !outputParentDir || !targetRootName) {
      return { success: false, error: '参数不完整：sourceRoot / outputParentDir / targetRootName' };
    }

    // 基础校验
    try {
      const stat = await fs.stat(sourceRoot);
      if (!stat.isDirectory()) {
        return { success: false, error: '源路径不是目录' };
      }
    } catch (error) {
      return { success: false, error: `源目录不存在: ${sourceRoot}` };
    }

    const targetRoot = path.join(outputParentDir, targetRootName);
    if (path.resolve(sourceRoot) === path.resolve(targetRoot)) {
      return { success: false, error: '目标目录不能与源目录相同' };
    }
    if (fsSync.existsSync(targetRoot)) {
      return { success: false, error: `目标目录已存在，请更换根目录名: ${targetRootName}` };
    }

    const progress = {
      stage: 'init',
      current: '',
      processed: 0,
      total: 1,
      successCount: 0,
      failedCount: 0,
      percent: 0
    };

    const sendMirrorProgress = () => {
      event.sender.send('mirror-progress-update', { ...progress });
    };

    // 扫描目录
    progress.stage = 'scan';
    progress.current = '扫描目录结构...';
    progress.percent = 5;
    sendMirrorProgress();

    const { dmgFiles, otherFiles, emptyDirs } = await collectFolderFiles(sourceRoot);
    const totalTasks = otherFiles.length + dmgFiles.length;
    progress.total = Math.max(totalTasks, 1);

    // 创建目标根目录
    await fs.mkdir(targetRoot, { recursive: true });

    // 先复制非DMG文件（保持路径）
    for (const file of otherFiles) {
      const targetFile = path.join(targetRoot, file.relativePath);
      await fs.mkdir(path.dirname(targetFile), { recursive: true });
      await fs.copyFile(file.absPath, targetFile);

      progress.stage = 'copy';
      progress.current = `复制文件: ${file.relativePath}`;
      progress.processed += 1;
      progress.successCount += 1;
      progress.percent = Math.min(45, Math.floor((progress.processed / progress.total) * 45));
      sendMirrorProgress();
    }

    // 创建空目录（保持目录结构）
    for (const dir of emptyDirs) {
      const relativeDir = path.relative(sourceRoot, dir);
      if (!relativeDir) continue;
      await fs.mkdir(path.join(targetRoot, relativeDir), { recursive: true });
    }

    const failures = [];

    // 处理DMG文件（文件名保持不变）
    for (const file of dmgFiles) {
      try {
        let scriptPath;
        if (app.isPackaged) {
          scriptPath = path.join(process.resourcesPath, 'tools/dmg-modifier/scripts/modify-dmg.sh');
        } else {
          scriptPath = path.join(__dirname, '../tools/dmg-modifier/scripts/modify-dmg.sh');
        }

        await fs.access(scriptPath);

        const outputFileName = path.basename(file.relativePath); // 保持原文件名
        const finalOutputPath = path.join(targetRoot, file.relativePath); // 保持相对路径
        await fs.mkdir(path.dirname(finalOutputPath), { recursive: true });

        // 执行DMG品牌化脚本
        await execAsync(
          `"${scriptPath}" "${file.absPath}" "${outputFileName}"`,
          {
            cwd: path.dirname(scriptPath),
            maxBuffer: 50 * 1024 * 1024,
            timeout: 10 * 60 * 1000
          }
        );

        // 脚本输出文件位于 tools/dmg-modifier/output/
        const scriptOutputPath = path.join(path.dirname(scriptPath), '../output', outputFileName);
        await fs.copyFile(scriptOutputPath, finalOutputPath);
        await fs.unlink(scriptOutputPath);

        progress.successCount += 1;
      } catch (error) {
        failures.push({
          file: file.relativePath,
          error: error.message
        });
        progress.failedCount += 1;
      } finally {
        progress.stage = 'dmg';
        progress.current = `处理DMG: ${file.relativePath}`;
        progress.processed += 1;
        const ratio = progress.processed / progress.total;
        progress.percent = Math.min(95, 45 + Math.floor(ratio * 50));
        sendMirrorProgress();
      }
    }

    progress.stage = 'done';
    progress.current = '目录镜像处理完成';
    progress.percent = 100;
    sendMirrorProgress();

    if (failures.length > 0) {
      return {
        success: false,
        partial: true,
        targetRoot,
        total: progress.total,
        failed: failures.length,
        failures,
        error: `部分失败：${failures.length} 个文件处理失败`
      };
    }

    return {
      success: true,
      targetRoot,
      total: progress.total,
      message: `处理完成：已生成 ${targetRootName}（仅根目录名改变，子路径保持不变）`
    };
  } catch (error) {
    console.error('[目录镜像处理] 失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// 打开文件所在目录
ipcMain.handle('reveal-in-finder', async (event, filePath) => {
  const { shell } = require('electron');
  shell.showItemInFolder(filePath);
});

// ========== v1.1.63 新增：批量处理功能 ==========

// 队列管理
class DmgQueue {
  constructor() {
    this.items = [];
    this.concurrency = 1; // 串行处理（避免temp文件冲突）
    this.processing = new Set();
    this.isPaused = false;
  }

  addFiles(filePaths) {
    const newItems = filePaths.map(filePath => ({
      id: Date.now() + Math.random().toString(36).substr(2, 9),
      fileName: path.basename(filePath),
      filePath: filePath,
      fileSize: 0, // 将在添加时获取
      status: 'pending',
      progress: 0,
      outputPath: null,
      error: null,
      startTime: null,
      endTime: null,
    }));
    
    this.items.push(...newItems);
    return newItems;
  }

  removeFile(id) {
    this.items = this.items.filter(item => item.id !== id);
  }

  clear() {
    this.items = [];
    this.processing.clear();
  }

  getNext() {
    return this.items.find(item => 
      item.status === 'pending' && 
      !this.processing.has(item.id)
    );
  }

  getState() {
    const completedCount = this.items.filter(i => i.status === 'completed').length;
    const failedCount = this.items.filter(i => i.status === 'failed').length;
    const totalProgress = this.items.length > 0
      ? this.items.reduce((sum, item) => sum + item.progress, 0) / this.items.length
      : 0;

    return {
      items: this.items,
      totalCount: this.items.length,
      completedCount,
      failedCount,
      overallProgress: totalProgress,
      isProcessing: this.processing.size > 0 && !this.isPaused,
      isPaused: this.isPaused,
    };
  }
}

const dmgQueue = new DmgQueue();

// 选择多个DMG文件
ipcMain.handle('select-dmg-files', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: '选择DMG文件（可多选）',
    filters: [{ name: 'DMG文件', extensions: ['dmg'] }],
    properties: ['openFile', 'multiSelections'] // 支持多选
  });

  if (result.canceled) {
    return null;
  }

  return result.filePaths;
});

// 选择包含DMG的文件夹
ipcMain.handle('select-dmg-folder', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: '选择包含DMG文件的文件夹',
    properties: ['openDirectory']
  });

  if (result.canceled || !result.filePaths[0]) {
    return null;
  }

  try {
    // 扫描文件夹中的所有.dmg文件
    const files = await fs.readdir(result.filePaths[0]);
    const dmgFiles = files
      .filter(file => file.endsWith('.dmg'))
      .map(file => path.join(result.filePaths[0], file));
    
    return dmgFiles;
  } catch (error) {
    console.error('[扫描文件夹失败]', error);
    return [];
  }
});

// 添加文件到队列
ipcMain.handle('add-to-queue', async (event, filePaths) => {
  try {
    const newItems = dmgQueue.addFiles(filePaths);
    
    // 获取文件大小
    for (const item of newItems) {
      try {
        const stats = await fs.stat(item.filePath);
        item.fileSize = stats.size;
      } catch (error) {
        console.error(`[获取文件大小失败] ${item.fileName}:`, error);
      }
    }
    
    return { success: true, items: newItems };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// 从队列移除文件
ipcMain.handle('remove-from-queue', async (event, id) => {
  dmgQueue.removeFile(id);
  return { success: true };
});

// 清空队列
ipcMain.handle('clear-queue', async () => {
  dmgQueue.clear();
  return { success: true };
});

// 获取队列状态
ipcMain.handle('get-queue-state', async () => {
  return dmgQueue.getState();
});

// 暂停批量处理
ipcMain.handle('pause-batch', async () => {
  dmgQueue.isPaused = true;
  return { success: true };
});

// 继续批量处理
ipcMain.handle('resume-batch', async () => {
  dmgQueue.isPaused = false;
  // 触发继续处理
  if (mainWindow) {
    mainWindow.webContents.send('batch-resume-signal');
  }
  return { success: true };
});

// 处理单个DMG文件（内部方法）
async function processSingleDmgFile(item, outputDir) {
  const inputPath = item.filePath;
  
  try {
    // 获取脚本路径（兼容开发模式和打包模式）
    let scriptPath;
    
    if (app.isPackaged) {
      // 打包模式：使用process.resourcesPath（extraResources目录）
      scriptPath = path.join(process.resourcesPath, 'tools/dmg-modifier/scripts/modify-dmg.sh');
    } else {
      // 开发模式：使用项目根目录
      scriptPath = path.join(__dirname, '../tools/dmg-modifier/scripts/modify-dmg.sh');
    }
    
    console.log('[批量处理] 脚本路径:', scriptPath);
    console.log('[批量处理] app.isPackaged:', app.isPackaged);

    
    // 生成输出文件名
    const inputFileName = path.basename(inputPath, '.dmg');
    let outputFileName;
    if (inputFileName.endsWith('-macsiwen')) {
      outputFileName = `${inputFileName}.dmg`;
    } else {
      outputFileName = `${inputFileName}-macsiwen.dmg`;
    }

    // 更新进度
    item.progress = 10;
    sendBatchProgressUpdate();

    // 检查脚本是否存在
    try {
      await fs.access(scriptPath);
    } catch (error) {
      throw new Error(`处理脚本不存在: ${scriptPath}`);
    }

    item.progress = 20;
    sendBatchProgressUpdate();

    // 执行脚本（捕获完整输出）
    let stdout = '';
    let stderr = '';
    
    try {
      const result = await execAsync(
        `"${scriptPath}" "${inputPath}" "${outputFileName}" 2>&1`,
        { 
          cwd: path.dirname(scriptPath),
          maxBuffer: 50 * 1024 * 1024, // 增加到50MB
          timeout: 300000 // 5分钟超时
        }
      );
      stdout = result.stdout;
      stderr = result.stderr;
      
      console.log(`[DMG处理] ${item.fileName} 执行成功`);
      console.log(`[DMG处理] ${item.fileName} 完整输出:\n`, stdout);
    } catch (error) {
      console.error(`[DMG处理] ${item.fileName} 执行失败:`, error.message);
      console.error(`[DMG处理] ${item.fileName} 完整stdout:\n`, error.stdout);
      console.error(`[DMG处理] ${item.fileName} stderr:`, error.stderr);
      throw error;
    }


    item.progress = 80;
    sendBatchProgressUpdate();

    // 脚本输出文件在 tools/dmg-modifier/output/ 目录
    const scriptOutputPath = path.join(
      path.dirname(scriptPath),
      '../output',
      outputFileName
    );
    
    // 移动到用户选择的目录
    const finalOutputPath = path.join(outputDir, outputFileName);

    try {
      await fs.copyFile(scriptOutputPath, finalOutputPath);
      await fs.unlink(scriptOutputPath);
    } catch (error) {
      console.error(`[DMG处理] ${item.fileName} 移动文件失败:`, error);
      // 如果移动失败，返回脚本输出路径
      return scriptOutputPath;
    }

    item.progress = 100;
    sendBatchProgressUpdate();

    return finalOutputPath;

  } catch (error) {
    console.error(`[DMG处理] ${item.fileName} 处理失败:`, error);
    throw error;
  }
}

// 发送批量进度更新
function sendBatchProgressUpdate() {
  if (mainWindow) {
    mainWindow.webContents.send('batch-progress-update', dmgQueue.getState());
  }
}

// 批量处理DMG
ipcMain.handle('process-batch', async (event, outputDir) => {
  try {
    console.log('[批量处理] 开始处理，输出目录:', outputDir);
    
    // 处理队列中的文件
    async function processNext() {
      // 检查是否暂停
      if (dmgQueue.isPaused) {
        console.log('[批量处理] 已暂停');
        return;
      }

      // 检查并发数
      if (dmgQueue.processing.size >= dmgQueue.concurrency) {
        return;
      }

      // 获取下一个待处理文件
      const item = dmgQueue.getNext();
      if (!item) {
        // 没有待处理文件了
        if (dmgQueue.processing.size === 0) {
          console.log('[批量处理] 全部完成');
          sendBatchProgressUpdate();
        }
        return;
      }

      // 标记为处理中
      item.status = 'processing';
      item.startTime = new Date();
      dmgQueue.processing.add(item.id);
      sendBatchProgressUpdate();

      try {
        // 处理文件
        const outputPath = await processSingleDmgFile(item, outputDir);
        
        item.status = 'completed';
        item.outputPath = outputPath;
        item.endTime = new Date();
        
      } catch (error) {
        item.status = 'failed';
        item.error = error.message;
        item.endTime = new Date();
        
      } finally {
        dmgQueue.processing.delete(item.id);
        sendBatchProgressUpdate();
        
        // 继续处理下一个
        await processNext();
      }
    }

    // 启动并发处理
    const workers = Array(dmgQueue.concurrency)
      .fill(null)
      .map(() => processNext());
    
    await Promise.all(workers);

    console.log('[批量处理] 处理完成');
    return { 
      success: true, 
      message: '批量处理完成',
      state: dmgQueue.getState()
    };

  } catch (error) {
    console.error('[批量处理] 处理失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// ===== v1.1.64 设置功能 IPC Handlers =====

// 选择图片文件
ipcMain.handle('select-image-file', async () => {
  const result = await dialog.showOpenDialog({
    properties: ['openFile'],
    filters: [
      { name: 'Images', extensions: ['png', 'jpg', 'jpeg'] }
    ]
  });
  
  return result.canceled ? null : result.filePaths[0];
});

// 上传背景图（v1.1.65: 简化版，不自动生成）
ipcMain.handle('upload-background', async (event, filePath) => {
  try {
    const templatesDir = getTemplatesDir();
    const targetPath = path.join(templatesDir, 'macsiwen-background.png');
    
    // 确保templates目录存在
    if (!fsSync.existsSync(templatesDir)) {
      fsSync.mkdirSync(templatesDir, { recursive: true });
    }
    
    // 复制文件
    fsSync.copyFileSync(filePath, targetPath);
    console.log('[设置] 背景图上传成功:', targetPath);
    
    return {
      success: true,
      path: targetPath,
      message: '背景图已上传'
    };
    
  } catch (error) {
    console.error('[设置] 背景图上传失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// ===== v1.1.65 新增：手动制作.DS_Store模板功能 =====

// 第1步：选择已处理的DMG并替换背景图+webloc
ipcMain.handle('start-ds-store-creation', async () => {
  try {
    const templatesDir = getTemplatesDir();

    // 检查背景图是否存在（检查默认背景图，不需要上传）
    const bgPath = path.join(templatesDir, 'background.png');
    if (!fsSync.existsSync(bgPath)) {
      return {
        success: false,
        error: 'templates目录缺少默认背景图 background.png'
      };
    }

    // 1. 使用默认模板DMG
    const defaultTemplate = path.join(
      require('os').homedir(),
      'Downloads/dmg测试/原文件',
      '2Do 2.9.2.dmg'
    );
    
    let sourceDmg;
    
    if (fsSync.existsSync(defaultTemplate)) {
      // 使用默认模板
      sourceDmg = defaultTemplate;
      console.log('[.DS_Store制作] 使用默认模板:', sourceDmg);
    } else {
      // 如果默认模板不存在，让用户选择
      const result = await dialog.showOpenDialog(mainWindow, {
        title: '默认模板不存在，请选择DMG',
        filters: [{ name: 'DMG文件', extensions: ['dmg'] }],
        properties: ['openFile'],
        message: '选择布局良好的DMG作为模板'
      });
      
      if (result.canceled || !result.filePaths[0]) {
        return {
          success: false,
          error: '未选择DMG文件'
        };
      }
      
      sourceDmg = result.filePaths[0];
    }
    console.log('[.DS_Store制作] 选择的DMG:', sourceDmg);
    
    // 2. 先检查DMG是否已挂载，如果已挂载则卸载
    try {
      const { stdout: mountCheck } = await execAsync(`hdiutil info | grep "${sourceDmg}"`);
      if (mountCheck) {
        console.log('[.DS_Store制作] 检测到DMG已挂载，尝试卸载...');
        await execAsync(`hdiutil detach "${mountCheck.match(/\/Volumes\/[^\s]+/)?.[0]}" -force`);
      }
    } catch (error) {
      // 如果没有挂载或grep没找到，忽略错误
    }
    
    // 3. 转换为可读写格式（临时）
    const tempDmgPath = getTempDmgPath();
    
    // 删除旧的临时文件
    if (fsSync.existsSync(tempDmgPath)) {
      fsSync.unlinkSync(tempDmgPath);
    }
    
    console.log('[.DS_Store制作] 转换DMG为可读写格式...');
    const convertCmd = `hdiutil convert "${sourceDmg}" -format UDRW -o "${tempDmgPath.replace('.dmg', '')}"`;
    console.log('[.DS_Store制作] 转换命令:', convertCmd);
    
    const { stdout: convertOut } = await execAsync(convertCmd, {
      maxBuffer: 50 * 1024 * 1024
    });
    console.log('[.DS_Store制作] 转换完成:', convertOut);
    
    // hdiutil convert会自动添加.dmg后缀，检查实际文件
    const actualTempPath = fsSync.existsSync(tempDmgPath) ? tempDmgPath : `${tempDmgPath.replace('.dmg', '')}.dmg`;
    console.log('[.DS_Store制作] 实际临时文件:', actualTempPath);
    
    // 3. 挂载（可读写，禁用所有验证）
    console.log('[.DS_Store制作] 挂载DMG...');
    const mountCmd = `hdiutil attach "${actualTempPath}" -readwrite -noverify -noautoopen -nobrowse`;
    console.log('[.DS_Store制作] 挂载命令:', mountCmd);
    
    const { stdout } = await execAsync(mountCmd, {
      maxBuffer: 10 * 1024 * 1024
    });
    console.log('[.DS_Store制作] 挂载输出:', stdout);
    
    // 解析挂载点（处理带空格的卷名）
    const mountLine = stdout.split('\n').find(line => line.includes('/Volumes/'));
    console.log('[.DS_Store制作] 挂载行:', mountLine);
    
    // 从最后一个制表符后提取挂载点
    const mountPoint = mountLine?.split('\t').pop()?.trim();
    
    if (!mountPoint) {
      throw new Error('无法获取挂载点');
    }
    
    console.log('[.DS_Store制作] 挂载点:', mountPoint);
    
    // 4. 替换背景图
    const bgDir1 = path.join(mountPoint, '.background');
    const bgDir2 = path.join(mountPoint, '.DropDMGBackground');
    
    if (fsSync.existsSync(bgDir1)) {
      // 标准.background目录
      fsSync.copyFileSync(bgPath, path.join(bgDir1, 'background.png'));
      console.log('[.DS_Store制作] 已替换.background/background.png');
    } else if (fsSync.existsSync(bgDir2)) {
      // DropDMG目录 - 需要保持原文件名
      // 先查找原背景图文件（可能是.tiff/.png）
      const bgFiles = fsSync.readdirSync(bgDir2).filter(f => f.startsWith('background'));
      
      // 删除所有旧背景图
      bgFiles.forEach(file => {
        fsSync.unlinkSync(path.join(bgDir2, file));
        console.log(`[.DS_Store制作] 删除旧背景图: ${file}`);
      });
      
      // 如果原背景图是TIFF格式，需要转换PNG为TIFF
      const targetName = bgFiles[0] || 'background.tiff';
      const targetPath = path.join(bgDir2, targetName);
      
      if (targetName.endsWith('.tiff') || targetName.endsWith('.tif')) {
        // 使用sips转换PNG为TIFF
        console.log('[.DS_Store制作] 转换PNG为TIFF格式...');
        try {
          await execAsync(`sips -s format tiff "${bgPath}" --out "${targetPath}"`);
          console.log(`[.DS_Store制作] 已转换并替换.DropDMGBackground/${targetName}`);
        } catch (error) {
          console.error('[.DS_Store制作] 转换失败，直接复制:', error.message);
          fsSync.copyFileSync(bgPath, targetPath);
        }
      } else {
        // 直接复制（PNG格式）
        fsSync.copyFileSync(bgPath, targetPath);
        console.log(`[.DS_Store制作] 已替换.DropDMGBackground/${targetName}`);
      }
    } else {
      // 如果都不存在，创建.background目录
      fsSync.mkdirSync(bgDir1, { recursive: true });
      fsSync.copyFileSync(bgPath, path.join(bgDir1, 'background.png'));
      console.log('[.DS_Store制作] 已创建.background/并复制背景图');
    }
    
    // 5. 替换webloc文件
    const files = fsSync.readdirSync(mountPoint);
    const weblocFiles = files.filter(f => f.endsWith('.webloc'));
    
    // 删除上家的webloc文件
    weblocFiles.forEach(file => {
      const filePath = path.join(mountPoint, file);
      fsSync.unlinkSync(filePath);
      console.log(`[.DS_Store制作] 删除上家网址: ${file}`);
    });
    
    // 添加我们的webloc文件
    const ourWebloc = path.join(templatesDir, '访问macsiwen.cc.webloc');
    if (fsSync.existsSync(ourWebloc)) {
      fsSync.copyFileSync(ourWebloc, path.join(mountPoint, '访问macsiwen.cc.webloc'));
      console.log('[.DS_Store制作] 已添加我们的网址');
    }
    
    // 6. 清除Finder缓存并打开窗口
    console.log('[.DS_Store制作] 清除Finder缓存...');
    try {
      // 删除挂载点的.DS_Store（如果存在）
      const dsStorePath = path.join(mountPoint, '.DS_Store');
      if (fsSync.existsSync(dsStorePath)) {
        fsSync.unlinkSync(dsStorePath);
        console.log('[.DS_Store制作] 已删除旧.DS_Store');
      }
      
      // 重启Finder以清除缓存
      await execAsync('killall Finder');
      console.log('[.DS_Store制作] Finder已重启');
      
      // 等待Finder重启
      await new Promise(resolve => setTimeout(resolve, DMG_CONFIG.FINDER_RESTART_DELAY));
    } catch (error) {
      console.warn('[.DS_Store制作] 清除缓存失败（继续）:', error.message);
    }
    
    // 打开Finder窗口
    await execAsync(`open "${mountPoint}"`);
    
    console.log('[.DS_Store制作] Finder窗口已打开（缓存已清除）');
    
    return {
      success: true,
      mountPoint: mountPoint,
      tempDmg: tempDmgPath,
      sourceDmg: path.basename(sourceDmg),
      message: `已打开 ${path.basename(sourceDmg)}，请在Finder中调整布局`
    };
    
  } catch (error) {
    console.error('[.DS_Store制作] 创建失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// 第2步：提取.DS_Store并清理
ipcMain.handle('finish-ds-store-creation', async (event, mountPoint) => {
  try {
    const templatesDir = getTemplatesDir();
    const tempDmgPath = getTempDmgPath();
    
    // 等待Finder写入.DS_Store
    console.log(`[.DS_Store制作] 等待Finder写入.DS_Store（${DMG_CONFIG.DS_STORE_WRITE_DELAY / 1000}秒）...`);
    await new Promise(resolve => setTimeout(resolve, DMG_CONFIG.DS_STORE_WRITE_DELAY));
    
    // 检查.DS_Store是否存在
    const dsStorePath = path.join(mountPoint, '.DS_Store');
    if (!fsSync.existsSync(dsStorePath)) {
      return {
        success: false,
        error: '.DS_Store文件不存在，请确保已在Finder中设置背景并关闭窗口'
      };
    }
    
    console.log('[.DS_Store制作] .DS_Store已找到');
    
    // 验证.DS_Store引用的路径
    try {
      const { stdout } = await execAsync(`strings "${dsStorePath}" | grep -i background`);
      console.log('[.DS_Store制作] .DS_Store内容检查:', stdout);
      
      if (stdout.includes('/Desktop/') || stdout.includes('/Users/')) {
        console.warn('[.DS_Store制作] ⚠️  检测到绝对路径，可能设置不正确');
      }
    } catch (error) {
      // strings命令可能失败，但可以继续
    }
    
    // 复制.DS_Store到模板目录
    fsSync.copyFileSync(dsStorePath, path.join(templatesDir, '.DS_Store'));
    
    console.log('[.DS_Store制作] .DS_Store已复制到模板目录');
    
    // 卸载DMG
    try {
      await execAsync(`hdiutil detach "${mountPoint}" -force`);
      console.log('[.DS_Store制作] DMG已卸载');
    } catch (error) {
      console.warn('[.DS_Store制作] 卸载DMG失败:', error.message);
    }
    
    // 删除临时DMG
    if (fsSync.existsSync(tempDmgPath)) {
      fsSync.unlinkSync(tempDmgPath);
      console.log('[.DS_Store制作] 临时文件已清理');
    }
    
    return {
      success: true,
      message: '.DS_Store模板制作成功！'
    };
    
  } catch (error) {
    console.error('[.DS_Store制作] 完成失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// 取消.DS_Store制作（清理）
ipcMain.handle('cancel-ds-store-creation', async (event, mountPoint) => {
  try {
    const tempDmgPath = getTempDmgPath();
    
    // 尝试卸载DMG
    if (mountPoint) {
      try {
        await execAsync(`hdiutil detach "${mountPoint}" -force`);
        console.log('[.DS_Store制作] 已取消，DMG已卸载');
      } catch (error) {
        console.warn('[.DS_Store制作] 卸载DMG失败:', error.message);
      }
    }
    
    // 删除临时DMG
    if (fsSync.existsSync(tempDmgPath)) {
      fsSync.unlinkSync(tempDmgPath);
      console.log('[.DS_Store制作] 临时文件已清理');
    }
    
    return {
      success: true,
      message: '已取消操作'
    };
    
  } catch (error) {
    console.error('[.DS_Store制作] 取消失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// 恢复默认背景
ipcMain.handle('reset-background', async () => {
  try {
    const templatesDir = getTemplatesDir();
    const backgroundPath = path.join(templatesDir, 'background.png');
    
    // 删除自定义背景图（如果存在）
    if (fsSync.existsSync(backgroundPath)) {
      // 备份一下
      const backupPath = backgroundPath + '.backup';
      if (fsSync.existsSync(backupPath)) {
        fsSync.copyFileSync(backupPath, backgroundPath);
        console.log('[设置] 已恢复默认背景图');
      } else {
        // 如果没有备份，就删除（使用脚本内置的默认背景）
        fsSync.unlinkSync(backgroundPath);
        console.log('[设置] 已删除自定义背景图，将使用默认背景');
      }
    }
    
    return {
      success: true
    };
  } catch (error) {
    console.error('[设置] 恢复默认背景失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// 保存网站设置
ipcMain.handle('save-website-settings', async (event, settings) => {
  try {
    const { name, url } = settings;
    const templatesDir = getTemplatesDir();
    
    // 确保templates目录存在
    if (!fsSync.existsSync(templatesDir)) {
      fsSync.mkdirSync(templatesDir, { recursive: true });
    }
    
    // 生成webloc文件内容
    const weblocContent = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>URL</key>
\t<string>${url}</string>
</dict>
</plist>`;
    
    // 保存webloc文件
    const weblocPath = path.join(templatesDir, `${name}.webloc`);
    fsSync.writeFileSync(weblocPath, weblocContent, 'utf8');
    
    console.log('[设置] 网站设置保存成功:', weblocPath);
    
    return {
      success: true,
      path: weblocPath
    };
  } catch (error) {
    console.error('[设置] 网站设置保存失败:', error);
    return {
      success: false,
      error: error.message
    };
  }
});
}

// ========== 初始化electron-log ==========
app.whenReady().then(() => {
  // 初始化electron-log配置（必须在app.whenReady()之后）
  log = configureLog();
  log.info('✅ app.whenReady()回调执行');
  log.info(`app对象类型: ${typeof app}`);
  
  registerIpcHandlers();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    log.info('[Electron] 所有窗口关闭，应用退出');
    app.quit();
  }
});

// 应用退出前记录日志
app.on('before-quit', () => {
  log.info('[Electron] 应用即将退出');
});
