# Cloak — Tasks (MVP)

## 1. Статус проекта
Дата обновления: 22 апреля 2026

- `P0`: в основном реализован.
- `P1`: частично реализован.
- `P2`: не начат.

## 2. P0 — Core MVP

## T-001 App state and day lifecycle
- Status: `Done`
- Notes: реализованы статусы дня и обновление состояния на новый день.

## T-002 DailyChallenge model + persistence
- Status: `Done`
- Notes: модель `DailyChallenge` на SwiftData, данные сохраняются между запусками.

## T-003 Number generation service
- Status: `Done`
- Notes: число стабильно в течение дня, создается новое на следующий день.

## T-004 Home / Today screen
- Status: `Done`
- Notes: экран показывает статус дня и соответствующий CTA.

## T-005 Morning number flow
- Status: `Done`
- Notes: утренний показ числа с подтверждением, повторный показ отключен.

## T-006 Evening answer flow
- Status: `Done`
- Notes: проверка ответа, запись `correct/wrong`.
- Extra: ввод скрыт до времени вечерней проверки.

## T-007 History screen
- Status: `Done`
- Notes: список дней с результатами (`correct/wrong/missed`).

## T-008 Basic stats
- Status: `Done`
- Notes: `currentStreak`, `bestStreak`, `accuracy`, `totalAnswered`.

## T-009 Notification permission + scheduling
- Status: `Done`
- Notes: запрос разрешения в первом запуске, расписание создается автоматически.

## T-010 Daytime reminders count
- Status: `Done`
- Notes: частота дневных напоминаний настраивается.
- Current range: `1...5`.

## T-011 Settings screen (MVP)
- Status: `Done`
- Notes: время начала/конца дня, количество дневных напоминаний, напоминание за N минут до полуночи, длина числа, статус уведомлений.

## T-012 Missed day handling
- Status: `Done`
- Notes: незавершенные прошлые дни получают `missed`.

## 3. Дополнительная задача (вне исходного P0)

## T-020 Number length setting
- Status: `Done`
- Notes:
  - добавлена настройка длины числа (`3...8`, default `4`);
  - применяется к ближайшему не начатому периоду.

## T-021 Reminder before midnight
- Status: `Done`
- Notes:
  - добавлена настройка напоминания за N минут до полуночи (`5...180`);
  - локальное уведомление планируется ежедневно в `24:00 - N`.

## 4. P1 — Release Quality

## T-013 Minimal onboarding
- Status: `Done`
- Notes: onboarding включает объяснение механики и начальные настройки расписания/частоты.

## T-014 Empty and error states
- Status: `Partially done`
- Notes: часть сообщений и пустых состояний реализована, требуется финальная полировка.

## T-015 Timezone and date edge cases
- Status: `In progress`
- Notes: базовая логика есть, нужен целевой QA и доработка крайних сценариев.

## T-016 Manual QA scenario pass
- Status: `Pending`
- Notes: полный ручной прогон по чеклисту не зафиксирован.

## 5. P2 — Post-MVP
- `T-017 Adaptive difficulty`: `Pending`
- `T-018 Extended analytics`: `Pending`
- `T-019 Word mode research spike`: `Pending`

## 6. Next steps
1. Закрыть `T-015` через QA-кейсы времени/полуночи/таймзоны.
2. Провести `T-016` и зафиксировать результаты.
3. Дополировать `T-014` по UX-текстам и пустым состояниям.
