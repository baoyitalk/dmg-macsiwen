const { contextBridge, ipcRenderer } = require('electron');

// 暴露安全的API给渲染进程
contextBridge.exposeInMainWorld('electronAPI', {
  // ===== 现有单文件处理 API（保持不变） =====
  selectDmgFile: () => ipcRenderer.invoke('select-dmg-file'),
  selectOutputDir: () => ipcRenderer.invoke('select-output-dir'),
  listTemplates: () => ipcRenderer.invoke('list-templates'),
  processDmg: (inputPath, outputDir, templateId = 'default') =>
    ipcRenderer.invoke('process-dmg', inputPath, outputDir, templateId),
  revealInFinder: (filePath) => ipcRenderer.invoke('reveal-in-finder', filePath),
  onProgressUpdate: (callback) => {
    ipcRenderer.on('progress-update', (event, data) => callback(data));
  },
  
  // ===== v1.1.63 新增：批量处理 API =====
  selectDmgFiles: () => ipcRenderer.invoke('select-dmg-files'),
  selectDmgFolder: () => ipcRenderer.invoke('select-dmg-folder'),
  addToQueue: (filePaths) => ipcRenderer.invoke('add-to-queue', filePaths),
  removeFromQueue: (id) => ipcRenderer.invoke('remove-from-queue', id),
  clearQueue: () => ipcRenderer.invoke('clear-queue'),
  getQueueState: () => ipcRenderer.invoke('get-queue-state'),
  processBatch: (outputDir, templateId = 'default') =>
    ipcRenderer.invoke('process-batch', outputDir, templateId),
  pauseBatch: () => ipcRenderer.invoke('pause-batch'),
  resumeBatch: () => ipcRenderer.invoke('resume-batch'),
  onBatchProgressUpdate: (callback) => {
    ipcRenderer.on('batch-progress-update', (event, data) => callback(data));
  },

  // ===== v1.1.66 新增：目录镜像处理（仅根目录改名） =====
  selectSourceFolder: () => ipcRenderer.invoke('select-source-folder'),
  processFolderMirror: (payload) => ipcRenderer.invoke('process-folder-mirror', payload),
  onMirrorProgressUpdate: (callback) => {
    ipcRenderer.on('mirror-progress-update', (event, data) => callback(data));
  },
  
  // ===== v1.1.64 新增：设置功能 API =====
  selectImageFile: () => ipcRenderer.invoke('select-image-file'),
  uploadBackground: (filePath) => ipcRenderer.invoke('upload-background', filePath),
  resetBackground: () => ipcRenderer.invoke('reset-background'),
  saveWebsiteSettings: (settings) => ipcRenderer.invoke('save-website-settings', settings),
  
  // ===== v1.1.65 新增：.DS_Store模板制作 API =====
  dsStore: {
    start: () => ipcRenderer.invoke('start-ds-store-creation'),
    finish: (mountPoint) => ipcRenderer.invoke('finish-ds-store-creation', mountPoint),
    cancel: (mountPoint) => ipcRenderer.invoke('cancel-ds-store-creation', mountPoint),
  },
  
  // 平台信息
  platform: process.platform,
  version: process.versions.electron,
});
