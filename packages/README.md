# packages/ —— 可选的大文件

这个目录不在版本库里（见 `.gitignore`），用来放两个可选文件，
放进来后 `install.sh` 会自动优先使用本地文件，避免联网下载失败。

## 1. Ubuntu rootfs（当 `proot-distro install` 报 Network unreachable 时必需）

下载地址：https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/

选 `ubuntu-base-24.04.x-base-arm64.tar.gz`，重命名为：

```
ubuntu-rootfs-arm64.tar.gz
```

## 2. Linux QQ 安装包（可选，省一次 200MB 下载）

官方地址（arm64）：

```
https://qqdl.gtimg.cn/qqfile/QQNT/9.9.36/beta/9ee04bef/linuxqq_3.2.34-53644_arm64.deb
```

下载后直接放进本目录，文件名保持 `linuxqq_*.deb` 即可。

> 注意：QQ 是腾讯的专有软件，请勿把这些文件提交到公开仓库。
