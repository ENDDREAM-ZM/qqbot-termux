# 第三方组件说明

## 本仓库自身的许可

`install.sh`、`scripts/*`、`docs/*`、`get.sh`、README 等**本项目编写的文件**适用 [MIT 许可](LICENSE)。

> 说明写在 NOTICE 而不是 LICENSE 里，是因为 GitHub 需要 LICENSE 与标准 MIT **逐字匹配**
> 才能正确识别许可证类型，附加说明会导致被归类为 `Other`。

## 第三方组件

`payload/` 目录下分发的文件均来自以下开源项目，版权归各自作者所有。
本仓库仅做「打包与集成」，不修改其上游代码。

## MaiBot（麦麦）
- 仓库：https://github.com/Mai-with-u/MaiBot
- 许可：GPL-3.0
- 说明：`payload/maibot/` 仅包含**配置模板**，程序本体由 `scripts/restore.sh` 在目标机器上通过 `uv tool install maibot` 从 PyPI 安装。

## 统一 QQ 连接器（MaiBot-SnowLuma-Adapter）
- 仓库：https://github.com/Mai-with-u/MaiBot-SnowLuma-Adapter
- 许可：GPL-3.0-or-later
- 说明：`payload/maibot/plugins/MaiBot-SnowLuma-Adapter/` 为其插件本体，一个插件同时支持 SnowLuma 与 NapCat。

## NapCat
- 仓库：https://github.com/NapNeko/NapCatQQ
- 许可：见上游仓库（部分逻辑代码采用其仓库开源许可）
- 说明：`payload/napcat-install/` 为其 Shell 发行包解压后的运行时（含 `napcat.mjs`、`native/`、`node_modules/`）。若上游许可不允许再分发，请删除本目录，改为运行 `install.sh` 时从官方 Release 下载。

## Linux QQ
- 来源：https://im.qq.com/linuxqq/
- 许可：腾讯公司专有软件
- 说明：**本仓库不分发 QQ 安装包**，由 `scripts/restore.sh` 在目标机器上从官方地址下载。

## Ubuntu rootfs
- 来源：https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/
- 许可：Ubuntu 官方发行版（含多种开源许可）
- 说明：**本仓库不分发**，需要时由使用者自行下载放入 `packages/`。

## PRoot / proot-distro
- 仓库：https://github.com/termux/proot-distro
- 说明：由 Termux 包管理器安装，不在本仓库分发。

---

如你是上述项目的作者，认为本仓库的分发方式不妥，请提 Issue，我会立即调整。

## 风险与免责

上述组件均涉及**非官方 QQ 接入**，可能违反腾讯服务条款并导致账号封禁。
使用前请阅读 [DISCLAIMER.md](DISCLAIMER.md)。
