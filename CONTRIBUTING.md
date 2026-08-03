# 参与贡献

感谢你改进 LifeTimer。提交变更前请：

1. 安装 Xcode 26.6、XcodeGen 2.46 或更高版本，以及 `jq`。
2. 从 `main` 创建短生命周期分支。
3. 为日期、排序、持久化或系统集成行为先添加测试。
4. 运行 `bash scripts/verify.sh`；界面变更再运行 `LIFETIMER_INCLUDE_UI_TESTS=1 bash scripts/verify.sh`。
5. 保持 SwiftData 字段有默认值或为可选，关系为可选，不依赖唯一约束，以维持 CloudKit 兼容性。

请勿提交签名证书、开发团队 ID、真实 iCloud 数据或个人纪念日内容。

