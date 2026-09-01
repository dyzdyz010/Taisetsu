import Foundation
import Testing

@testable import Taisetsu
@testable import TaisetsuCore

@MainActor
struct WatchTransportTests {
    @Test func firstDeliverySpendsTheComplicationTransfer() {
        let transport = FakeWatchTransport()
        let dispatcher = WatchSnapshotDispatcher(transport: transport)

        #expect(dispatcher.deliver(snapshot(titles: ["生日"])) == .complicationRefresh)
        #expect(transport.sent.count == 1)
    }

    @Test func movingOnlyTheTimestampDoesNotSpendTheComplicationBudget() {
        let transport = FakeWatchTransport()
        let dispatcher = WatchSnapshotDispatcher(transport: transport)
        dispatcher.deliver(snapshot(titles: ["生日"], generatedAt: referenceDate))

        let later = dispatcher.deliver(
            snapshot(titles: ["生日"], generatedAt: referenceDate.addingTimeInterval(3_600))
        )

        // Reconcile runs often; only real content changes may wake the watch.
        #expect(later == .applicationContext)
        #expect(transport.sent.count == 2)
    }

    @Test func changedContentSpendsTheComplicationTransferAgain() {
        let transport = FakeWatchTransport()
        let dispatcher = WatchSnapshotDispatcher(transport: transport)
        dispatcher.deliver(snapshot(titles: ["生日"]))

        #expect(dispatcher.deliver(snapshot(titles: ["生日", "纪念日"])) == .complicationRefresh)
    }

    @Test func nothingIsSentWhenNoWatchCanReceive() {
        let transport = FakeWatchTransport()
        transport.canDeliver = false
        let dispatcher = WatchSnapshotDispatcher(transport: transport)

        #expect(dispatcher.deliver(snapshot(titles: ["生日"])) == nil)
        #expect(transport.sent.isEmpty)
    }

    @Test func aFailedDeliveryIsRetriedAsAContentChange() {
        let transport = FakeWatchTransport()
        transport.failsNextSend = true
        let dispatcher = WatchSnapshotDispatcher(transport: transport)

        #expect(dispatcher.deliver(snapshot(titles: ["生日"])) == nil)
        // The failure must not be recorded as delivered content.
        #expect(dispatcher.deliver(snapshot(titles: ["生日"])) == .complicationRefresh)
    }

    private let referenceDate = ISO8601DateFormatter().date(from: "2026-08-03T00:00:00Z")!

    private func snapshot(titles: [String], generatedAt: Date? = nil) -> WatchSnapshot {
        WatchSnapshot(
            generatedAt: generatedAt ?? referenceDate,
            timeZoneIdentifier: "UTC",
            localeIdentifier: "zh-Hans",
            events: titles.enumerated().map { index, title in
                WatchEventSnapshot(
                    id: UUID(uuidString: "00000000-0000-4000-8000-00000000000\(index)")!,
                    title: title,
                    originalDate: referenceDate,
                    upcomingDates: [referenceDate.addingTimeInterval(86_400)],
                    previousDate: nil,
                    isAllDay: true,
                    displayMode: .countdown,
                    categorySymbolName: "calendar",
                    categoryColorToken: "blue",
                    isPinned: false,
                    isVisibleInWidget: true
                )
            }
        )
    }
}

@MainActor
private final class FakeWatchTransport: WatchTransport {
    struct DeliveryError: Error {}

    var canDeliver = true
    var failsNextSend = false
    private(set) var sent: [(snapshot: WatchSnapshot, priority: WatchDeliveryPriority)] = []

    func send(_ snapshot: WatchSnapshot, priority: WatchDeliveryPriority) throws {
        if failsNextSend {
            failsNextSend = false
            throw DeliveryError()
        }
        sent.append((snapshot, priority))
    }
}
