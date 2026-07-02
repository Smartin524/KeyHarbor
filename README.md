# 快捷虾

快捷虾是一个原生 macOS 菜单栏快捷切换工具。默认快捷键：

- `Option + W`：打开或切到 WeChat
- `Option + C`：打开或切到 Codex
- `Option + Command`：唤起快捷虾面板
- `Option + Space`：显示桌面；如果已经在桌面，则回到上一个前台 App

设置窗口是一张轻量化的模糊透明键盘。已绑定的按键会直接显示目标 App 图标，双击任意可绑定按键即可选择 App；`Option + Space` 保留为显示/返回桌面；底部可清除当前绑定。

## 构建

```bash
swift build
```

## 打包本机可运行 App

```bash
bash Scripts/make_icns.sh
bash Scripts/package_app.sh
open dist/快捷虾.app
```

## 安装到应用程序

```bash
bash Scripts/install_app.sh
```

安装后会复制到 `/Applications/快捷虾.app`，应用选择器和 Finder 的“应用程序”里都能看到。打开后会自动弹出键盘设置窗口。之后也可以从屏幕右上角菜单栏的「快捷虾」入口重新打开设置。应用会默认尝试开启 macOS 登录项；若系统提示需要确认，请在系统设置的登录项里允许快捷虾。

首次启动或用快捷键切换 App 时，系统可能会提示授予“辅助功能”权限。允许后，快捷虾可以监听 `Option + Command` 修饰键组合，并在跳转到目标桌面后把目标 App 的窗口抬到最前并聚焦。

图标源文件在 `Assets/`：

- `AppIcon-light.png`：当前应用图标源图
- `AppIcon-dark.png`：暗色版备用源图
- `AppIcon.icns`：打包进 `.app` 的 macOS 图标

首版使用本机 ad-hoc 签名，不包含 App Store 发布、notarization 或正式签名流程。
