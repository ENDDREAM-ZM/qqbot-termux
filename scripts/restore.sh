#!/bin/bash
# ============================================================
#  容器内恢复脚本（在 proot Ubuntu 里运行）
#  用法： bash scripts/restore.sh <项目目录>
#  环境变量：
#    MIRROR  apt 镜像（默认清华 ubuntu-ports，arm64 专用）
#    PYPI    PyPI 镜像（默认清华）
# ============================================================
set -e
PKG="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
H="${HOME:-/root}"
MIRROR="${MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports}"
PYPI="${PYPI:-https://pypi.tuna.tsinghua.edu.cn/simple}"

APT="apt-get -o Acquire::http::Timeout=20 -o Acquire::Retries=4 -o Acquire::ForceIPv4=true"

# ubuntu-base 精简镜像可能没装 ca-certificates，https 源会直接握手失败，
# 所以默认用 http（apt 有 Release 签名校验，http 不影响包完整性）
write_sources() {
  local url="$1"
  mkdir -p /etc/apt/sources.list.d
  {
    echo "Types: deb"
    echo "URIs: $url"
    echo "Suites: noble noble-updates noble-security"
    echo "Components: main restricted universe multiverse"
    [ -f /usr/share/keyrings/ubuntu-archive-keyring.gpg ] && \
      echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
  } > /etc/apt/sources.list.d/ubuntu.sources
  rm -f /etc/apt/sources.list
}

echo "== 1. 检查基础系统 =="
if [ ! -f /etc/os-release ]; then
  echo "❌ 当前不是可用的 Ubuntu 容器（/etc/os-release 不存在）"
  exit 2
fi
echo "   $(grep -E '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '\"')"

# 索引真的拿到了吗（apt update 在部分失败时退出码仍是 0，不能只看 $?）
index_ok() {
  ls /var/lib/apt/lists/*_Packages* >/dev/null 2>&1 && \
  apt-cache policy xvfb 2>/dev/null | grep -q "Candidate: [0-9]"
}

CANDIDATES="http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports \
http://mirrors.aliyun.com/ubuntu-ports \
http://mirrors.ustc.edu.cn/ubuntu-ports \
http://ports.ubuntu.com/ubuntu-ports"

UPDATE_OK=0
for url in $CANDIDATES; do
  echo "== 2. 尝试镜像：$url =="
  write_sources "$url"
  rm -rf /var/lib/apt/lists/*
  $APT update 2>&1 | tail -5
  if index_ok; then
    UPDATE_OK=1
    echo "✅ 索引可用，镜像：$url"
    break
  fi
  echo "⚠️  该镜像没拿到可用索引，换下一个"
done

if [ "$UPDATE_OK" = "0" ]; then
  echo ""
  echo "❌ 所有镜像都拿不到包索引。常见原因："
  echo "   1) 容器网络不通：proot-distro login ubuntu -- ping -c2 223.5.5.5"
  echo "   2) DNS 解析失败：proot-distro login ubuntu -- cat /etc/resolv.conf"
  echo "   3) 系统证书缺失（https 源）：改用 http 源（本脚本已默认 http）"
  echo "   4) rootfs 不完整：删除容器重装"
  echo "      rm -rf \$PREFIX/var/lib/proot-distro/containers/ubuntu"
  exit 3
fi

echo "== 2.5 先装 ca-certificates（后续 https 源/curl 依赖它）=="
$APT install -y --no-install-recommends ca-certificates || true

echo "== 3. 分批安装依赖（失败自动重试）=="
b() {
  for i in 1 2 3; do
    $APT install -y --no-install-recommends "$@" && return 0
    echo "  第 $i 次失败，3 秒后重试..."
    sleep 3
  done
  echo "  ⚠️ 这批失败，可稍后单独重跑：$*"
  return 1
}
# git: 麦麦「插件市场 → 从 Git 安装插件」需要；ffmpeg: NapCat/麦麦 语音转码需要
b xvfb xauth curl unzip ca-certificates fonts-noto-cjk tmux git ffmpeg
b libgtk-3-0t64 libnss3 libnspr4 libasound2t64 libgbm1 libxss1 libxtst6
b libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libdrm2 libxkbcommon0
b libxcomposite1 libxdamage1 libxrandr2 libpango-1.0-0 libcairo2 libdbus-1-3
b libatspi2.0-0t64 libsecret-1-0 libxfixes3 libx11-xcb1 libxcb-dri3-0 libxshmfence1

echo "== 4. 安装 QQ =="
if ! command -v qq >/dev/null 2>&1; then
  if ls "$PKG"/linuxqq_*.deb >/dev/null 2>&1; then
    echo "使用本地安装包"
    dpkg -i "$PKG"/linuxqq_*.deb || $APT install -y -f
  else
    echo "联网下载 QQ 安装包（arm64）..."
    curl -L --max-time 600 -o /tmp/qq.deb \
      "https://qqdl.gtimg.cn/qqfile/QQNT/9.9.36/beta/9ee04bef/linuxqq_3.2.34-53644_arm64.deb" || {
        echo "❌ QQ 安装包下载失败"; exit 4; }
    dpkg -i /tmp/qq.deb || $APT install -y -f
  fi
fi
dpkg -l linuxqq 2>/dev/null | tail -1 | awk '{print "QQ:",$3}'

echo "== 5. 部署 NapCat =="
rm -rf /opt/napcat-install
cp -a "$PKG"/payload/napcat-install /opt/
chmod +x /opt/napcat-install/launcher.sh
mkdir -p /opt/napcat-install/napcat/config
cp -f "$PKG"/scripts/templates/onebot11.json /opt/napcat-install/napcat/config/onebot11.json

echo "== 6. 部署麦麦实例 =="
rm -rf /opt/maibot-instance
mkdir -p /opt/maibot-instance
cp -a "$PKG"/payload/maibot/config /opt/maibot-instance/
mkdir -p /opt/maibot-instance/plugins /opt/maibot-instance/data /opt/maibot-instance/logs /opt/maibot-instance/temp
cp -a "$PKG"/payload/maibot/plugins/* /opt/maibot-instance/plugins/
cp -f "$PKG"/scripts/templates/adapter-config.toml \
      /opt/maibot-instance/plugins/MaiBot-SnowLuma-Adapter/config.toml

echo "== 7. 安装麦麦程序（PyPI 国内镜像）=="
export PATH="$H/.local/bin:$PATH"
export UV_DEFAULT_INDEX="$PYPI"
export UV_HTTP_TIMEOUT=120
export UV_LINK_MODE=copy
command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install --python 3.13 maibot 2>/dev/null || uv tool upgrade maibot
export PATH="$H/.local/bin:$PATH"
maibot --version

echo "== 8. 校验关键工具 =="
for t in git ffmpeg curl; do
  if command -v $t >/dev/null 2>&1; then echo "  ✅ $t"; else echo "  ⚠️ $t 未安装（插件市场 / 语音功能可能受限）"; fi
done

echo
echo "================ 恢复完成 ================"
echo "还需要手动做两件事："
echo "  1) 填模型：nano /opt/maibot-instance/config/model_config.toml  (base_url + api_key)"
echo "  2) 填QQ号：nano /opt/maibot-instance/config/bot_config.toml    ([bot] qq_account)"
