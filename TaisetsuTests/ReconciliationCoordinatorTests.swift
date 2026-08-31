import SwiftData
import Testing
import UserNotifications

@testable import Taisetsu

@MainActor
struct ReconciliationCoordinatorTests {
    @Test func overlappingRequestsCoalesceIntoOneFollowUp() async throws {
        let repository = AnniversaryRepository(
            context: ModelContext(try ModelContainerFactory.makeInMemory())
        )
        let client = SuspendingNotificationClient()
        let coordinator = ReconciliationCoordinator(
            repository: repository,
            notificationClient: client,
            snapshotStore: nil
        )

        let first = Task { await coordinator.reconcile() }
        await client.waitForFirstCall()
        let second = Task { await coordinator.reconcile() }
        let third = Task { await coordinator.reconcile() }
        await Task.yield()
        client.releaseFirstCall()

        await first.value
        await second.value
        await third.value

        #expect(client.callCount == 2)
        #expect(client.maximumConcurrentCalls == 1)
    }
}

@MainActor
private final class SuspendingNotificationClient: NotificationCenterClientProtocol {
    private(set) var callCount = 0
    private(set) var maximumConcurrentCalls = 0
    private var activeCalls = 0
    private var firstCallContinuation: CheckedContinuation<Void, Never>?

    func authorizationStatus() async -> UNAuthorizationStatus { .authorized }

    func requestAuthorization() async throws -> Bool { true }

    func replaceTaisetsuRequests(with _: [ScheduledReminder]) async throws {
        callCount += 1
        activeCalls += 1
        maximumConcurrentCalls = max(maximumConcurrentCalls, activeCalls)
        if callCount == 1 {
            await withCheckedContinuation { continuation in
                firstCallContinuation = continuation
            }
        }
        activeCalls -= 1
    }

    func waitForFirstCall() async {
        while callCount == 0 {
            await Task.yield()
        }
    }

    func releaseFirstCall() {
        firstCallContinuation?.resume()
        firstCallContinuation = nil
    }
}
