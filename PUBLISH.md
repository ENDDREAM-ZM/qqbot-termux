# 怎么发布到 GitHub

这个目录是**干净的仓库内容**（不含 `.git`、不含任何敏感信息），需要你用自己的 GitHub 账号推上去。

## 方式 A：gh CLI（最简单，3 条命令）

```bash
# 1. 解压 + 初始化
tar xzf qqbot-termux-repo.tar.gz
cd qqbot-termux
git init && git add -A && git commit -m "feat: QQ Bot on Termux 一键部署（MaiBot + NapCat）"

# 2. 登录（浏览器输一次性验证码）
gh auth login

# 3. 建仓库并推送
gh repo create qqbot-termux --public --source=. --push
```

> Termux / Linux 上装 gh：`pkg install gh`（Termux）或 `sudo apt install gh`（Debian/Ubuntu）

## 方式 B：先在网页建仓，再 push

1. 打开 https://github.com/new 建一个**空**仓库（不要勾 README / .gitignore / LICENSE）
2. 然后：

```bash
tar xzf qqbot-termux-repo.tar.gz
cd qqbot-termux
git init && git add -A && git commit -m "feat: QQ Bot on Termux 一键部署"
git branch -M main
git remote add origin https://github.com/你的用户名/qqbot-termux.git
git push -u origin main
```

提示输密码时，粘贴 **Personal Access Token**（Settings → Developer settings → Personal access tokens → 勾选 `repo`），不要用账号密码。

## 注意

- 仓库本体约 **113 MB**（含 NapCat 多平台原生库），首次 push 建议开代理或加速
- 中断了直接 `git push` 重试，已传部分不会重传
- 仓库里**不含**：QQ 登录态、API Key、QQ 安装包、Ubuntu rootfs——都由使用者自行准备（见 `packages/README.md`）

## Release 离线包

发版时另打的离线包 = 仓库内容 + `packages/ubuntu-rootfs-arm64.tar.gz`（约 29 MB），
压缩后约 **62 MB**，让用户即使连不上 GitHub 也能装容器。

## 想再瘦一点

`payload/napcat-install/napcat/native/` 里有各平台的预编译库，其中 x64 / darwin / win32 加起来约 80MB。
只想服务 Android（arm64）的话：

```bash
cd payload/napcat-install/napcat/native
find . -type f \( -name "*x64*" -o -name "*darwin*" -o -name "*win32*" \) -delete
git add -A && git commit -m "chore: 只保留 arm64 原生库"
```

体积可从 113MB 降到约 35MB。

## 发布前建议再确认一遍

```bash
grep -rIl --exclude-dir=node_modules -e "sk-" -e "@qq.com" -e "^[0-9]\{9,10\}$" . | head
```

确认没有把你的 Key、QQ 号、登录态带出去。
