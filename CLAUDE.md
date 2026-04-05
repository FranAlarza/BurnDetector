# Asado

macOS menu bar app that monitors CPU usage and plays a scream sound when it exceeds a configurable threshold (default 90%). Includes a settings window for configuration.

## Tech Stack

- **UI:** SwiftUI
- **Min deployment:** macOS 14+
- **Architecture:** MVVM
- **Concurrency:** Swift async/await only — no Combine, no completion handlers
- **Persistence:** UserDefaults (threshold, sound enabled, etc.)
- **Audio:** AVFoundation with bundled .mp3/.wav file
- **No SwiftData** — remove template code

## Project Structure

```
Asado/
├── AsadoApp.swift          # App entry point
├── App/                    # Transversal elements shared across features
│   ├── Models/
│   ├── Views/              # MenuBarView, MenuBarViewModel, Components/
│   └── Services/
├── Features/               # One subfolder per feature
│   ├── CPU/
│   │   ├── Models/         # TopProcess
│   │   ├── Views/          # Feature-specific views and ViewModels
│   │   └── Services/       # CPUMonitoringService, ProcessMonitoringService
│   ├── Disk/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── Services/       # DiskMonitoringService
│   └── Settings/
│       ├── Models/         # AppSettings, SoundOption
│       ├── Views/          # SettingsView
│       └── Services/       # AudioPlayerService, CustomSoundStorageService
└── Resources/              # Assets.xcassets, .mp3 files
```

## Architecture

- **MVVM** — Views bind to ViewModels, ViewModels use Services
- **ViewModels live inside `Views/`** within their feature folder
- Services are **protocol-based** for testability
- ViewModels use `@Observable` (Observation framework)
- No business logic in Views

### Adding a new feature

Every new feature gets its own folder under `Features/<FeatureName>/` with three subfolders:
- `Models/` — data structs for that feature
- `Views/` — SwiftUI views **and** the `@Observable` ViewModel
- `Services/` — protocol + implementation, one file per service

Elements shared across multiple features go in `App/` under the same three subfolders.

## Build & Run

```bash
# Build
xcodebuild -scheme Asado -configuration Debug build

# Run tests
xcodebuild -scheme Asado -only-testing AsadoTests test
```

## Code Conventions

- **Language:** English for all code, comments, and commits
- **Naming:** Follow Swift API Design Guidelines
- **No force unwraps** (`!`) in production code
- Use `// MARK: -` to organize code sections
- Prefer `guard` for early exits
- Use `async/await` for all asynchronous work

## Testing

- **Framework:** Swift Testing (`@Test`, `#expect`) — not XCTest
- **Test naming:** `{ClassName}Tests.swift`
- Mock services via protocols
- Test ViewModels independently from Views

## Spec Driven Development

Every new feature MUST follow this flow before writing any code:

1. **`/spec-requirements <feature-name>`** — Generates `docs/specs/<feature-name>/requirements.md`. Wait for approval.
2. **`/spec-design <feature-name>`** — Generates `docs/specs/<feature-name>/design.md`. Wait for approval.
3. **`/spec-tasks <feature-name>`** — Generates `docs/specs/<feature-name>/tasks.md`. Wait for approval.
4. **`/spec-implement <feature-name>`** — Implements tasks one by one with atomic commits.

Template: `docs/specs/000-template.md`
No code is written until steps 1-3 are approved.
