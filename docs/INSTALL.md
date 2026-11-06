# 详细安装步骤

从一台没装任何东西的 Android 手机，到机器人能正常聊天。

**总耗时** 约 30~50 分钟（取决于网速）  
**总占用** 约 2.2 GB

---

## 0. 安装 Termux

| 装什么 | 从哪装 | 说明 |
|---|---|---|
| **Termux** | [F-Droid](https://f-droid.org/packages/com.termux/) 或 [GitHub Releases](https://github.com/termux/termux-app/releases) | **不要用 Play 商店版**，那个版本已停更 |
| **Termux:Boot**（可选） | [F-Droid](https://f-droid.org/packages/com.termux.boot/) | 只有需要开机自启才装；装完**必须点开一次** |

---

## 1. Termux 初始化 + 换源

```bash
pkg update -y
termux-setup-storage          # 弹窗点「允许」
termux-wake-lock              # 防止系统杀后台
```

**国内必须换源**，否则官方源只有几 KB/s：

```bash
termux-change-repo
# 选 Main repository → 空格选中 → 回车 → 选 Mirrors in China 的清华 / 北外
```

或直接写源：

```bash
echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list
rm -rf $PREFIX/var/lib/apt/lists/*
pkg update -y
```

---

## 2. 获取项目

**方式 A：一键脚本（推荐，不需要 Termux 的 git）**

```bash
bash <(curl -sL https://raw.githubusercontent.com/ENDDREAM-ZM/qqbot-termux/main/get.sh)
```

它会**先查本地、再比对版本**：

| 情况 | 行为 |
|---|---|
| 本地没有 | 下载约 62 MB 到「下载」目录再解压 |
| 本地版本 = 线上最新 | 直接用本地，**不联网** |
| 本地版本 < 线上最新 | 自动下载新版并覆盖解压 |
| 查不到线上版本（断网） | 用本地，并给出提示 |
| `--local` | 强制只用本地 |
| `--force` | 强制重新下载 |

版本号来自仓库根目录的 `VERSION` 文件，与 Release tag 对应。

下载慢可以加前缀：`GH_PROXY=https://ghfast.top/ bash <(curl -sL ...)`
手动下载也行，把包丢进「下载」目录再跑 `get.sh` 即可。

- 中断可续传：`curl -L -C - -o qqbot.tar.gz <同一地址>`
- 直连慢可加前缀：`https://ghfast.top/` + 原地址
- 离线包里**已包含 Ubuntu rootfs**（`packages/ubuntu-rootfs-arm64.tar.gz`）

**方式 B：git clone**

```bash
pkg install -y git
git clone https://ghfast.top/https://github.com/ENDDREAM-ZM/qqbot-termux.git
cd qqbot-termux
```

用这种方式仓库里**没有** Ubuntu rootfs。如果在线装容器失败（连不上 GitHub），需要自己下一个：

```
https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu-base/releases/24.04/release/
选 ubuntu-base-24.04.x-base-arm64.tar.gz，放到手机「下载」目录即可（脚本会自动找到）
```

---

## 3. 一键部署

```bash
bash install.sh
```

脚本分五个阶段，逐个说明。

### ① 安装 Ubuntu 容器

```
===== 0. Termux 基础环境 =====
===== 1. 安装 Ubuntu 容器 =====
```

- 先尝试 `proot-distro install ubuntu`（需要连 GitHub）
- 失败时自动改用 `packages/` 里的本地 rootfs
- 两者都失败 → 见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 的「rootfs 下载失败」

### ② 拷贝项目进容器

```
===== 2. 把项目拷进容器 =====
```

### ③ 容器内恢复（最久，10~20 分钟）

```
===== 3. 容器内恢复（约 10-20 分钟，取决于网速）=====
== 1. 换国内 apt 源 ==
== 2. 更新索引 ==
== 3. 分批安装依赖（失败自动重试）==
== 4. 安装 QQ ==
QQ: 3.2.34-53644
== 5. 部署 NapCat ==
== 6. 部署麦麦实例 ==
== 7. 安装麦麦程序（PyPI 国内镜像）==
1.3.19
================ 恢复完成 ================
```

> 中间可能出现 `Failed to resolve user 'systemd-network'`、`Cannot set file attributes for '/var/log/journal'` 等红字 —— proot 里没有 systemd，**属于正常现象，可忽略**。

### ④ 填写配置（交互式，30 秒）

```
===== 4. 填写配置（直接回车可跳过，之后也能手改）=====
机器人 QQ 号（只填数字）: 123456789
  ✅ 已写入 qq_account = 123456789
模型接口地址（如 https://api.deepseek.com）: https://api.deepseek.com
  ✅ 已写入 base_url
API Key: sk-xxxxxxxx
  ✅ 已写入 api_key
模型 ID（如 deepseek-chat / gpt-4o-mini，回车用默认）: deepseek-chat
  ✅ 已写入 model_identifier = deepseek-chat
```

**不知道模型 ID 填什么**？填完地址和 Key 之后查一下服务商支持的模型：

```bash
curl -s <你的接口地址>/v1/models -H "Authorization: Bearer <你的APIKey>" | grep -o '"id":"[^"]*"'
```

输出的 `id` 就是可以填的模型名。

| 服务商 | 模型 ID 示例 |
|---|---|
| DeepSeek 官方 | `deepseek-chat`、`deepseek-reasoner` |
| 硅基流动 | `deepseek-ai/DeepSeek-V3` |
| OpenAI | `gpt-4o`、`gpt-4o-mini` |
| 各类中转站 | 以 `/v1/models` 返回的 `id` 为准 |

### ⑤ 生成启动脚本

```
===== 5. 生成启动脚本 =====
```

在 `~/qqbot.sh` 生成启动脚本，并打印一份完整的使用说明（同时保存到手机「下载」目录：`qqbot-使用说明.txt`）。

---

## 4. 启动（首次会自动引导扫码）

```bash
bash ~/qqbot.sh
```

脚本会先尝试**快速登录**（登录态有效时约 20 秒），失败则自动转扫码：

```
==================================================
  需要扫码登录 QQ

  二维码图片：/opt/napcat-install/napcat/cache/qrcode.png
  （Termux 会自动把它复制到手机「下载」目录）
  解码 URL  ：https://txz.qq.com/p?k=xxxxx
==================================================
```

手机 QQ →「+」→ 扫一扫 → 右下角**相册** → 选「下载」里的 `qqbot-qr.png` → 确认登录。

登录成功后打印：

```
==================================================
  ✅ 机器人已经登录成功了，请去 MaiBot 后台进行设置以进行使用
  麦麦后台  : http://127.0.0.1:8001
  NapCat后台: http://127.0.0.1:6099/webui?token=xxx
==================================================
```

> **不再刷屏**：NapCat 的消息日志写在 `/tmp/napcat.log`，终端只有 5 分钟一次的心跳。
> 想看实时消息：`proot-distro login ubuntu -- tail -f /tmp/napcat.log`

---

## 5. 验证

手机 QQ 给机器人发一句「在吗」：

- **有回复** → 全部打通 ✅
- 没回复 → `proot-distro login ubuntu -- tail -20 /tmp/maibot.log`

---

## 6. 日常启动

```bash
bash ~/qqbot.sh
```

---

## 7. 后台面板

| 面板 | 地址 | 用途 |
|---|---|---|
| 麦麦 | `http://127.0.0.1:8001` | 改人设与回复风格、换模型、装插件、黑白名单、看聊天记录 |
| NapCat | `http://127.0.0.1:6099/webui?token=xxx` | 看登录状态、改 OneBot 端口与 token、看消息收发 |

麦麦首次登录用启动时打印的 Token，之后会让你设置固定密码。

---

## 8. 开机自启（可选）

1. 安装 [Termux:Boot](https://f-droid.org/packages/com.termux.boot/) 并**点开一次**
2. 在 Termux 里：

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

3. 系统设置里给 **Termux** 和 **Termux:Boot** 都设「电池 → 不限制」
4. 国产 ROM 再把两者加进「自启动」白名单

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

---

## 日常只有两件事

| 场景 | 做什么 |
|---|---|
| 正常使用 | 什么都不用做，Termux 在后台跑着 |
| 重启过 / 被系统杀了 | 打开 Termux，`bash ~/qqbot.sh` |

遇到问题看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)。
