# 排障

下面这些坑都是**实际部署时踩到的**，按发生阶段归类。现象 → 原因 → 解法。

---

## 部署阶段

| 现象 | 原因 | 解法 |
|---|---|---|
| `pkg update` 报 `File has unexpected size` / `Mirror sync in progress` | Termux 镜像正在同步 | `termux-change-repo` 换清华/北外源，然后 `rm -rf $PREFIX/var/lib/apt/lists/* && pkg update` |
| 脚本打印「容器已存在，跳过」但实际没装成功 | 上一次在线安装超时/中断，留下了半成品目录，旧版只判断目录存在就当已安装 | 已修：现在检查 `rootfs/etc/os-release` 与 `rootfs/bin/bash`；如仍异常，手动 `rm -rf $PREFIX/var/lib/proot-distro/containers/ubuntu` 再跑 |
| `apt update` 报 `Certificate verification failed: The certificate is NOT trusted` / `No system certificates available` | **ubuntu-base 精简 rootfs 没装 ca-certificates**，https 源无法握手 | 已修：`restore.sh` 默认改用 **http** 源（apt 有签名校验，不影响完整性），拿到索引后先装 ca-certificates |
| `apt update` 看起来"成功"但后面 `Unable to locate package` | apt 部分失败时**退出码仍是 0**，旧版只看退出码误判成功 | 已修：改为检查 `/var/lib/apt/lists/*_Packages*` 是否真的存在 + `apt-cache policy xvfb` 是否有候选 |
| 装依赖刷一屏 `Unable to locate package xvfb / xauth / curl ...` | **容器是空壳**（没装成）或 apt 索引为空 | 已修：`restore.sh` 现在会先验证镜像可用、找不到 `xvfb` 就报错退出。手动排查：`proot-distro login ubuntu -- apt-get update` |
| 在线装容器一直卡住 | 要连 GitHub 拉 rootfs，国内基本超时 | 已修：**优先用本地 rootfs**，找不到才在线装，且在线装最多等 1 分钟；把 `ubuntu-base-*-arm64.tar.gz` 放「下载」目录或用内置 rootfs 的离线包即可 |
| `proot-distro install` 报 `No cached manifest found` + `Network is unreachable` | 它要去 GitHub 取 rootfs | 把 `ubuntu-base-*-arm64.tar.gz` 放进 `packages/`（见 [packages/README.md](../packages/README.md)），或手动 `proot-distro install <本地包路径> --name ubuntu` |
| `cp: cannot create .../installed-rootfs/ubuntu/root/` | proot-distro **v5 改了目录布局** | 新路径是 `$PREFIX/var/lib/proot-distro/containers/<名字>/rootfs`，不再是 `installed-rootfs/<名字>/root` |
| 装依赖时一堆红字 `Failed to resolve user 'systemd-network'` / `Cannot set file attributes for '/var/log/journal'` | proot 里没有 PID 1 的 systemd | **无害，直接忽略** |
| apt 下载特别慢 | 默认走国外源 | `restore.sh` 已内置清华源；也可 `MIRROR=https://mirrors.aliyun.com/ubuntu-ports bash scripts/restore.sh` |
| `uv tool install maibot` 卡住 | PyPI 直连慢 | 已内置 `UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple`；可手动 `export UV_DEFAULT_INDEX=...` 后重跑 |

---

## 运行阶段

| 现象 | 原因 | 解法 |
|---|---|---|
| 麦麦日志一直 `目标端口拒绝连接：ws://127.0.0.1:3001` | NapCat 没起来，或没登录 | 看 `/tmp/napcat.log`；没起就重启 launcher |
| 扫码报「扫码授权失败，请前往QQ官网下载最新版QQ」 | **`LD_PRELOAD` 里混入了别的库**（尤其是拦截 `mmap`/`shmget` 的 shim），QQ 发包验签失败 | `launcher.sh` 的 `LD_PRELOAD` 里**只能有** `libnapcat_launcher.so` |
| QQ 启动就 `FATAL: ... /dev/shm ...` | proot 里没有 `/dev/shm` | launcher 必须带 `--disable-dev-shm-usage` |
| x11vnc 起不来，日志 `shmget: Function not implemented` | Android 没有 SysV 共享内存 | 加 `-noshm` 参数 |
| 二维码图片一直不变 / 扫了提示已过期 | ① NapCat 只在扫码失败后才换新码；② 相册 App 缓存了同名旧图 | 用**文件管理器**直接打开具体文件（别用相册缩略图）；过期就重启 launcher 生成新码，**2 分钟内扫完** |
| `maibot: command not found` | 没把 `~/.local/bin` 加进 PATH | `export PATH=/root/.local/bin:$PATH` |
| 用 tmux / `nohup &` 起后台，命令一结束进程就没了 | **proot-distro 会话退出时会杀掉所有子进程**，无法「启动后脱离」 | 必须留一个前台会话挂住（`while true; do sleep 60; done`），不能关窗口 |
| 从最近任务划掉 Termux，机器人立刻下线 | 划掉 = 杀进程 | 别划它；要开机自启就配 Termux:Boot |
| 重装 QQ 之后起不来 | `launcher.sh` 会改写 QQ 的 `package.json`，中途 Ctrl+C 会留下坏状态 | 重装 QQ deb 恢复：`dpkg -i /root/qqbot/packages/linuxqq_*.deb` |
| 开机自启没生效 | Termux:Boot 没打开过 / 电池优化没关 / ROM 自启动白名单没加 | 三处依次检查 |
| 换了台机器，快速登录不认 | QQ 登录态可能和机器绑定 | `rm -rf ~/.config/QQ` 后重新扫码 |

---

## 调试技巧

### 1. 不要用 `pkill -f "/opt/QQ/qq"`

这个字符串也会出现在你自己的命令行里，`pkill` 会把自己一起匹配上，直接杀掉当前会话（表现为打完命令立刻 `Killed`，后面全不执行）。用进程名精确匹配：

```bash
pkill -9 -x qq        # ✅ 安全
pkill -9 -f "QQ/qq"   # ❌ 会自杀
```

### 2. 机器人跑着的时候想看日志

`proot-distro` 允许并发登录，能新开 Termux 会话就新开一个：

```bash
proot-distro login ubuntu -- tail -20 /tmp/maibot.log
proot-distro login ubuntu -- tail -20 /tmp/napcat.log
```

新开不了窗口的话，就 `Ctrl+C` 停掉主会话再查——登录态已保存，重启只要 25 秒。

### 3. 判断「到底哪一环断了」

按这个顺序看，一眼就能定位：

```bash
# ① QQ 进程在不在
proot-distro login ubuntu -- bash -c 'ps aux | grep -c "[q]q"'

# ② NapCat 有没有拿到登录
proot-distro login ubuntu -- bash -c 'grep -a "登录成功\|Login Error\|二维码" /tmp/napcat.log | tail -5'

# ③ OneBot 端口有没有起来
proot-distro login ubuntu -- bash -c '(exec 3<>/dev/tcp/127.0.0.1/3001) 2>/dev/null && echo "3001 OK" || echo "3001 未监听"'

# ④ 麦麦有没有连上
proot-distro login ubuntu -- bash -c 'grep -a "适配器已连接\|客户端画像" /tmp/maibot.log | tail -2'
```

| 断在哪 | 说明 |
|---|---|
| ① 为 0 | QQ 没起来，看 `/tmp/napcat.log` |
| ② 有 `二维码` 没 `登录成功` | 卡在扫码 |
| ③ 未监听 | NapCat 没登录成功，或 OneBot 配置没生效 |
| ④ 空 | 麦麦没起来，或 PATH/配置有问题 |

---

## 还没解决？

开 [Issue](https://github.com/ENDDREAM-ZM/qqbot-termux/issues)，请附上：

1. 手机型号 / Android 版本 / Termux 来源（F-Droid 还是 GitHub）
2. 完整报错（不要只贴一行）
3. 上面「判断哪一环断了」四条命令的输出
4. `proot-distro login ubuntu -- tail -50 /tmp/napcat.log`
