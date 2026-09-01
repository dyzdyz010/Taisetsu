import Foundation
import TaisetsuCore
import WatchConnectivity

enum WatchDeliveryPriority: Equatable, Sendable {
    /// Cheap and coalesced: the system keeps only the most recent one and delivers it on reconnect.
    case applicationContext
    /// Budgeted per day, so it is spent only when the displayed content actually changed.
    case complicationRefresh
}

@MainActor
protocol WatchTransport: AnyObject {
    var canDeliver: Bool { get }
    func send(_ snapshot: WatchSnapshot, priority: WatchDeliveryPriority) throws
}

/// Decides how a snapshot reaches the watch.
///
/// Every reconcile pushes the latest state cheaply; the budgeted complication transfer is spent
/// only when `contentDigest` shows the wearer would actually see something different.
@MainActor
final class WatchSnapshotDispatcher {
    private let transport: WatchTransport
    private var lastDeliveredDigest: String?

    init(transport: WatchTransport) {
        self.transport = transport
    }

    @discardableResult
    func deliver(_ snapshot: WatchSnapshot) -> WatchDeliveryPriority? {
        guard transport.canDeliver else { return nil }
        let digest = snapshot.contentDigest
        let priority: WatchDeliveryPriority =
            digest == lastDeliveredDigest ? .applicationContext : .complicationRefresh
        do {
            try transport.send(snapshot, priority: priority)
            lastDeliveredDigest = digest
            return priority
        } catch {
            // Leave the digest untouched so the next reconcile retries instead of assuming delivery.
            return nil
        }
    }
}

@MainActor
final class WatchConnectivityTransport: NSObject, WatchTransport {
    static func makeIfSupported() -> WatchConnectivityTransport? {
        guard WCSession.isSupported() else { return nil }
        return WatchConnectivityTransport(session: .default)
    }

    private let session: WCSession

    init(session: WCSession) {
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
    }

    var canDeliver: Bool {
        session.activationState == .activated && session.isPaired && session.isWatchAppInstalled
    }

    func send(_ snapshot: WatchSnapshot, priority: WatchDeliveryPriority) throws {
        let payload: [String: Any] = [
            WatchSnapshot.payloadKey: try WatchSnapshot.encoder().encode(snapshot)
        ]
        try session.updateApplicationContext(payload)
        if priority == .complicationRefresh {
            session.transferCurrentComplicationUserInfo(payload)
        }
    }
}

extension WatchConnectivityTransport: WCSessionDelegate {
    nonisolated func session(
        _: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: Error?
    ) {}

    nonisolated func sessionDidBecomeInactive(_: WCSession) {}

    /// The wearer switched watches; reactivate so the new one starts receiving snapshots.
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
