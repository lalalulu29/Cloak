# Cloak

<p align="center">
  Daily memory training for iOS: <b>morning number -> daytime recall -> evening check</b>.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS-0A84FF">
  <img alt="Language" src="https://img.shields.io/badge/language-Swift-F05138">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-34C759">
  <img alt="Storage" src="https://img.shields.io/badge/storage-SwiftData-5AC8FA">
  <img alt="Status" src="https://img.shields.io/badge/status-MVP%20in%20progress-F59E0B">
</p>

## Overview

**Cloak** is a simple iOS app for training working memory through a daily ritual:

1. In the morning, you see one number.
2. During the day, reminders help you keep it in memory.
3. In the evening, you enter the number from memory.
4. The app stores your result and tracks progress.

The idea comes from a real-life habit: remembering your cloakroom number.

## Current MVP Features

- Daily challenge with one number per local day.
- Morning reveal flow (number is not shown again after confirmation).
- Evening check flow with time gating.
- Result states: `correct`, `wrong`, `missed`.
- History screen with daily outcomes.
- Basic stats: current streak, best streak, accuracy, total answers.
- Onboarding (first launch):
  - start of day,
  - end of day,
  - daytime reminder frequency.
- Local notifications:
  - morning,
  - daytime reminders,
  - evening,
  - reminder before midnight (configurable in minutes).
- Settings:
  - notification status,
  - start/end of day,
  - reminder count (`1...5`),
  - reminder time before midnight (`5...180` minutes),
  - number length (`3...8`, default `4`).

## Product Rules

- `1` daytime reminder = harder mode.
- `5` daytime reminders = easier mode.
- Number length updates apply to the **nearest unstarted period**.
- Evening input is hidden until evening check time.

## Tech Stack

- `SwiftUI` for UI.
- `SwiftData` for local persistence.
- `UserNotifications` for scheduling reminders.
- `AppStorage` for lightweight user settings.

## Project Structure

```text
Cloak/
├─ Cloak/
│  ├─ CloakApp.swift
│  ├─ ContentView.swift
│  ├─ Item.swift
│  └─ NotificationScheduler.swift
├─ Docs/
│  ├─ PRODUCT_VISION.md
│  ├─ MVP_IMPLEMENTATION_PLAN.md
│  ├─ PRD_CHECKLIST.md
│  └─ TASKS.md
└─ README.md
```

## Getting Started

### Requirements

- Xcode 16+
- iOS 17+

### Run

1. Open `Cloak.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Build and run (`Cmd + R`).
4. Allow notifications on first launch.

## Roadmap

- [x] Core daily loop.
- [x] Notifications and history.
- [x] Basic stats.
- [x] First-launch onboarding.
- [ ] Timezone and midnight edge-case hardening.
- [ ] Full manual QA pass.
- [ ] Adaptive number length.
- [ ] Word mode (post-MVP).
- [ ] iCloud sync (post-MVP).

## Documentation

Detailed planning and status docs are available in [`Docs/`](Docs):

- [`Docs/PRODUCT_VISION.md`](Docs/PRODUCT_VISION.md)
- [`Docs/MVP_IMPLEMENTATION_PLAN.md`](Docs/MVP_IMPLEMENTATION_PLAN.md)
- [`Docs/PRD_CHECKLIST.md`](Docs/PRD_CHECKLIST.md)
- [`Docs/TASKS.md`](Docs/TASKS.md)

## License

No license file yet.
If this project goes public, add a license (for example, MIT).
