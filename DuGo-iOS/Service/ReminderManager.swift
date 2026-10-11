//
//  ReminderManager.swift
//  DuGo-iOS
//
//  Created by 김승원 on 19/9/26.
//

import Combine
import Foundation
import UserNotifications

struct WishReminder {
    // MARK: - Properties

    let itemID: UUID
    let date: Date
    var identifier: String { "dugo.review.\(itemID.uuidString)" }
}

@MainActor
final class ReminderManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // MARK: - Properties

    @Published var openedItemID: UUID?
    private(set) var scheduledIDs: Set<UUID> = []
    private(set) var notice: String?
    private var queue: Task<Void, Never>?
    private var center: UNUserNotificationCenter { .current() }
    private let notificationHour = 13

    // MARK: - Methods

    func start() { center.delegate = self }

    func requestPermissionIfNeeded() async {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func synchronize(_ reminders: [WishReminder]) async {
        let previous = queue
        let task = Task { @MainActor in
            await previous?.value
            await self.performSync(reminders)
        }
        queue = task
        await task.value
    }

    // MARK: - Private Methods

    private func performSync(_ reminders: [WishReminder]) async {
        let settings = await center.notificationSettings()
        let authorized = [.authorized, .provisional, .ephemeral].contains(
            settings.authorizationStatus
        )
        let future =
            reminders
            .map { (reminder: $0, notificationDate: notificationDate(for: $0.date)) }
            .filter { $0.notificationDate > .now }
            .sorted { $0.notificationDate < $1.notificationDate }
        let selected = authorized ? Array(future.prefix(60)) : []
        let allowed = Set(selected.map { $0.reminder.identifier })
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter {
                $0.hasPrefix("dugo.review.") && !allowed.contains($0)
            }
        )
        let active = Set(reminders.map(\.identifier))
        let delivered = await center.deliveredNotifications()
        center.removeDeliveredNotifications(
            withIdentifiers: delivered.map(\.request.identifier).filter {
                $0.hasPrefix("dugo.review.") && !active.contains($0)
            }
        )
        notice = nil
        if !authorized && !future.isEmpty {
            notice = "알림 권한이 꺼져 있어요"
        } else if future.count > 60 {
            notice = "가까운 일정 60개까지 알림을 예약했어요 앱을 열 때 다음 일정을 갱신해요"
        }
        for scheduledReminder in selected {
            let reminder = scheduledReminder.reminder
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: scheduledReminder.notificationDate
            )
            if let existing = pending.first(where: { $0.identifier == reminder.identifier }),
                let trigger = existing.trigger as? UNCalendarNotificationTrigger,
                trigger.dateComponents == components
            {
                continue
            }
            let content = UNMutableNotificationContent()
            content.title = "잠시 담아둔 마음, 다시 살펴볼까요?"
            content.body = "지금 결정하지 않아도 괜찮아요"
            content.userInfo = ["wishID": reminder.itemID.uuidString]
            let request = UNNotificationRequest(
                identifier: reminder.identifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            do {
                try await center.add(request)
            } catch {
                notice = "알림을 예약하지 못했어요"
            }
        }
        let actual = await center.pendingNotificationRequests()
        scheduledIDs = Set(
            actual.compactMap { request in
                guard request.identifier.hasPrefix("dugo.review.") else { return nil }
                return UUID(uuidString: String(request.identifier.dropFirst("dugo.review.".count)))
            }
        )
    }

    private func notificationDate(for reviewDate: Date) -> Date {
        Calendar.current.date(
            bySettingHour: notificationHour,
            minute: 0,
            second: 0,
            of: reviewDate
        ) ?? reviewDate
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let text = response.notification.request.content.userInfo["wishID"] as? String,
            let id = UUID(uuidString: text)
        else { return }
        await MainActor.run { self.openedItemID = id }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
