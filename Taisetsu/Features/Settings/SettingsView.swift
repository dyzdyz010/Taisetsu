import SwiftUI

struct SettingsView: View {
    let repository: AnniversaryRepository

    var body: some View {
        NavigationStack {
            List {
                Section("Organization") {
                    NavigationLink {
                        CategoryManagerView(repository: repository)
                    } label: {
                        Label("Manage Categories", systemImage: "folder")
                    }
                    NavigationLink {
                        TagManagerView(repository: repository)
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }
                Section("Sync & Permissions") {
                    LabeledContent("iCloud", value: "Automatic Sync")
                    Label("Notification access is requested when you add a reminder", systemImage: "bell")
                    Label("Calendar access is requested when you export", systemImage: "calendar.badge.plus")
                }
                Section("About") {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("Your data stays on your device and in your private iCloud database.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
