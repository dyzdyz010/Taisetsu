import Foundation
import Testing

@testable import TaisetsuCore

struct AnniversaryDeepLinkTests {
    private let id = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

    @Test func urlRoundTripsBackToTheSameDay() throws {
        let url = try #require(AnniversaryDeepLink.url(for: id))

        #expect(url.absoluteString == "taisetsu://anniversary/00000000-0000-4000-8000-000000000001")
        #expect(AnniversaryDeepLink.anniversaryID(from: url) == id)
    }

    @Test func foreignLinksAreRejected() throws {
        for candidate in [
            "https://anniversary/00000000-0000-4000-8000-000000000001",
            "taisetsu://settings/00000000-0000-4000-8000-000000000001",
            "taisetsu://anniversary/not-a-uuid",
            "taisetsu://anniversary",
        ] {
            let url = try #require(URL(string: candidate))
            #expect(AnniversaryDeepLink.anniversaryID(from: url) == nil, "\(candidate) should not resolve")
        }
    }

    @Test func reminderPayloadCarriesTheDayItIsAbout() {
        let userInfo: [AnyHashable: Any] = [
            AnniversaryDeepLink.notificationUserInfoKey: id.uuidString
        ]

        #expect(AnniversaryDeepLink.anniversaryID(fromNotification: userInfo) == id)
    }

    @Test func malformedReminderPayloadsResolveToNothing() {
        #expect(AnniversaryDeepLink.anniversaryID(fromNotification: [:]) == nil)
        #expect(
            AnniversaryDeepLink.anniversaryID(
                fromNotification: [AnniversaryDeepLink.notificationUserInfoKey: "nope"]
            ) == nil
        )
        #expect(
            AnniversaryDeepLink.anniversaryID(fromNotification: ["other": id.uuidString]) == nil
        )
    }

    @Test func everySurfaceEmitsALinkTheWatchCanParse() throws {
        let widget = WidgetEventSnapshot(
            id: id,
            title: "纪念日",
            targetDate: .now,
            originalDate: .now,
            isAllDay: true,
            displayMode: .countdown,
            categorySymbolName: "calendar",
            categoryColorToken: "blue",
            isPinned: false
        )
        let watch = WatchEventSnapshot(
            id: id,
            title: "纪念日",
            originalDate: .now,
            upcomingDates: [.now],
            previousDate: nil,
            isAllDay: true,
            displayMode: .countdown,
            categorySymbolName: "calendar",
            categoryColorToken: "blue",
            isPinned: false,
            isVisibleInWidget: true
        )

        #expect(AnniversaryDeepLink.anniversaryID(from: try #require(widget.deepLink)) == id)
        #expect(AnniversaryDeepLink.anniversaryID(from: try #require(watch.deepLink)) == id)
    }

    @Test func onlyDaysThePhoneHasSyncedCanBeSelected() {
        let snapshot = WatchSnapshot(
            generatedAt: .now,
            timeZoneIdentifier: "UTC",
            localeIdentifier: "zh-Hans",
            events: [
                WatchEventSnapshot(
                    id: id,
                    title: "纪念日",
                    originalDate: .now,
                    upcomingDates: [.now],
                    previousDate: nil,
                    isAllDay: true,
                    displayMode: .countdown,
                    categorySymbolName: "calendar",
                    categoryColorToken: "blue",
                    isPinned: false,
                    isVisibleInWidget: true
                )
            ]
        )

        #expect(snapshot.selectableID(id) == id)
        // A link can outlive the day it points at, or arrive before the watch has synced it.
        #expect(snapshot.selectableID(UUID()) == nil)
        #expect(snapshot.selectableID(nil) == nil)
    }
}
