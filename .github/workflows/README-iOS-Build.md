# iOS 构建配置说明

## GitHub Action 自动打包 iOS

本项目已配置 GitHub Action 自动打包 iOS 安装包。支持以下触发方式：

### 触发方式

1. **自动触发**：推送到 `main`、`master` 或 `develop` 分支时自动构建
2. **Pull Request**：创建 PR 到上述分支时触发
3. **手动触发**：在 GitHub Actions 页面手动运行，可选择构建模式（release/debug/profile）

## iOS 代码签名配置（必需）

要构建可安装的 IPA 文件，需要配置 iOS 代码签名证书和 Provisioning Profile。

### 步骤 1: 准备签名文件

#### 1.1 导出证书（.p12 文件）
1. 打开 **钥匙串访问**（Keychain Access）
2. 找到你的 iOS 开发/发布证书
3. 右键点击证书 → 导出
4. 选择 .p12 格式，设置密码
5. Base64 编码证书：
   ```bash
   base64 -i your_certificate.p12 | pbcopy
   ```

#### 1.2 导出 Provisioning Profile
1. 访问 [Apple Developer Portal](https://developer.apple.com/account/resources/profiles/list)
2. 下载对应的 Provisioning Profile（.mobileprovision 文件）
3. Base64 编码：
   ```bash
   base64 -i your_profile.mobileprovision | pbcopy
   ```

### 步骤 2: 配置 GitHub Secrets

在你的 GitHub 仓库中，进入 **Settings → Secrets and variables → Actions**，添加以下 secrets：

| Secret 名称 | 说明 | 示例 |
|------------|------|------|
| `IOS_CERTIFICATE` | Base64 编码的 .p12 证书文件 | `MIIM...` (Base64 字符串) |
| `IOS_CERTIFICATE_PASSWORD` | .p12 文件的密码 | `your_password` |
| `IOS_PROVISIONING_PROFILE` | Base64 编码的 provisioning profile | `MIIM...` (Base64 字符串) |
| `KEYCHAIN_PASSWORD` | 临时钥匙串密码（可自定义） | `temporary_password` |

### 步骤 3: 配置 Xcode 项目

确保 `ios/Runner.xcodeproj` 中的签名配置正确：

1. 打开 `ios/Runner.xcworkspace`
2. 选择 Runner 项目
3. 在 **Signing & Capabilities** 中：
   - 勾选 "Automatically manage signing"（如果使用自动签名）
   - 或手动选择 Team 和 Provisioning Profile

### 步骤 4: 更新 Bundle ID

如果需要修改 Bundle Identifier，请更新以下文件：

1. `ios/Runner.xcodeproj/project.pbxproj`
2. `ios/Runner/Info.plist`

## 无代码签名构建

如果没有配置签名证书，workflow 会构建未签名的 App Bundle（Runner.app），该文件无法直接安装到设备，但可以用于测试和验证。

## 手动运行构建

1. 进入 GitHub 仓库的 **Actions** 页面
2. 选择 **Build iOS** workflow
3. 点击 **Run workflow**
4. 选择构建模式：
   - `release` - 正式发布版本
   - `debug` - 调试版本
   - `profile` - 性能分析版本
5. 点击 **Run workflow** 开始构建

## 下载构建产物

构建完成后：

1. 进入 Actions 页面对应的 workflow 运行记录
2. 滚动到底部 **Artifacts** 区域
3. 下载对应的 artifact：
   - 有签名：`ios-build-{mode}` (包含 .ipa 文件)
   - 无签名：`ios-app-{mode}` (包含 Runner.app)

## 常见问题

### 1. 构建失败：证书相关错误
- 检查 `IOS_CERTIFICATE` 和 `IOS_PROVISIONING_PROFILE` 是否正确 Base64 编码
- 确认证书未过期
- 确保 Provisioning Profile 包含正确的 Bundle ID 和设备 UDID

### 2. 构建失败：Pod install 错误
```bash
cd ios
pod deintegrate
pod install
```

### 3. 签名后仍无法安装
- 确认 Provisioning Profile 包含测试设备的 UDID
- 检查 Bundle ID 是否与 Provisioning Profile 匹配
- 确认使用的是发布证书（Distribution）而非开发证书（Development）

## 本地测试构建

在提交到 GitHub 之前，可以本地测试 iOS 构建：

```bash
# 获取依赖
flutter pub get

# 安装 iOS 依赖
cd ios && pod install && cd ..

# 构建未签名版本（测试）
flutter build ios --release --no-codesign

# 构建签名版本
flutter build ios --release
```

## 参考资料

- [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)
- [GitHub Actions for iOS](https://github.com/actions/runner-images/blob/main/images/macos/macos-13-Readme.md)
- [iOS 代码签名指南](https://developer.apple.com/support/code-signing/)
