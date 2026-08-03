import SwiftUI

struct SettingsView: View {
    let repository: AnniversaryRepository

    var body: some View {
        NavigationStack {
            List {
                Section("整理") {
                    NavigationLink {
                        CategoryManagerView(repository: repository)
                    } label: {
                        Label("分类管理", systemImage: "folder")
                    }
                    NavigationLink {
                        TagManagerView(repository: repository)
                    } label: {
                        Label("标签管理", systemImage: "tag")
                    }
                }
                Section("同步与权限") {
                    LabeledContent("iCloud", value: "自动同步")
                    Label("通知权限在首次添加提醒时申请", systemImage: "bell")
                    Label("日历权限在导出时申请", systemImage: "calendar.badge.plus")
                }
                Section("关于") {
                    LabeledContent(
                        "版本",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("数据优先保存在你的设备与私人 iCloud 中。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}
