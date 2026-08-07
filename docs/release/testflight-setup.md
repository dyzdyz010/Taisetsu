# TestFlight 自动发布配置

`.github/workflows/testflight.yml` 会在 `main` 上的应用代码变更推送后运行：

1. 生成并检查 Xcode 工程与本地化目录。
2. 构建模拟器版本并运行单元测试和覆盖率检查。
3. 使用 App Store Connect API Key 进行签名归档。
4. 导出 IPA 并上传到 App Store Connect。

工作流不会把 Apple ID、密码、证书私钥或 API 私钥写入仓库。

## 一次性配置

在 App Store Connect 中创建 API Key，角色建议使用 `Developer`。保存下载的 `.p8` 文件；私钥只会显示一次。记录：

- Issuer ID
- Key ID
- `.p8` 文件完整内容

在 GitHub 仓库的 `Settings → Secrets and variables → Actions` 添加以下 Repository secrets：

| Secret | 内容 |
| --- | --- |
| `APPSTORE_CONNECT_KEY_ID` | API Key 的 Key ID |
| `APPSTORE_CONNECT_ISSUER_ID` | App Store Connect 的 Issuer ID |
| `APPSTORE_CONNECT_PRIVATE_KEY` | `.p8` 文件的完整 PEM 内容，包括头尾行 |

还需要在 App Store Connect 中完成：

- 创建 iOS App，Bundle ID 为 `com.dyz.Taisetsu`
- 确认 Team ID 为 `2FBFFBNMS3`
- 同意最新协议并完成税务/银行信息（发布商店时需要）
- 在 Certificates, Identifiers & Profiles 中启用 iCloud、Push Notifications 和 App Groups

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

如果没有配置三个 secrets，工作流会在签名前明确失败，不会产生半成品上传。
