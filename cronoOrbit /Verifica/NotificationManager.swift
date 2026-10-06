import Foundation
import UserNotifications

#if os(iOS)

/// Alla fine di ogni impegno manda "Hai svolto «…»?" con tre risposte rapide: Fatto / In parte / Non fatto.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private var store: EventStore?
    private var progress: ProgressManager?
    
    private let center = UNUserNotificationCenter.current()
    private let categoryID = "VERIFY"

    func start(store: EventStore, progress: ProgressManager) {
    
        self.store = store
        self.progress = progress
        
        center.delegate = self
        
        let done = UNNotificationAction(identifier: "done", title: String(localized: "Fatto"), options: [])
        let partial = UNNotificationAction(identifier: "partial", title: String(localized: "In parte"), options: [])
        let skipped = UNNotificationAction(identifier: "skipped", title: String(localized: "Non fatto"), options: [.destructive])
        center.setNotificationCategories([
            UNNotificationCategory(identifier: categoryID, actions: [done, partial, skipped],
                                   intentIdentifiers: [], options: [])
        ])
    }

    
    func reschedule(for events: [Event]) async {
        var status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            status = await center.notificationSettings().authorizationStatus
        }
        guard status == .authorized || status == .provisional else { return }

        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map { $0.identifier }.filter { $0.hasPrefix("verify-") })

        let upcoming = events
            .filter { $0.end > .now && $0.completion == nil && !$0.isAllDay }
            .sorted { $0.end < $1.end }
            .prefix(40)                                   // iOS permette al massimo 64 notifiche in coda

        for e in upcoming {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Hai svolto «\(e.title)»?")
            content.body = String(localized: "Conferma com'è andata: il resoconto settimanale sarà più preciso.")
            content.sound = .default
            content.categoryIdentifier = categoryID
            content.userInfo = ["eventID": e.id.uuidString]

            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: e.end)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "verify-\(e.id.uuidString)",
                                                        content: content, trigger: trigger))
        }
    }

    // MARK: UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])              // mostrala anche con l'app aperta
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let idString = response.notification.request.content.userInfo["eventID"] as? String
        Task { @MainActor in
            if let idString, let id = UUID(uuidString: idString) {
                NotificationManager.shared.handle(action: action, id: id)
            }
        }
        completionHandler()
    }

    @MainActor
    private func handle(action: String, id: UUID) {
        switch action {
        case "done":    store?.setCompletion(id, status: .done)
            if let event = store?.events.first(where: { $0.id == id }) {
                           progress?.completeEvent(category: event.category.title) 
                       }
        case "partial": store?.setCompletion(id, status: .partial)
        case "skipped": store?.setCompletion(id, status: .skipped)
        default:        break
        }
    }
}

#endif
