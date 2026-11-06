#!/bin/bash
# ============================================================
#  容器内启动：快速登录 → 失败转扫码 → 成功后静默运行
#  由 Termux 侧的 ~/qqbot.sh 调用
#
#  说明：NapCat 的所有输出都写进 /tmp/napcat.log，不刷终端。
#        终端只打印「需要扫码」和「已可使用」这类关键提示。
#  退出码：0 正常 / 2 登录失败
# ============================================================
LOG=/tmp/qqbot-start.log
NLOG=/tmp/napcat.log
MLOG=/tmp/maibot.log
log() { echo "$*"; echo "$*" >> "$LOG"; }

log "===== start $(date '+%F %T') ====="
export PATH=/root/.local/bin:$PATH

QQ=$(grep -aE '^qq_account *=' /opt/maibot-instance/config/bot_config.toml 2>/dev/null \
       | head -1 | grep -oE '[0-9]{5,12}')

up() { (exec 3<>/dev/tcp/127.0.0.1/3001) 2>/dev/null; }

start_launcher() {
  # $1 = q 表示快速登录；不传则走扫码
  pkill -9 -x qq 2>/dev/null
  sleep 2
  cd /opt/napcat-install || return 1
  if [ "$1" = "q" ] && [ -n "$QQ" ]; then
    nohup bash launcher.sh -q "$QQ" > "$NLOG" 2>&1 &
  else
    nohup bash launcher.sh > "$NLOG" 2>&1 &
  fi
}

# ---------- 1. 先试快速登录（登录态有效时约 20 秒）----------
if [ -n "$QQ" ]; then
  log "[1/3] 尝试快速登录 QQ $QQ ..."
  start_launcher q
  for i in $(seq 1 12); do
    sleep 2
    up && break
  done
fi

# ---------- 2. 不行就转扫码 ----------
if ! up; then
  log "[2/3] 快速登录不可用，转扫码登录"
  start_launcher
  printed=0
  for i in $(seq 1 45); do
    sleep 2
    up && break
    if [ "$printed" = "0" ] && [ -f /opt/napcat-install/napcat/cache/qrcode.png ]; then
      URL=$(grep -a "二维码解码URL" "$NLOG" 2>/dev/null | tail -1 | grep -oE 'https://[^ ]+')
      echo ""
      echo "=================================================="
      echo "  需要扫码登录 QQ"
      echo ""
      echo "  二维码图片：/opt/napcat-install/napcat/cache/qrcode.png"
      echo "  （Termux 会自动把它复制到手机「下载」目录）"
      [ -n "$URL" ] && echo "  解码 URL  ：$URL"
      echo ""
      echo "  手机 QQ →「+」→ 扫一扫 → 右下角「相册」→ 选那张图"
      echo "  扫完在手机上点「确认登录」，这里会自动继续"
      echo "=================================================="
      printed=1
    fi
  done
fi

if ! up; then
  log "[error] 登录失败，排查：tail -30 $NLOG"
  exit 2
fi
log "[3/3] QQ 已登录，OneBot 3001 就绪"

# ---------- 3. 启动麦麦 ----------
pkill -9 -x maibot 2>/dev/null
sleep 1
cd /opt/maibot-instance || exit 1
nohup maibot run > "$MLOG" 2>&1 &
sleep 30

TOKEN=$(grep -a "WebUi Token" "$NLOG" 2>/dev/null | tail -1 | grep -oE "[a-z0-9]{8,}")
MTOKEN=$(grep -a "WebUI 登录 Token" "$MLOG" 2>/dev/null | tail -1 | sed 's/.*Token[:：] *//')

cat <<INFO

==================================================
  ✅ 机器人已经登录成功了，请去 MaiBot 后台进行设置以进行使用

  麦麦后台  : http://127.0.0.1:8001
  登录 Token: ${MTOKEN:-见 /tmp/maibot.log}
  NapCat后台: http://127.0.0.1:6099/webui?token=${TOKEN:-见 /tmp/napcat.log}

  消息日志不再刷屏，需要看时：
    proot-distro login ubuntu -- tail -f $NLOG
==================================================

INFO

# ---------- 4. 静默保活（5 分钟一次心跳）----------
while true; do
  sleep 300
  log "[$(date +%H:%M)] 运行中"
done
