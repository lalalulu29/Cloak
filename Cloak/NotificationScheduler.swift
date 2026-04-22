import Foundation
import UserNotifications

struct NotificationSettings {
    var morningHour: Int
    var morningMinute: Int
    var eveningHour: Int
    var eveningMinute: Int
    var daytimeReminderCount: Int

    static let `default` = NotificationSettings(
        morningHour: 9,
        morningMinute: 0,
        eveningHour: 21,
        eveningMinute: 0,
        daytimeReminderCount: 2
    )
}

enum NotificationScheduler {
    static let morningIdentifier = "cloak.morning"
    static let eveningIdentifier = "cloak.evening"
    static let daytimePrefix = "cloak.daytime."

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    static func scheduleAll(settings: NotificationSettings) async {
        let center = UNUserNotificationCenter.current()

        var identifiers = [morningIdentifier, eveningIdentifier]
        identifiers.append(contentsOf: (0..<max(0, settings.daytimeReminderCount)).map { daytimePrefix + String($0) })
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        await scheduleMorning(center: center, settings: settings)
        await scheduleEvening(center: center, settings: settings)
        await scheduleDaytime(center: center, settings: settings)
    }

    private static func scheduleMorning(center: UNUserNotificationCenter, settings: NotificationSettings) async {
        let content = UNMutableNotificationContent()
        content.title = "Утренний номер"
        content.body = "Открой Cloak и запомни число дня"
        content.sound = .default

        var components = DateComponents()
        components.hour = settings.morningHour
        components.minute = settings.morningMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: morningIdentifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Ignore scheduling error for MVP.
        }
    }

    private static func scheduleEvening(center: UNUserNotificationCenter, settings: NotificationSettings) async {
        let content = UNMutableNotificationContent()
        content.title = "Вечерняя проверка"
        content.body = "Введи число по памяти"
        content.sound = .default

        var components = DateComponents()
        components.hour = settings.eveningHour
        components.minute = settings.eveningMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: eveningIdentifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Ignore scheduling error for MVP.
        }
    }

    private static func scheduleDaytime(center: UNUserNotificationCenter, settings: NotificationSettings) async {
        let count = max(0, settings.daytimeReminderCount)
        guard count > 0 else { return }

        let morningMinutes = settings.morningHour * 60 + settings.morningMinute
        let eveningMinutes = settings.eveningHour * 60 + settings.eveningMinute
        let span = max(60, eveningMinutes - morningMinutes)
        let step = span / (count + 1)

        for index in 0..<count {
            let totalMinutes = morningMinutes + step * (index + 1)
            let hour = max(0, min(23, totalMinutes / 60))
            let minute = max(0, min(59, totalMinutes % 60))

            let content = UNMutableNotificationContent()
            content.title = "Помнишь число?"
            content.body = "Коротко вспомни число дня, не открывая приложение"
            content.sound = .default

            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: daytimePrefix + String(index),
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                // Ignore scheduling error for MVP.
            }
        }
    }
}
