//
//  Item.swift
//  Cloak
//
//  Created by Кирилл Любарских on 17.04.2026.
//

import Foundation
import SwiftData

enum DayResult: String, CaseIterable, Codable {
    case correct
    case wrong
    case missed
}

enum DayStatus {
    case notRevealed
    case awaitingAnswer
    case completed
}

@Model
final class DailyChallenge {
    @Attribute(.unique) var dayStart: Date
    var value: String
    var length: Int
    var shownAt: Date?
    var answeredAt: Date?
    var userAnswer: String?
    var resultRaw: String?

    init(
        dayStart: Date,
        value: String,
        length: Int,
        shownAt: Date? = nil,
        answeredAt: Date? = nil,
        userAnswer: String? = nil,
        result: DayResult? = nil
    ) {
        self.dayStart = dayStart
        self.value = value
        self.length = length
        self.shownAt = shownAt
        self.answeredAt = answeredAt
        self.userAnswer = userAnswer
        self.resultRaw = result?.rawValue
    }

    var result: DayResult? {
        get {
            guard let resultRaw else { return nil }
            return DayResult(rawValue: resultRaw)
        }
        set {
            resultRaw = newValue?.rawValue
        }
    }
}

struct DayStats {
    let currentStreak: Int
    let bestStreak: Int
    let accuracyPercent: Int
    let totalAnswered: Int
}

struct DailyChallengeService {
    static func refreshCurrentDay(in modelContext: ModelContext, now: Date = .now, length: Int = 4) throws -> DailyChallenge {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)

        let markMissedDescriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate<DailyChallenge> { challenge in
                challenge.dayStart < todayStart && challenge.resultRaw == nil
            }
        )
        let staleChallenges = try modelContext.fetch(markMissedDescriptor)
        for challenge in staleChallenges {
            challenge.result = .missed
            challenge.answeredAt = now
        }

        let todayDescriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate<DailyChallenge> { challenge in
                challenge.dayStart == todayStart
            }
        )

        if let existing = try modelContext.fetch(todayDescriptor).first {
            try modelContext.save()
            return existing
        }

        let challenge = DailyChallenge(
            dayStart: todayStart,
            value: generateNumber(length: length),
            length: length
        )
        modelContext.insert(challenge)
        try modelContext.save()
        return challenge
    }

    static func dayStatus(for challenge: DailyChallenge) -> DayStatus {
        if challenge.result != nil {
            return .completed
        }
        if challenge.shownAt == nil {
            return .notRevealed
        }
        return .awaitingAnswer
    }

    static func computeStats(from challenges: [DailyChallenge]) -> DayStats {
        let sorted = challenges.sorted { $0.dayStart < $1.dayStart }

        let answered = sorted.filter { $0.result == .correct || $0.result == .wrong }
        let correctCount = answered.filter { $0.result == .correct }.count
        let accuracyPercent: Int
        if answered.isEmpty {
            accuracyPercent = 0
        } else {
            accuracyPercent = Int((Double(correctCount) / Double(answered.count) * 100.0).rounded())
        }

        var currentStreak = 0
        for challenge in sorted.reversed() {
            if challenge.result == .correct {
                currentStreak += 1
            } else {
                break
            }
        }

        var bestStreak = 0
        var runningStreak = 0
        for challenge in sorted {
            if challenge.result == .correct {
                runningStreak += 1
                bestStreak = max(bestStreak, runningStreak)
            } else {
                runningStreak = 0
            }
        }

        return DayStats(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            accuracyPercent: accuracyPercent,
            totalAnswered: answered.count
        )
    }

    static func applyPreferredLengthToUnstartedCurrentDay(
        in modelContext: ModelContext,
        length: Int,
        now: Date = .now
    ) throws {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let todayDescriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate<DailyChallenge> { challenge in
                challenge.dayStart == todayStart
            }
        )

        guard let challenge = try modelContext.fetch(todayDescriptor).first else {
            return
        }

        let isUnstarted = challenge.shownAt == nil && challenge.resultRaw == nil
        guard isUnstarted, challenge.length != length else {
            return
        }

        challenge.length = length
        challenge.value = generateNumber(length: length)
        challenge.userAnswer = nil
        challenge.answeredAt = nil

        try modelContext.save()
    }

    private static func generateNumber(length: Int) -> String {
        (0..<length)
            .map { _ in String(Int.random(in: 0...9)) }
            .joined()
    }
}
