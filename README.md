# Taisetsu · Important Days

Taisetsu 是一个原生 iPhone / iPad 重要日应用：记录值得期待或回望的日期，支持公历、农历、自定义周期、多提醒、分类与自由标签，并在桌面小组件中自动展示最近的事件。

**Keep the days that matter close.** / **把重要的日子，放在心上。**

## 功能

- 纪念日新增、查看、编辑、删除与搜索
- 单一分类 + 可自由组合的多个标签
- 首页置顶；置顶顺序同时影响小组件
- 公历与中国农历（含闰月）
- 不重复，或每 N 天 / 周 / 月 / 年重复
- 全天或精确到时分；倒计时、正计时或同时显示
- 每个纪念日可配置多个本地提醒
- 月历视图与系统日历单向导出
- 再次导出会更新原系统日历事件；只导出由 Taisetsu 计算出的下一次日期
- WidgetKit 小、中、大组件分别显示 1、4、5 个最近事件
- SwiftData 本地优先存储，可连接用户私人 CloudKit
- 英语、简体中文、繁体中文、日语、韩语、西班牙语、法语、德语、巴西葡萄牙语、意大利语和阿拉伯语
- 区域化日期顺序、星期起始日、相对时间和周期表达
- 深色模式、动态字体、VoiceOver 语义和阿拉伯语从右到左布局

## 技术结构

```text
LifeTimerCore   日期/周期、排序筛选、小组件快照（无 UI、可独立测试）
LifeTimer       SwiftUI、SwiftData、通知、EventKit、应用协调
LifeTimerWidget 只读取 App Group 原子 JSON 快照，不直接打开 SwiftData
```

`Taisetsu` 是所有语言地区统一使用的公开品牌名。现有的 `LifeTimer` target、bundle identifier、App Group、CloudKit 容器及持久化标识属于兼容性边界，不随品牌名改动。

`OccurrenceCalculator` 是原始日期、上一/下一次、已过/剩余时间的唯一来源。通知、系统日历、首页、月历和小组件不会各自实现一套日期规则。

## 开发环境

- macOS 26
- Xcode 26.6 / Swift 6
- iOS / iPadOS 18.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.46+
- `jq`

```bash
brew install xcodegen jq
xcodegen generate
open LifeTimer.xcodeproj
```

默认标识位于 `LifeTimerCore/Configuration/AppConfiguration.swift`：

- App Group：`group.com.dyz.LifeTimer`
- CloudKit：`iCloud.com.dyz.LifeTimer`

在真机签名前，请在自己的 Apple Developer Team 中创建相应容器，或同时修改配置、entitlements 与 `project.yml` 后重新生成工程。模拟器构建和测试不需要个人签名。

## 验证

```bash
# 本地化、工程漂移、格式、无签名构建、单元测试和 Core 覆盖率门槛
bash scripts/verify.sh

# 额外执行新增纪念日 UI 流程
LIFETIMER_INCLUDE_UI_TESTS=1 bash scripts/verify.sh
```

CI 使用 GitHub `macos-26` + Xcode 26.6，包含：

- XcodeGen 生成结果漂移检查
- 11 个语言地区的 String Catalog 完整性与生成结果漂移检查
- `swift-format` lint
- App + Core + Widget 无签名构建
- 单元测试与 `xcresult` 证据
- `LifeTimerCore` 行覆盖率至少 80%
- 新增纪念日 UI 冒烟测试
- Swift CodeQL 扫描、PR 依赖审查与 Dependabot
- 最小权限、并发取消、超时和失败产物上传

## 数据与隐私

Taisetsu 没有自建服务器或账户系统。重要日保存在设备与用户私人 iCloud 数据库中；小组件只读取 App Group 内的最小展示快照。日历导出和通知权限只在对应功能需要时请求。

品牌与本地化维护规则见 [docs/brand-localization.md](docs/brand-localization.md)。

## 许可证

[MIT](LICENSE)
