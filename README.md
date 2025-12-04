# Cadence Capture SVN 插件

为 Cadence Capture CIS 17.2 提供 SVN 版本控制集成的浮动工具栏插件。

## 功能特性

- ✅ **SVN 更新 (Update)** - 快速更新设计文件
- ✅ **SVN 提交 (Commit)** - 提交设计变更
- ✅ **SVN 清理 (Cleanup)** - 清理 SVN 工作区
- ✅ **浮动工具栏** - 轻量级界面，自动定位在屏幕右下角
- ✅ **自动检测** - 自动识别 SVN 工作区和 TortoiseSVN
- ✅ **快捷键支持** - Ctrl+U (更新), Ctrl+M (提交)
- ✅ **自动启动** - 随 Cadence Capture 自动加载

## 安装方法

### 方式一：可执行程序（推荐）
1. 双击 `CadenceTool\Cadence Tool.exe`
2. 选择 `[1] Install`
3. 重启 Cadence Capture

### 方式二：独立安装包
1. 双击 `CadenceSVNPlugin_Standalone.bat`
2. 选择 `[1] Install`
3. 重启 Cadence Capture

## 使用说明

启动 Cadence Capture 后，工具栏自动出现在屏幕右下角：

- **U** - 更新当前设计
- **C** - 提交当前设计
- **L** - 清理工作区
- **S** - 设置选项

或使用菜单：**Tools > SVN Tools**

## 卸载

### 方法一：使用安装程序
1. 运行 `CadenceTool\Cadence Tool.exe`
2. 选择 `[2] Uninstall`

### 方法二：使用卸载器
运行 `CadenceSVNPlugin_Uninstaller.bat`

## 系统要求

- **Cadence Capture CIS 17.2** (SPB 17.2-2016)
- **TortoiseSVN 1.9+**
- **Windows 7/10/11**

## 开发构建

```powershell
.\build_all.bat
```

生成文件：
- `CadenceSVNPlugin_Standalone.bat` - 独立安装包 (44 KB)
- `CadenceTool\Cadence Tool.exe` - 可执行安装程序 (49 KB)

## 项目结构

```
cadenceplug/
├── CaptureMenuPlugin.tcl           # 主程序脚本
├── CaptureMenuPlugin.men           # 菜单定义文件
├── build_all.bat                   # 一键构建脚本
├── build_standalone.bat            # 构建独立安装包
├── build_exe_simple.ps1            # 构建可执行程序
├── installer_template.bat          # 安装程序模板
├── app.ico                         # 程序图标
├── CadenceSVNPlugin_Standalone.bat # 独立安装包
├── CadenceSVNPlugin_Uninstaller.bat# 卸载程序
├── CadenceTool/                    # 可执行程序目录
│   ├── Cadence Tool.exe           # 安装程序
│   └── README.txt                 # 使用说明
├── archive/                        # 归档文件
└── README.md                       # 本文件
```

## 技术实现

- **语言**: TCL 8.6.0 + Tk
- **SVN 集成**: TortoiseSVN GUI
- **打包**: PowerShell + C# 编译器 (csc.exe)
- **编码**: UTF-8 without BOM

## 版本历史

### v1.1 (2025-12-04)
- ✅ 新增 SVN Show Log 功能（查看历史记录）
- ✅ 新增鼠标悬停提示功能
- ✅ 优化工具栏尺寸为 130×25
- ✅ 完善中英文使用文档
- ✅ 添加作者信息

### v1.0 (2025-12-04)
- ✅ 初始发布
- ✅ 基础 SVN 功能（更新、提交、清理）
- ✅ 浮动工具栏界面
- ✅ 自动安装/卸载
- ✅ 可执行程序打包
- ✅ 自动检测任务栏高度
- ✅ 屏幕右下角智能定位

## 许可证

Free to use and modify.
