# TestFlight 自动发布配置

`.github/workflows/testflight.yml` 会在 `main` 上的应用代码变更推送后运行：

1. 生成并检查 Xcode 工程与本地化目录。
2. 构建模拟器版本并运行单元测试和覆盖率检查。
3. 将固定的 Apple Development 签名身份导入临时钥匙串。
4. 自动生成或下载开发 provisioning profiles 并归档。
5. 使用 App Store Connect 云管理发布签名导出 IPA，然后上传。

工作流不会把 Apple ID、密码、证书私钥或 API 私钥写入仓库。证书和私钥只保存在 GitHub Actions Secrets 中，并且仅在单次任务的临时钥匙串中解密。

## 一次性配置

### App Store Connect API Key

在 App Store Connect 中创建 Team API Key，角色使用 `Admin`。CI 需要该密钥管理 provisioning profiles、使用云管理发布证书并上传构建。保存下载的 `.p8` 文件；私钥只会显示一次。记录：

- Issuer ID
- Key ID
- `.p8` 文件完整内容

### 可复用的 Apple Development 证书

GitHub runner 每次都是新机器，因此必须把同一份证书及其私钥导入临时钥匙串，不能让 Xcode 在每次构建时创建新证书。

1. 在 Apple Developer 的 Certificates 页面撤销一个不再使用的 `Apple Development: Created via API` 证书，为固定证书腾出名额。不要撤销本机仍在使用的证书。
2. 在 Mac 上打开 Xcode 的 `Settings → Accounts`，选择 Apple Account 和 Team，进入 `Manage Certificates`。
3. 点击 `+` 创建一个 `Apple Development` 证书。
4. 右键该证书，选择 `Export Certificate`，导出为带密码保护的 `.p12`。
5. 把证书转换为单行 Base64 并复制：

   ```bash
   base64 -i Taisetsu-Apple-Development.p12 | pbcopy
   ```

保留原始 `.p12` 及其密码作为离线备份。只要 CI 仍使用它，就不要在 Apple Developer 后台撤销该证书。

### GitHub Actions Secrets

在 GitHub 仓库的 `Settings → Secrets and variables → Actions` 添加以下 Repository secrets：

| Secret | 内容 |
| --- | --- |
| `APPSTORE_CONNECT_KEY_ID` | API Key 的 Key ID |
| `APPSTORE_CONNECT_ISSUER_ID` | App Store Connect 的 Issuer ID |
| `APPSTORE_CONNECT_PRIVATE_KEY` | `.p8` 文件的完整 PEM 内容，包括头尾行 |
| `APPLE_DEVELOPMENT_CERTIFICATE_BASE64` | `.p12` 文件的单行 Base64 内容 |
| `APPLE_DEVELOPMENT_CERTIFICATE_PASSWORD` | 导出 `.p12` 时设置的密码 |

工作流会在签名前验证证书确实包含可用的 `Apple Development` 代码签名身份。缺少任何 Secret 时会立即失败，不会申请新证书。

还需要在 App Store Connect 中完成：

- 创建 iOS App，Bundle ID 为 `com.dyz.Taisetsu`
- 确认 Team ID 为 `2FBFFBNMS3`
- 同意最新协议并完成税务/银行信息（发布商店时需要）
- 在 Certificates, Identifiers & Profiles 中为 `com.dyz.Taisetsu` 和 `com.dyz.Taisetsu.Widget` 启用 App Groups
- 为两个 App ID 关联 `group.com.dyz.Taisetsu`
- 启用 iCloud、Push Notifications 和 App Groups

## 第一次发布后

上传完成且构建状态变为 `Complete` 后，在 App Store Connect 的 TestFlight 页面：

1. 创建 Internal Testing group。
2. 把自己的 Apple Account 加入内部测试员。
3. 添加最新构建并开始测试。
4. iPhone 安装 TestFlight，通过邀请安装 Taisetsu。

外部测试员需要额外填写测试信息，并且第一个外部测试构建通常需要 TestFlight App Review；内部测试适合个人真机验证。

## 触发方式

- 推送应用代码到 `main`：自动发布。
- GitHub Actions → TestFlight → Run workflow：手动发布。

固定证书配置完成后，每次构建都会复用同一个签名身份；CI 只删除本次任务的临时钥匙串，不会撤销 Apple Developer 后台证书。
