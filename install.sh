#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  QQ Bot on Termux —— 一键部署
#  （MaiBot 麦麦 + NapCat，跑在 proot-distro 的 Ubuntu 里）
#
#  用法（在 Termux 里执行，不要在 proot 里）：
#      bash install.sh
# ============================================================
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
NAME="ubuntu"
CONTAINER_DIR="$PREFIX/var/lib/proot-distro/containers/$NAME"
ROOTFS="$CONTAINER_DIR/rootfs"
INSTALL_TIMEOUT=60

# ---------- 0. Termux 基础环境 ----------
echo "===== 0. Termux 基础环境 ====="
pkg update -y || true
pkg install -y proot-distro tar termux-api || true
termux-wake-lock 2>/dev/null || true
echo "已申请 wake-lock（防止系统杀后台）"

# ---------- 1. 检查/创建 Ubuntu 容器 ----------
echo "===== 1. 安装 Ubuntu 容器 ====="

# 判断容器是否"真的可用"（不是只看目录在不在）
container_ok() {
  [ -f "$ROOTFS/etc/os-release" ] && [ -x "$ROOTFS/bin/bash" ]
}

find_local_rootfs() {
  for p in \
    "$REPO_DIR"/packages/ubuntu*.tar.* \
    "$REPO_DIR"/packages/*rootfs*.tar.* \
    /sdcard/Download/ubuntu*.tar.* \
    /sdcard/Download/*rootfs*.tar.* \
    "$HOME"/ubuntu*.tar.* \
    "$HOME"/*rootfs*.tar.* ; do
    [ -f "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

if container_ok; then
  echo "✅ 容器已存在且可用，跳过创建"
else
  # 有残留（半成品）就先清掉，否则会被误判为"已安装"
  if [ -d "$CONTAINER_DIR" ]; then
    echo "⚠️  检测到不完整的容器目录，正在清理：$CONTAINER_DIR"
    rm -rf "$CONTAINER_DIR"
  fi

  # 优先用本地离线包，避免联网等待
  RB="$(find_local_rootfs || true)"

  if [ -n "$RB" ]; then
    echo "✅ 找到本地 rootfs：$RB"
    echo "   直接本地安装，跳过在线下载"
    if ! proot-distro install "$RB" --name "$NAME"; then
      echo "❌ 本地 rootfs 安装失败，请确认文件完整（tar tzf 能正常列出内容）"
      exit 1
    fi
  else
    echo "未找到本地 rootfs，尝试在线安装（最多等待 $((INSTALL_TIMEOUT/60)) 分钟，需要连 GitHub）..."
    if timeout "$INSTALL_TIMEOUT" proot-distro install "$NAME"; then
      echo "在线安装完成"
    else
      echo "❌ 在线安装失败或超时"
      rm -rf "$CONTAINER_DIR"
      cat <<'TIP'

================================================================
❌ 在线安装失败，且没有找到本地 Ubuntu rootfs。

请用下面任一方式准备 rootfs：

  A) 下载后放到手机「下载」目录（文件名含 ubuntu，后缀 .tar.gz / .tar.xz）
     官方： https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/
           选 ubuntu-base-24.04.x-base-arm64.tar.gz
     国内： https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu-base/releases/24.04/release/
           或 https://mirrors.aliyun.com/ubuntu-cdimage/ubuntu-base/releases/24.04/release/

  B) 直接使用本项目的离线包（已内置 rootfs）
     https://github.com/ENDDREAM-ZM/qqbot-termux/releases/latest

  C) 开代理后重新运行本脚本

准备好后重新执行： bash install.sh
================================================================
TIP
      exit 1
    fi
  fi
fi

# ---------- 2. 再次校验容器可用 ----------
if ! container_ok; then
  echo "❌ 容器创建后仍不可用：$ROOTFS 内容不完整"
  echo "   排查：proot-distro list"
  echo "         ls $ROOTFS/etc/os-release"
  echo "   确认无误后删除残留目录重试：rm -rf $CONTAINER_DIR"
  exit 1
fi
echo "✅ 容器可用：$(cat "$ROOTFS/etc/os-release" 2>/dev/null | grep -E '^PRETTY_NAME' | cut -d= -f2 | tr -d '\"')"

# ---------- 3. 把项目拷进容器 ----------
echo "===== 3. 把项目拷进容器 ====="
DEST="$ROOTFS/root/qqbot"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "$REPO_DIR"/payload "$REPO_DIR"/scripts "$DEST"/
if cp "$REPO_DIR"/packages/linuxqq_*.deb "$DEST"/ 2>/dev/null; then
  echo "已带上本地 QQ 安装包"
else
  echo "未找到本地 QQ 安装包，容器内会联网下载"
fi

# ---------- 4. 容器内恢复 ----------
echo "===== 4. 容器内恢复（约 10-20 分钟，取决于网速）====="
proot-distro login "$NAME" -- bash -c 'cd /root/qqbot && bash scripts/restore.sh /root/qqbot'

# ---------- 5. 填写配置 ----------
echo "===== 5. 填写配置（直接回车可跳过，之后也能手改）====="
CFG="$ROOTFS/opt/maibot-instance/config"

printf "机器人 QQ 号（只填数字）: "
read -r QQ
if [ -n "${QQ:-}" ]; then
  sed -i "s|^qq_account = .*|qq_account = \"$QQ\"|" "$CFG/bot_config.toml"
  sed -i "s|^platform = .*|platform = \"qq\"|" "$CFG/bot_config.toml"
  echo "  ✅ 已写入 qq_account = $QQ"
else
  echo "  跳过（启动时会出二维码让你扫）"
fi

printf "模型接口地址（如 https://api.deepseek.com）: "
read -r BU
printf "API Key: "
read -r AK
if [ -n "${BU:-}" ]; then
  sed -i "s|^base_url = .*|base_url = \"$BU\"|" "$CFG/model_config.toml"
  echo "  ✅ 已写入 base_url"
fi
if [ -n "${AK:-}" ]; then
  sed -i "s|^api_key = .*|api_key = \"$AK\"|" "$CFG/model_config.toml"
  echo "  ✅ 已写入 api_key"
fi

printf "模型 ID（如 deepseek-chat / gpt-4o-mini，回车用默认）: "
read -r MID
if [ -n "${MID:-}" ]; then
  sed -i "s|^model_identifier = .*|model_identifier = \"$MID\"|g" "$CFG/model_config.toml"
  echo "  ✅ 已写入 model_identifier = $MID"
fi

# ---------- 6. 生成启动脚本 ----------
echo "===== 6. 生成启动脚本 ====="
cat > "$HOME/qqbot.sh" <<'EOS'
termux-wake-lock 2>/dev/null

ROOTFS="$PREFIX/var/lib/proot-distro/containers/ubuntu/rootfs"
QR_SRC="$ROOTFS/opt/napcat-install/napcat/cache/qrcode.png"

# 后台把二维码同步到「下载」目录（同名覆盖，方便相册/文件管理器打开）
(
  while true; do
    [ -f "$QR_SRC" ] && cp -f "$QR_SRC" /sdcard/Download/qqbot-qr.png 2>/dev/null
    sleep 3
  done
) &
QRPID=$!

proot-distro login ubuntu -- bash /root/qqbot/scripts/start-bot.sh
RC=$?
kill $QRPID 2>/dev/null
exit $RC
EOS
chmod +x "$HOME/qqbot.sh"

# ---------- 7. 使用说明 ----------
GUIDE_DST="/sdcard/Download/qqbot-使用说明.txt"
if ! ( : > "$GUIDE_DST" ) 2>/dev/null; then
  GUIDE_DST="$HOME/qqbot-使用说明.txt"   # 没有存储权限时退回 Termux 家目录
fi
cat > "$GUIDE_DST" <<'GUIDE'
========================================================
  QQ Bot (MaiBot + NapCat) 使用说明
========================================================

【第 1 步】确认模型 ID 填对了
  不知道填什么就查服务商支持的模型：

    curl -s <你的接口地址>/v1/models \
         -H "Authorization: Bearer <你的APIKey>" | grep -o '"id":"[^"]*"'

  然后改配置里 [[models]] 的 model_identifier（共 3 处）：

    proot-distro login ubuntu -- nano /opt/maibot-instance/config/model_config.toml

【第 2 步】首次扫码登录 QQ
    proot-distro login ubuntu -- bash -c 'cd /opt/napcat-install && bash launcher.sh'

  约 25 秒后终端打印二维码（字符画）+ 解码 URL，同时存成图片：
    /opt/napcat-install/napcat/cache/qrcode.png

  同一个手机怎么扫：QQ →「+」→ 扫一扫 → 右下角「相册」→ 选那张图 → 确认登录
  二维码约 2 分钟有效，过期就重跑上面那条命令。

【第 3 步】启动
    bash ~/qqbot.sh

  约 30 秒后屏幕框出两个后台地址和一个 Token。

【怎么算成功】
  手机 QQ 给机器人发一句「在吗」——有回复就是全通了。

【常用命令】
  启动        bash ~/qqbot.sh
  看麦麦日志  proot-distro login ubuntu -- tail -f /tmp/maibot.log
  看NapCat日志 proot-distro login ubuntu -- tail -f /tmp/napcat.log
  停止        proot-distro login ubuntu -- bash -c 'pkill -9 -x qq; pkill -9 -x maibot'
  重新扫码    proot-distro login ubuntu -- bash -c 'rm -rf ~/.config/QQ && cd /opt/napcat-install && bash launcher.sh'

【注意】
  · Termux 窗口别关、别从最近任务划掉，划掉 = 机器人立刻下线
  · 想开机自启：装 Termux:Boot 并点开一次，再按 README 配置
  · 遇到问题看 README 的「排障」章节

========================================================
GUIDE

echo
cat "$GUIDE_DST"
echo
echo "  以上说明已保存到： $GUIDE_DST"
echo "============================================================"
