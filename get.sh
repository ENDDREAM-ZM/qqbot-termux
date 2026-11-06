#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  获取并部署 qqbot-termux
#
#  用法（在 Termux 里执行）：
#      bash <(curl -sL https://raw.githubusercontent.com/ENDDREAM-ZM/qqbot-termux/main/get.sh)
#  或者先存下来再跑：
#      curl -sL -o get.sh https://raw.githubusercontent.com/ENDDREAM-ZM/qqbot-termux/main/get.sh
#      bash get.sh
#
#  可选参数 / 环境变量：
#      --local          只用本地已有的包，不检查也不下载
#      --force          忽略本地，强制重新下载
#      GH_PROXY=...     GitHub 加速前缀，如 https://ghfast.top/
#      QQBOT_URL=...    自定义下载地址
#
#  逻辑：
#    1. 查本地有没有（已解压目录 / 「下载」里的包），并读出它的版本号
#    2. 查线上最新版本号
#    3. 本地 >= 线上 -> 用本地；本地旧或没有 -> 下载
# ============================================================
set -e

URL="${QQBOT_URL:-https://github.com/ENDDREAM-ZM/qqbot-termux/releases/latest/download/qqbot-termux-repo.tar.gz}"
API="${QQBOT_API:-https://api.github.com/repos/ENDDREAM-ZM/qqbot-termux/releases/latest}"
GH_PROXY="${GH_PROXY:-}"
DIR="/sdcard/Download"
DEST="$HOME"
TARGET="$DEST/qqbot-termux"

MODE=auto
for a in "$@"; do
  case "$a" in
    --local) MODE=local ;;
    --force) MODE=force ;;
  esac
done

say() { printf '%s\n' "$*"; }
ver_of_pkg() { tar xzOf "$1" qqbot-termux/VERSION 2>/dev/null | tr -d ' \r\n'; }

# 版本比较：$1 > $2 返回 0
ver_gt() {
  [ "$1" = "$2" ] && return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

[ -d "$DIR" ] || DIR="$HOME"

# ---------- 1. 找本地 ----------
LOCAL_VER=""
LOCAL_SRC=""

if [ -f "$TARGET/VERSION" ]; then
  LOCAL_VER=$(tr -d ' \r\n' < "$TARGET/VERSION")
  LOCAL_SRC="$TARGET（已解压）"
fi

PKG=""
for p in "$DIR"/*qqbot*.tar.gz "$HOME"/*qqbot*.tar.gz; do
  [ -f "$p" ] || continue
  tar tzf "$p" >/dev/null 2>&1 || continue
  v=$(ver_of_pkg "$p")
  PKG="$p"
  if [ -n "$v" ] && { [ -z "$LOCAL_VER" ] || ver_gt "$v" "$LOCAL_VER"; }; then
    LOCAL_VER="$v"
    LOCAL_SRC="$p"
  fi
  break
done

[ -n "$LOCAL_VER" ] && say "📦 本地版本：$LOCAL_VER  （$LOCAL_SRC）" || say "📦 本地没有可用的安装包"

# ---------- 2. 查线上 ----------
REMOTE_VER=""
if [ "$MODE" != "local" ]; then
  REMOTE_VER=$(curl -fsSL --max-time 12 "$API" 2>/dev/null \
    | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed 's/.*"v\{0,1\}\([0-9][0-9.]*\)".*/\1/')
  [ -n "$REMOTE_VER" ] && say "🌐 线上版本：$REMOTE_VER" || say "🌐 查不到线上版本（可能没网），按本地处理"
fi

# ---------- 3. 决定 ----------
NEED_DL=0
if [ "$MODE" = "force" ]; then
  NEED_DL=1
elif [ -z "$LOCAL_VER" ]; then
  NEED_DL=1
elif [ -n "$REMOTE_VER" ] && ver_gt "$REMOTE_VER" "$LOCAL_VER"; then
  say "⬆️  本地 $LOCAL_VER 比线上 $REMOTE_VER 旧"
  NEED_DL=1
fi

if [ "$NEED_DL" = "0" ]; then
  say "✅ 本地已是最新（或无法联网），跳过下载"
  if [ ! -f "$TARGET/install.sh" ] && [ -n "$PKG" ]; then
    say "解压 $PKG ..."
    tar xzf "$PKG" -C "$DEST"
  fi
else
  PKG="$DIR/qqbot.tar.gz"
  say ""
  say "开始下载（约 62 MB）：${GH_PROXY}${URL}"
  if ! curl -fL --progress-bar --max-time 1800 -o "$PKG" "${GH_PROXY}${URL}"; then
    say ""
    say "❌ 下载失败。可以："
    say "   1) 加加速前缀：GH_PROXY=https://ghfast.top/ bash get.sh"
    say "   2) 浏览器手动下载后放进「下载」目录，再跑：bash get.sh --local"
    say "      ${URL}"
    exit 1
  fi
  if ! tar tzf "$PKG" >/dev/null 2>&1; then
    say "❌ 文件不完整（可能被截断），删掉重试：rm -f $PKG"
    exit 1
  fi
  say "✅ 下载完成：$(du -h "$PKG" | cut -f1)   版本：$(ver_of_pkg "$PKG")"
  say "解压到 $DEST ..."
  rm -rf "$TARGET"
  tar xzf "$PKG" -C "$DEST"
fi

if [ ! -f "$TARGET/install.sh" ]; then
  say "❌ 没找到 $TARGET/install.sh，请检查压缩包内容"
  exit 1
fi

cd "$TARGET"
say ""
say "✅ 准备就绪（版本 $(tr -d ' \r\n' < VERSION 2>/dev/null || echo 未知)），开始部署"
say ""
exec bash install.sh
