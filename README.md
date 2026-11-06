# QQ Bot on Termux

[![Platform](https://img.shields.io/badge/Platform-Android%207%2B%20%2F%20arm64-3DDC84?logo=android&logoColor=white)](#supported-versions)
[![Termux](https://img.shields.io/badge/Termux-F--Droid-black?logo=gnubash&logoColor=white)](https://f-droid.org/packages/com.termux/)
[![MaiBot](https://img.shields.io/badge/MaiBot-1.3.x-blue)](https://github.com/Mai-with-u/MaiBot)
[![NapCat](https://img.shields.io/badge/NapCat-4.x-orange)](https://github.com/NapNeko/NapCatQQ)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen)](#contributing)

## Introduction

在 Android 手机上用 Termux 跑一个完整的 QQ 机器人 —— **MaiBot（麦麦）** 当大脑，**NapCat** 当 QQ 协议端。

> 一条 `install.sh` 完成从零到能聊天：自动创建 Ubuntu 容器、装依赖、装 QQ、部署 NapCat 与麦麦、写入配置、生成启动脚本。
>
> 不需要 root，不需要电脑，不需要额外启动器。整套约 2.2 GB。

```
QQ 客户端(Linux QQ)  →  NapCat(协议端)  →  统一QQ连接器(插件)  →  MaiBot(大脑)
                              OneBot v11 WebSocket :3001
```

> [!WARNING]
> **使用前必读**：本项目部署的是**非官方** QQ 协议端，可能违反腾讯服务条款，**导致账号被限制或封禁**。
> 请使用**小号**测试，严禁用于群发、诈骗、绕过风控等用途。
> 完整条款见 **[DISCLAIMER.md](DISCLAIMER.md)**。本项目与腾讯公司无任何隶属或合作关系。

## Features

- **一键部署** —— `bash install.sh` 跑完即可用，中途交互式询问 QQ 号 / 接口地址 / API Key / 模型 ID
- **免 root** —— 全部跑在 proot-distro 的 Ubuntu 容器里
- **国内网络优化** —— apt / PyPI 自动切国内镜像，下载超时自动重试
- **完整排障文档** —— [16 个实际踩过的坑](docs/TROUBLESHOOTING.md)都记录了现象、原因和解法
- **后台可管理** —— 麦麦 WebUI（8001）与 NapCat WebUI（6099）都能在手机浏览器打开
- **开机自启** —— 配合 Termux:Boot 实现重启后自动上线

## Supported Versions

| 项 | 要求 |
|---|---|
| 系统 | Android 7.0+ |
| 架构 | **arm64**（捆绑的 QQ 安装包为 aarch64） |
| 存储 | ≥ 3 GB 可用 |
| 内存 | ≥ 3 GB |
| Termux | F-Droid 版或 GitHub Releases 版（**不要用 Play 商店版**） |

## Install

> ⚠️ **国内网络必读**：不换源的话 `pkg install` 只有几 KB/s，装个 git 要十分钟。

### 1. 装 Termux

从 [F-Droid](https://f-droid.org/packages/com.termux/) 或 [GitHub Releases](https://github.com/termux/termux-app/releases) 安装，**不要用 Play 商店版**。

### 2. 换 Termux 源

```bash
termux-change-repo
# 方向键选 Main repository → 空格选中 → 回车 → 选「Mirrors in China」里的清华 / 北外
```

TUI 不好操作就直接写源：

```bash
echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list
rm -rf $PREFIX/var/lib/apt/lists/*
```

### 3. 取代码并部署

**方式 A：一键脚本（推荐，不需要 Termux 的 git）**

```bash
pkg update -y && termux-setup-storage && termux-wake-lock
bash <(curl -sL https://raw.githubusercontent.com/ENDDREAM-ZM/qqbot-termux/main/get.sh)
```

`get.sh` 会**先检查本地、再比对版本**，不是无脑下载也不是无脑用旧的：

| 情况 | 行为 |
|---|---|
| 本地没有 | 下载约 62 MB |
| 本地版本 = 线上 | 直接用本地，**不联网** |
| 本地版本 < 线上 | 自动下载新版 |
| 查不到线上（没网） | 用本地，并提示 |
| `--local` | 强制只用本地 |
| `--force` | 强制重新下载 |

离线包里**已包含 Ubuntu rootfs**，即使连不上 GitHub 也能装。
下载慢可以加加速前缀：`GH_PROXY=https://ghfast.top/ bash <(curl -sL ...)`

**方式 B：git clone（想 `git pull` 更新才需要）**

```bash
pkg install -y git
git clone https://ghfast.top/https://github.com/ENDDREAM-ZM/qqbot-termux.git
cd qqbot-termux && bash install.sh
```

> 用 git clone 时仓库里**没有** Ubuntu rootfs，如果连不上 GitHub 装不了容器，
> 需要自己下一个 `ubuntu-base-24.04.x-base-arm64.tar.gz` 放进「下载」目录
> （国内镜像：<https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu-base/releases/24.04/release/>）

### 4. 按提示填配置

安装脚本会依次问你：机器人 QQ 号、模型接口地址、API Key、模型 ID（都可回车跳过）。

### 5. 启动（首次会自动引导扫码）

```bash
bash ~/qqbot.sh
```

- **有登录态** → 快速登录，约 20 秒就绪
- **没有 / 已失效** → 自动转扫码，终端提示二维码位置，并**自动复制到手机「下载」目录**（`qqbot-qr.png`）
  手机 QQ →「+」→ 扫一扫 → 右下角**相册** → 选它 → 确认登录

登录成功后终端只打印一次：

```
==================================================
  ✅ 机器人已经登录成功了，请去 MaiBot 后台进行设置以进行使用
  麦麦后台  : http://127.0.0.1:8001
  NapCat后台: http://127.0.0.1:6099/webui?token=xxx
==================================================
```

之后**不再刷消息**——NapCat 的所有输出都写进 `/tmp/napcat.log`，终端只留 5 分钟一次的心跳。
需要看实时消息时：

```bash
proot-distro login ubuntu -- tail -f /tmp/napcat.log
```

**详细步骤见 [docs/INSTALL.md](docs/INSTALL.md)**。

## Download

| 方式 | 大小 | 说明 |
|---|---|---|
| **Release 离线包** | 约 62 MB | `qqbot-termux-repo.tar.gz`，**内含 Ubuntu rootfs**，解压即用，不需要 git、不需要连 GitHub 装容器 |
| **git clone** | 约 113 MB | 方便 `git pull` 更新；但仓库里没有 rootfs，在线装容器失败时要自己下一个 |

> 两者内容一致，只有 rootfs 与 `.git` 的差别。

## Usage

| 操作 | 命令 |
|---|---|
| 启动 | `bash ~/qqbot.sh` |
| 看麦麦日志 | `proot-distro login ubuntu -- tail -f /tmp/maibot.log` |
| 看 NapCat 日志 | `proot-distro login ubuntu -- tail -f /tmp/napcat.log` |
| 停止 | `proot-distro login ubuntu -- bash -c 'pkill -9 -x qq; pkill -9 -x maibot'` |
| 重新扫码 | `proot-distro login ubuntu -- bash -c 'rm -rf ~/.config/QQ && cd /opt/napcat-install && bash launcher.sh'` |

后台面板（手机浏览器直接打开）：

- 麦麦：`http://127.0.0.1:8001`
- NapCat：`http://127.0.0.1:6099/webui?token=<启动时打印的 token>`

## Auto-start

配合 [Termux:Boot](https://f-droid.org/packages/com.termux.boot/) 实现开机自动上线。

### 配置

1. 安装 Termux:Boot 并**点开一次**（不打开的话 Android 不会注册开机广播）
2. Termux 里执行：

```bash
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/qqbot.sh <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sleep 60
bash "$HOME/qqbot.sh"
EOS
chmod +x ~/.termux/boot/qqbot.sh
```

3. 系统设置里给 **Termux** 和 **Termux:Boot** 都设「电池 → 不限制」；国产 ROM 再把两者加进「自启动」白名单。

### 重启之后怎么用

| 场景 | 你要做的 |
|---|---|
| 手机重启、自启正常 | **什么都不用做**，等 **约 5 分钟**（等网络 + QQ 登录 + 麦麦初始化），然后直接给机器人发 QQ 消息 |
| **怎么确认好了** | ① 给机器人发一条 QQ 消息，**有回复**就是通了<br>② 手机浏览器打开 `http://127.0.0.1:8001`（麦麦后台）看有没有连上<br>③ 打开 `http://127.0.0.1:6099/webui?token=xxx`（NapCat 后台）看 QQ 是否在线 |
| 想看启动日志 | `proot-distro login ubuntu -- tail -20 /tmp/qqbot-start.log` |
| 自启没生效 | 打开 Termux，手动 `bash ~/qqbot.sh` |
| 想停掉机器人 | `proot-distro login ubuntu -- bash -c 'pkill -9 -x qq; pkill -9 -x maibot'` |
| 手滑划掉了 Termux | 机器人立刻下线，重新 `bash ~/qqbot.sh` |

> ⚠️ Termux:Boot 只在**真重启**时触发。划掉 Termux 不会触发，必须手动启动。

## Get Help

- 先查 **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** —— 部署与运行阶段的常见问题都在里面
- 仍然解决不了：开 [Issue](https://github.com/ENDDREAM-ZM/qqbot-termux/issues)，请附上
  - 手机型号 / Android 版本 / Termux 来源
  - `install.sh` 或启动时的完整报错
  - `proot-distro login ubuntu -- tail -50 /tmp/napcat.log` 的输出

## For Developers

```
install.sh          Termux 侧一键部署（容器创建 → 拷贝 → 恢复 → 交互配置 → 生成启动脚本）
scripts/
  restore.sh        容器内恢复：换源、装依赖、装 QQ、部署 NapCat 与麦麦
  templates/        需要写入的配置模板（onebot11.json、adapter-config.toml）
payload/            上游原包，未做任何改动（已与上游 Release 逐字节比对）
packages/           可选大文件（Ubuntu rootfs、QQ deb），不进版本库
```

- `payload/` 只放上游原包，所有定制都在 `scripts/` 里，便于跟随上游升级
- 想改默认行为：编辑 `scripts/templates/` 下的模板，或 `scripts/restore.sh` 的部署步骤
- 想减少 clone 体积：删掉 `payload/napcat-install/napcat/native/` 里非 arm64 的预编译库，可从 113 MB 降到约 35 MB（Android 端功能不受影响）

## Contributing

欢迎 PR。请保持 `payload/` 与上游一致——如需修改上游文件，请改为在 `scripts/` 中打补丁，并在 PR 里说明原因。

## Credits

- [MaiBot](https://github.com/Mai-with-u/MaiBot)：LLM 聊天机器人框架（GPL-3.0）
- [MaiBot-SnowLuma-Adapter](https://github.com/Mai-with-u/MaiBot-SnowLuma-Adapter)：统一 QQ 连接器（GPL-3.0-or-later）
- [NapCat](https://github.com/NapNeko/NapCatQQ)：基于 NTQQ 的协议端
- [Termux](https://github.com/termux/termux-app) / [proot-distro](https://github.com/termux/proot-distro)：提供 Android 上的 Linux 环境
- [Linux QQ](https://im.qq.com/linuxqq/)：腾讯官方客户端

第三方组件的许可与再分发说明见 [NOTICE.md](NOTICE.md)。

## Disclaimer

本项目是**非官方**的第三方技术验证项目，与腾讯公司**没有任何隶属、合作或授权关系**。

**风险提示**

| 风险 | 说明 |
|---|---|
| 账号 | 使用非官方协议端**可能违反腾讯服务条款**，导致限制、封禁或永久封号 |
| 数据 | 封号可能导致好友、群聊、空间等数据不可恢复 |
| 隐私 | 聊天内容会发送给你**自行配置**的 LLM 服务商，群成员发言亦然 |
| 设备 | 长期运行可能发热、耗电、占存储 |

**禁止用途**：违法违规、垃圾信息群发、诈骗骚扰、自动化养号、绕过腾讯安全风控与实名认证、
大规模抓取他人数据、商业代挂代刷、侵犯他人隐私与著作权。

**请使用小号测试，风险自负。** 作者与贡献者不对任何账号损失、数据丢失或连带后果负责。

完整条款（含责任限制、合规检查清单、停止使用方法）见 **[DISCLAIMER.md](DISCLAIMER.md)**。

## License

[MIT](LICENSE) © 2026 qqbot-termux contributors

第三方组件的版权与许可见 [NOTICE.md](NOTICE.md)，使用风险见 [DISCLAIMER.md](DISCLAIMER.md)。
