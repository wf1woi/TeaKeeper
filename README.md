# TeaKeeper

[English](README_EN.md)

TeaKeeper 是一款轻量的 macOS 菜单栏防休眠工具。它可以在屏幕正常熄灭的同时让 Mac 和后台任务继续运行，也可以按需让屏幕保持常亮。

> 当前版本：`0.1.2`（Build 5）
>
> 系统要求：macOS 13.0 或更高版本，Apple Silicon

### 功能

- 防止 Mac 因空闲自动进入系统休眠。
- 默认允许屏幕按 macOS 的节能设置正常熄灭，后台任务仍可继续运行。
- 可选择禁止屏幕休眠，使屏幕保持常亮。
- 支持无限时长，以及 5 分钟到 12 小时的定时防休眠。
- 支持按时间段和星期自动开启、关闭防休眠。
- 支持登录时启动 TeaKeeper，以及应用启动时自动开启防休眠。
- 可在电池电量低于 20% 时自动停止防休眠。
- 可选择左键单击菜单栏图标，快速开启或关闭防休眠。
- 可选择合盖时保持主机运行；合盖后内置屏幕始终允许休眠。
- 菜单界面根据 macOS 首选语言自动显示简体中文或英文。

### 安装

1. 从 [Releases](https://github.com/wf1woi/TeaKeeper/releases/latest) 下载 `TeaKeeper.app.zip`。
2. 解压后，将 `TeaKeeper.app` 移动到“应用程序”文件夹。
3. 首次启动时，如果 macOS 提示无法验证开发者，请在 Finder 中右键点击 TeaKeeper，选择“打开”，然后再次确认。

当前安装包尚未使用 Developer ID 签名或经过 Apple 公证，因此首次启动会出现 Gatekeeper 提示。

### 使用方法

TeaKeeper 启动后只显示在菜单栏，不会显示 Dock 图标。

1. 右键点击菜单栏中的茶杯图标，打开功能菜单。
2. 点击“开启防休眠”，Mac 将保持运行。
3. 默认勾选“允许屏幕休眠（主机保持唤醒）”。此时屏幕可以正常变黑，但 Mac 不会因空闲而休眠，下载、编译和 Codex 等后台任务可以继续执行。
4. 取消勾选“允许屏幕休眠”后，TeaKeeper 会同时让屏幕保持常亮。
5. 可在“持续时间”或“定时防休眠”中设置自动停止时间。
6. 点击“关闭防休眠”或退出 TeaKeeper，即可释放由应用创建的电源断言。

如果开启了“单击图标开启/关闭防休眠”，左键点击菜单栏图标即可切换状态；右键始终打开菜单。

### 休眠行为说明

- **屏幕变黑不等于系统休眠。** 开启防休眠并允许屏幕休眠时，屏幕可以熄灭，Mac 和后台任务仍会继续运行。
- **默认允许屏幕休眠。** TeaKeeper 不会改变 macOS 中设置的屏幕关闭时间。
- **合盖安全优先。** 即使选择合盖时保持主机运行，TeaKeeper 也不会强制点亮已合盖 Mac 的内置屏幕。
- “合盖时主机保持运行”受机型、电源状态、外接显示器和 macOS 电源策略影响，不能替代 Apple 官方支持的合盖工作条件。

### 日志

运行日志保存在：

```text
~/Library/Logs/TeaKeeper/TeaKeeper.log
```

日志达到约 512 KB 后会轮转为 `TeaKeeper.old.log`，便于排查防休眠断言或系统唤醒问题。

### 从源码构建

```bash
git clone https://github.com/wf1woi/TeaKeeper.git
cd TeaKeeper
./work/TeaKeeper/test.sh
./work/TeaKeeper/build.sh
```

构建后的应用位于 `outputs/TeaKeeper.app`。当前构建脚本生成 Apple Silicon 版本，并使用 ad-hoc 签名。
