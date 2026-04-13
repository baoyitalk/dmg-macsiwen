/**
 * electron-log配置
 * 目标：确保开发和生产环境的日志都可见、可追踪
 */

const log = require('electron-log');
const path = require('path');

/**
 * 配置electron-log
 * 必须在app.whenReady()之后调用
 */
function configureLog() {
  const isDev = process.env.NODE_ENV !== 'production';
  
  // 在函数内部require app，确保在app.whenReady()之后调用
  const { app } = require('electron');
  
  // ========== 日志路径配置 ==========
  if (isDev) {
    // 开发模式：日志保存在项目根目录
    const projectRoot = path.resolve(__dirname, '..');
    log.transports.file.resolvePathFn = () => path.join(projectRoot, 'logs', 'electron', 'dev.log');
    console.log('[electron-log] 开发模式日志路径:', log.transports.file.getFile().path);
  } else {
    // 生产模式：使用electron-log默认路径
    // macOS: ~/Library/Logs/{app name}/main.log
    // Windows: %USERPROFILE%\AppData\Roaming\{app name}\logs\main.log
    // Linux: ~/.config/{app name}/logs/main.log
    console.log('[electron-log] 生产模式日志路径:', log.transports.file.getFile().path);
  }
  
  // ========== 日志级别配置 ==========
  log.transports.file.level = 'info';  // 文件日志级别
  log.transports.console.level = isDev ? 'debug' : 'info';  // 控制台日志级别
  
  // ========== 日志格式配置 ==========
  log.transports.file.format = '[{y}-{m}-{d} {h}:{i}:{s}.{ms}] [{level}] {text}';
  log.transports.console.format = '[{h}:{i}:{s}.{ms}] [{level}] {text}';
  
  // ========== 日志文件大小限制 ==========
  log.transports.file.maxSize = 10 * 1024 * 1024;  // 10MB
  
  // ========== 记录配置完成 ==========
  log.info('========================================');
  log.info('electron-log配置完成');
  log.info(`环境: ${isDev ? '开发' : '生产'}`);
  log.info(`日志路径: ${log.transports.file.getFile().path}`);
  log.info(`文件日志级别: ${log.transports.file.level}`);
  log.info(`控制台日志级别: ${log.transports.console.level}`);
  log.info('========================================');
  
  return log;
}

/**
 * 获取日志文件路径（用于文档和调试）
 */
function getLogPath() {
  return log.transports.file.getFile().path;
}

module.exports = {
  configureLog,
  getLogPath
};