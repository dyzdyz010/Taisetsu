import Foundation
import Observation
import TaisetsuCore
import WatchConnectivity
import WidgetKit

/// Receives snapshots from the iPhone and keeps the watch's own copy current.
///
/// The last received snapshot is persisted, so the app and its complication still render after a
/// reboot or while the phone is out of range.
@MainActor
@Observable
final class WatchSessionReceiver {
    private(set) var snapshot: WatchSnapshot?

    private let store: WatchSnapshotStore?
    private let delegate = SessionDelegate()

    init(store: WatchSnapshotStore? = WatchSnapshotStore()) {
        self.store = store
        snapshot = try? store?.read()
        delegate.onReceive = { [weak self] payload in
            self?.ingest(payload)
        }
    }

    func activate(session: WCSession = .default) {
        guard WCSession.isSupported() else { return }
        session.delegate = delegate
        session.activate()
    }

    /// Exposed for the app to replay whatever the system already handed the session.
    func ingest(_ payload: [String: Any]) {
        guard
            let data = payload[WatchSnapshot.payloadKey] as? Data,
            let received = try? WatchSnapshot.decoder().decode(WatchSnapshot.self, from: data),
            received.schemaVersion == WatchSnapshot.currentSchemaVersion
        else { return }
        snapshot = received
        try? store?.write(received)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private final class SessionDelegate: NSObject, WCSessionDelegate, @unchecked Sendable {
    /// Set once during construction on the main actor, read from session callbacks.
    var onReceive: (@Sendable @MainActor ([String: Any]) -> Void)?

    nonisolated func session(
        _: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: Error?
    ) {}

    nonisolated func session(_: WCSession, didReceiveApplicationContext context: [String: Any]) {
        forward(context)
    }

    /// Complication transfers from the iPhone arrive here.
    nonisolated func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        forward(userInfo)
    }

    private nonisolated func forward(_ payload: [String: Any]) {
        guard let data = payload[WatchSnapshot.payloadKey] as? Data else { return }
        let handler = onReceive
        Task { @MainActor in
            handler?([WatchSnapshot.payloadKey: data])
        }
    }
}
