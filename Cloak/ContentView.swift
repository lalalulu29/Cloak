//
//  ContentView.swift
//  Cloak
//
//  Created by Кирилл Любарских on 17.04.2026.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyChallenge.dayStart, order: .reverse) private var challenges: [DailyChallenge]

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("morningHour") private var morningHour = NotificationSettings.default.morningHour
    @AppStorage("morningMinute") private var morningMinute = NotificationSettings.default.morningMinute
    @AppStorage("eveningHour") private var eveningHour = NotificationSettings.default.eveningHour
    @AppStorage("eveningMinute") private var eveningMinute = NotificationSettings.default.eveningMinute
    @AppStorage("daytimeReminderCount") private var daytimeReminderCount = NotificationSettings.default.daytimeReminderCount
    @AppStorage("beforeMidnightReminderMinutes") private var beforeMidnightReminderMinutes = NotificationSettings.default.beforeMidnightReminderMinutes
    @AppStorage("numberLength") private var numberLength = 4

    @State private var isShowingRevealSheet = false
    @State private var answerInput = ""
    @State private var resultMessage = ""
    @State private var notificationStatusText = "Статус уведомлений не проверен"
    @State private var selectedTab: RootTab = .today
    @State private var isShowingOnboarding = false
    @State private var isShowingNotificationAlert = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                todayTabContent
                    .navigationTitle("Сегодня")
            }
            .tabItem {
                Label("Сегодня", systemImage: "sun.max")
            }
            .tag(RootTab.today)

            NavigationStack {
                historyTabContent
                    .navigationTitle("История")
            }
            .tabItem {
                Label("История", systemImage: "clock.arrow.circlepath")
            }
            .tag(RootTab.history)

            NavigationStack {
                settingsTabContent
                    .navigationTitle("Настройки")
            }
            .tabItem {
                Label("Настройки", systemImage: "gear")
            }
            .tag(RootTab.settings)
        }
        .task {
            await bootstrapAppState()
        }
        .onAppear {
            isShowingOnboarding = !hasSeenOnboarding
        }
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView(
                initialStartTime: bindingForTime(hour: $morningHour, minute: $morningMinute).wrappedValue,
                initialEndTime: bindingForTime(hour: $eveningHour, minute: $eveningMinute).wrappedValue,
                initialDifficulty: reminderDifficultyForOnboarding(count: daytimeReminderCount)
            ) { config in
                applyOnboarding(config: config)
            }
            .interactiveDismissDisabled()
        }
        .alert("Нужны уведомления", isPresented: $isShowingNotificationAlert) {
            Button("Открыть настройки") {
                openSystemSettings()
            }
            Button("Позже", role: .cancel) {}
        } message: {
            Text("Для ежедневного цикла Cloak нужны уведомления: утром показать число, вечером проверить ответ.")
        }
    }

    private var todayChallenge: DailyChallenge? {
        let todayStart = Calendar.current.startOfDay(for: .now)
        return challenges.first(where: { $0.dayStart == todayStart })
    }

    private var todayTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let todayChallenge {
                    let status = DailyChallengeService.dayStatus(for: todayChallenge)

                    dayStatusCard(status: status)
                    todayActionSection(challenge: todayChallenge, status: status)
                    statsCard
                } else {
                    ProgressView("Готовим задание дня...")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isShowingRevealSheet) {
            if let todayChallenge {
                MorningRevealView(number: todayChallenge.value)
            }
        }
    }

    @ViewBuilder
    private func dayStatusCard(status: DayStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Статус дня")
                .font(.headline)

            switch status {
            case .notRevealed:
                Label("Число еще не показано", systemImage: "eye.slash")
            case .awaitingAnswer:
                Label("Число уже было показано, ждем вечерний ввод", systemImage: "moon")
            case .completed:
                Label("День завершен", systemImage: "checkmark.circle")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func todayActionSection(challenge: DailyChallenge, status: DayStatus) -> some View {
        switch status {
        case .notRevealed:
            VStack(alignment: .leading, spacing: 12) {
                Text("Утренний шаг")
                    .font(.headline)
                Text("Нажми, чтобы увидеть число дня. После подтверждения оно больше не показывается.")
                    .foregroundStyle(.secondary)
                Button("Показать число") {
                    revealTodayNumber(challenge)
                }
                .buttonStyle(.borderedProminent)
            }

        case .awaitingAnswer:
            let isCheckAvailable = isEveningCheckAvailable()
            VStack(alignment: .leading, spacing: 12) {
                Text("Вечерняя проверка")
                    .font(.headline)
                if !isCheckAvailable {
                    Text("Проверка откроется после \(eveningCheckTimeString())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    TextField("Введи число", text: $answerInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: answerInput) { _, newValue in
                            answerInput = newValue.filter(\.isNumber)
                        }

                    Button("Проверить") {
                        submitAnswer(for: challenge)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(answerInput.count != challenge.length)
                }

                if !resultMessage.isEmpty {
                    Text(resultMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

        case .completed:
            VStack(alignment: .leading, spacing: 12) {
                Text("Результат за сегодня")
                    .font(.headline)

                if let result = challenge.result {
                    Text(resultTitle(result))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                if let userAnswer = challenge.userAnswer {
                    Text("Твой ответ: \(userAnswer)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var historyTabContent: some View {
        List {
            if challenges.isEmpty {
                Text("Пока нет записей")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(challenges) { challenge in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.dayStart, style: .date)
                                .font(.headline)
                            Text(historySubtitle(challenge: challenge))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(historyStatus(challenge))
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(challenge).opacity(0.15), in: Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var settingsTabContent: some View {
        Form {
            Section("Уведомления") {
                Text(notificationStatusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                DatePicker(
                    "Начало дня",
                    selection: bindingForTime(hour: $morningHour, minute: $morningMinute),
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    "Конец дня",
                    selection: bindingForTime(hour: $eveningHour, minute: $eveningMinute),
                    displayedComponents: .hourAndMinute
                )

                Stepper("Дневные напоминания: \(daytimeReminderCount)", value: $daytimeReminderCount, in: 1...5)
                Stepper(
                    "Напомнить до полуночи: \(beforeMidnightReminderMinutes) мин",
                    value: $beforeMidnightReminderMinutes,
                    in: 5...180,
                    step: 5
                )
            }

            Section("Тренировка") {
                Stepper("Длина числа: \(numberLength)", value: $numberLength, in: 3...8)
                Text("Изменение применяется к ближайшему не начатому периоду.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("О приложении") {
                Text("Cloak тренирует память через ежедневный цикл: утром запомнил, вечером проверил.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: morningHour) { _, _ in Task { await scheduleNotifications() } }
        .onChange(of: morningMinute) { _, _ in Task { await scheduleNotifications() } }
        .onChange(of: eveningHour) { _, _ in Task { await scheduleNotifications() } }
        .onChange(of: eveningMinute) { _, _ in Task { await scheduleNotifications() } }
        .onChange(of: daytimeReminderCount) { _, _ in Task { await scheduleNotifications() } }
        .onChange(of: beforeMidnightReminderMinutes) { _, _ in Task { await scheduleNotifications() } }
        .onChange(of: numberLength) { _, _ in
            applyNumberLengthForNearestUnstartedPeriod()
        }
    }

    private var statsCard: some View {
        let stats = DailyChallengeService.computeStats(from: challenges)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Статистика")
                .font(.headline)

            HStack {
                statItem(title: "Текущая серия", value: String(stats.currentStreak))
                statItem(title: "Лучшая серия", value: String(stats.bestStreak))
                statItem(title: "Точность", value: "\(stats.accuracyPercent)%")
            }

            Text("Ответов: \(stats.totalAnswered)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func revealTodayNumber(_ challenge: DailyChallenge) {
        challenge.shownAt = .now
        do {
            try modelContext.save()
            answerInput = ""
            resultMessage = ""
            isShowingRevealSheet = true
        } catch {
            resultMessage = "Не удалось сохранить состояние дня"
        }
    }

    private func submitAnswer(for challenge: DailyChallenge) {
        guard isEveningCheckAvailable() else {
            resultMessage = "Проверка будет доступна после \(eveningCheckTimeString())"
            return
        }

        let normalizedAnswer = answerInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedAnswer.count == challenge.length else {
            resultMessage = "Длина ответа должна быть \(challenge.length) цифры"
            return
        }

        challenge.userAnswer = normalizedAnswer
        challenge.answeredAt = .now
        challenge.result = normalizedAnswer == challenge.value ? .correct : .wrong

        do {
            try modelContext.save()
            if challenge.result == .correct {
                resultMessage = "Верно. Отличная работа."
            } else {
                resultMessage = "Неверно. Завтра новое число."
            }
            answerInput = ""
        } catch {
            resultMessage = "Не удалось сохранить ответ"
        }
    }

    private func bootstrapAppState() async {
        do {
            _ = try DailyChallengeService.refreshCurrentDay(in: modelContext, length: numberLength)
            try DailyChallengeService.applyPreferredLengthToUnstartedCurrentDay(in: modelContext, length: numberLength)
        } catch {
            resultMessage = "Не удалось подготовить задание дня"
        }

        let authorized = await NotificationScheduler.isAuthorized()
        notificationStatusText = authorized ? "Уведомления разрешены" : "Уведомления не разрешены"
        if authorized {
            await scheduleNotifications()
        } else if hasSeenOnboarding {
            isShowingNotificationAlert = true
        }
    }

    private func scheduleNotifications() async {
        let settings = NotificationSettings(
            morningHour: morningHour,
            morningMinute: morningMinute,
            eveningHour: eveningHour,
            eveningMinute: eveningMinute,
            daytimeReminderCount: daytimeReminderCount,
            beforeMidnightReminderMinutes: beforeMidnightReminderMinutes
        )
        await NotificationScheduler.scheduleAll(settings: settings)
    }

    private func applyOnboarding(config: OnboardingConfig) {
        let start = Calendar.current.dateComponents([.hour, .minute], from: config.startTime)
        let end = Calendar.current.dateComponents([.hour, .minute], from: config.endTime)

        morningHour = start.hour ?? morningHour
        morningMinute = start.minute ?? morningMinute
        eveningHour = end.hour ?? eveningHour
        eveningMinute = end.minute ?? eveningMinute
        daytimeReminderCount = config.difficulty.reminderCount
        applyNumberLengthForNearestUnstartedPeriod()

        hasSeenOnboarding = true
        isShowingOnboarding = false

        Task {
            let granted = await NotificationScheduler.requestPermission()
            notificationStatusText = granted ? "Уведомления разрешены" : "Уведомления не разрешены"
            if granted {
                await scheduleNotifications()
            } else {
                isShowingNotificationAlert = true
            }
        }
    }

    private func openSystemSettings() {
#if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
#endif
    }

    private func bindingForTime(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding<Date> {
            let calendar = Calendar.current
            return calendar.date(
                from: DateComponents(
                    year: 2000,
                    month: 1,
                    day: 1,
                    hour: hour.wrappedValue,
                    minute: minute.wrappedValue
                )
            ) ?? .now
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            hour.wrappedValue = components.hour ?? hour.wrappedValue
            minute.wrappedValue = components.minute ?? minute.wrappedValue
        }
    }

    private func isEveningCheckAvailable(now: Date = .now) -> Bool {
        now >= eveningCheckStartDate(for: now)
    }

    private func eveningCheckStartDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return calendar.date(
            bySettingHour: eveningHour,
            minute: eveningMinute,
            second: 0,
            of: dayStart
        ) ?? dayStart
    }

    private func eveningCheckTimeString() -> String {
        String(format: "%02d:%02d", eveningHour, eveningMinute)
    }

    private func reminderDifficultyForOnboarding(count: Int) -> ReminderDifficulty {
        switch count {
        case 5:
            return .easy
        case 4:
            return .normal
        case 3:
            return .hard
        default:
            return .intense
        }
    }

    private func applyNumberLengthForNearestUnstartedPeriod() {
        do {
            try DailyChallengeService.applyPreferredLengthToUnstartedCurrentDay(in: modelContext, length: numberLength)
        } catch {
            resultMessage = "Не удалось применить длину числа"
        }
    }

    private func resultTitle(_ result: DayResult) -> String {
        switch result {
        case .correct:
            return "Верно"
        case .wrong:
            return "Неверно"
        case .missed:
            return "Пропущено"
        }
    }

    private func historyStatus(_ challenge: DailyChallenge) -> String {
        if let result = challenge.result {
            return resultTitle(result)
        }
        if challenge.shownAt == nil {
            return "Не начато"
        }
        return "В процессе"
    }

    private func historySubtitle(challenge: DailyChallenge) -> String {
        if let answer = challenge.userAnswer {
            return "Ответ: \(answer)"
        }
        return "Длина числа: \(challenge.length)"
    }

    private func statusColor(_ challenge: DailyChallenge) -> Color {
        switch challenge.result {
        case .correct:
            return .green
        case .wrong:
            return .red
        case .missed:
            return .orange
        case nil:
            return .gray
        }
    }
}

private enum RootTab {
    case today
    case history
    case settings
}

private struct OnboardingConfig {
    let startTime: Date
    let endTime: Date
    let difficulty: ReminderDifficulty
}

private enum ReminderDifficulty: Int, CaseIterable, Identifiable {
    case easy = 0
    case normal = 1
    case hard = 2
    case intense = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy:
            return "Просто"
        case .normal:
            return "Средне"
        case .hard:
            return "Сложно"
        case .intense:
            return "Очень сложно"
        }
    }

    var reminderCount: Int {
        switch self {
        case .easy:
            return 5
        case .normal:
            return 4
        case .hard:
            return 3
        case .intense:
            return 1
        }
    }
}

private struct MorningRevealView: View {
    let number: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Число дня")
                    .font(.headline)

                Text(number)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("Запомни число. После закрытия экрана оно больше не будет показано сегодня.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Запомнил") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Утро")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct OnboardingView: View {
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var difficulty: ReminderDifficulty

    let onFinish: (OnboardingConfig) -> Void

    init(
        initialStartTime: Date,
        initialEndTime: Date,
        initialDifficulty: ReminderDifficulty,
        onFinish: @escaping (OnboardingConfig) -> Void
    ) {
        _startTime = State(initialValue: initialStartTime)
        _endTime = State(initialValue: initialEndTime)
        _difficulty = State(initialValue: initialDifficulty)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Как работает Cloak")
                    .font(.title2)
                    .fontWeight(.semibold)

                Label("Утром приложение показывает число", systemImage: "sun.max")
                Label("Днем напоминания помогают удерживать его в памяти", systemImage: "bell")
                Label("Вечером ты вводишь число и видишь результат", systemImage: "moon")

                GroupBox("Твои параметры") {
                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("Начало дня", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("Конец дня", selection: $endTime, displayedComponents: .hourAndMinute)
                        Picker("Частота дневных напоминаний", selection: $difficulty) {
                            ForEach(ReminderDifficulty.allCases) { level in
                                Text("\(level.title): \(level.reminderCount) раз(а) в день").tag(level)
                            }
                        }
                        Text("Чем чаще напоминания, тем проще удерживать число в памяти.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                Spacer()

                Button("Начать") {
                    onFinish(OnboardingConfig(startTime: startTime, endTime: endTime, difficulty: difficulty))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DailyChallenge.self], inMemory: true)
}
