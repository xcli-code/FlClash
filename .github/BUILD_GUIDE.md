# FlClash GitHub Actions 自动构建安装包指南

本文档说明如何在本仓库使用 GitHub Actions 自动构建多平台安装包。

---

## 一、触发自动构建

### 1.1 触发方式

Workflow 文件：`.github/workflows/build.yaml`

**触发条件：** 推送**标签（tag）**，且标签名符合 `v*`（如 `v1.0.0`、`v2.0.0-beta.1`）。

```bash
# 创建并推送标签以触发构建
git tag v1.0.0
git push origin v1.0.0
```

- **稳定版**：标签不含 `-`（如 `v1.0.0`）→ 会创建 GitHub Release、生成 sha256、可选推送到 F-Droid 仓库。
- **预发布**：标签含 `-`（如 `v1.0.0-beta.1`）→ 只构建产物并上传到 Artifacts，不创建 Release。

### 1.2 构建矩阵

| 平台     | 系统               | 架构   |
|----------|--------------------|--------|
| Android  | ubuntu-latest      | 多架构 |
| Windows  | Windows-2022       | amd64  |
| Linux    | ubuntu-22.04       | amd64  |
| Linux    | ubuntu-24.04-arm   | arm64  |
| macOS    | macos-15-intel     | amd64  |
| macOS    | macos-latest       | arm64  |

构建产物会作为 **Artifacts** 出现在对应 workflow run 中；稳定版还会发布到 **Releases** 页。

---

## 二、构建前准备（Secrets 配置）

在仓库 **Settings → Secrets and variables → Actions** 中配置以下 Secrets，否则相关步骤会失败或跳过。

### 2.1 必选（Android 签名，否则 Android 构建会失败）

| Secret 名称       | 说明 |
|-------------------|------|
| `KEYSTORE`        | Base64 编码的 keystore 文件内容 |
| `KEY_ALIAS`       | 签名别名 |
| `STORE_PASSWORD`  | keystore 密码 |
| `KEY_PASSWORD`    | key 密码 |
| `SERVICE_JSON`    | Base64 编码的 `google-services.json`（如使用 Firebase） |

生成 Base64：

```bash
base64 -w0 android/app/keystore.jks | pbcopy   # Linux/macOS
base64 -w0 android/app/google-services.json | pbcopy
```

### 2.2 可选（Release 与通知）

| Secret 名称       | 说明 |
|-------------------|------|
| `GITHUB_TOKEN`    | 默认存在，用于创建 Release、推送 changelog |
| `TELEGRAM_BOT_TOKEN` | Telegram 机器人 token，用于构建完成后推送到频道 |
| `TELEGRAM_API_ID` / `TELEGRAM_API_HASH` | 若使用 Telegram Bot API 本地服务时填写 |
| `SSH_DEPLOY_KEY`  | 推送到 F-Droid 仓库的 SSH 私钥（仅稳定版需推 F-Droid 时） |

不配置 Telegram / F-Droid 相关 Secrets 时，对应步骤会失败或需在 workflow 中关闭，不影响「构建 + 上传 Artifacts + 创建 Release」。

### 2.3 权限

- **Release 步骤** 使用 `permissions: write-all`，以便 `action-gh-release` 创建 Release。
- 若只希望「构建 + Artifacts」而不发布 Release，可删除或条件化 `upload` job 中的 Release 相关步骤。

---

## 三、构建产物与下载

1. **Actions 页**：  
   `https://github.com/<你的用户名>/FlClash/actions`  
   进入对应 tag 的 workflow run → 在页面底部下载各平台的 **Artifacts**（如 `artifact-android`、`artifact-windows-amd64` 等）。

2. **Releases 页（仅稳定版）**：  
   `https://github.com/<你的用户名>/FlClash/releases`  
   会看到自动生成的 Release 和附件（含 `.sha256`）。

3. **Release 说明**：  
   由 `release_template.md` + 自动生成的 changelog 拼接而成，下载链接中的仓库名已改为 `xcli-code/FlClash`；若你使用自己的 fork 发布，可在 `.github/release_template.md` 中把 `xcli-code` 改为你的 GitHub 用户名。

---

## 四、发版的推荐流程

```bash
# 需要发版时
git tag vx.y.z
git push origin vx.y.z
```

---

## 六、常见问题

- **Android 构建失败**：检查 `KEYSTORE`、`KEY_ALIAS`、`STORE_PASSWORD`、`KEY_PASSWORD`、`SERVICE_JSON` 是否正确且为 Base64。
- **Release 未创建**：确认 tag 为稳定版（不含 `-`），且仓库有 `GITHUB_TOKEN` 写权限（默认有）。
- **Changelog 推送失败**：若 fork 无写 main 权限或未配置 token，可禁用 `changepog` job 或改为仅在本分支生成 changelog 不推送。
- **F-Droid 推送失败**：检查 `SSH_DEPLOY_KEY` 及目标仓库 `FlClash-fdroid-repo` 是否存在且可写；不需要 F-Droid 时可删除或条件化对应步骤。

---

**总结**：推送 `v*` 标签即可触发多平台自动构建；在仓库中配置好 Android 签名等 Secrets 后，即可在 Actions 和 Releases 中获取安装包。
