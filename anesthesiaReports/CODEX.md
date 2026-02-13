# CODEX

## Project overview and purpose
AnesthesiaReports is an iOS app for anesthesiologists to manage the full perioperative flow: patients, surgeries, anesthesia, SRPA (recovery), and pre‑anesthesia assessments. It focuses on reliable data capture, permissioning, and consistent workflows between backend and mobile.

## Key architecture decisions
- **SwiftUI-first UI**: Fast iteration, consistent layout, and native form patterns.
- **Session-based state**: Each domain (Auth, Patient, Surgery, Anesthesia, PreAnesthesia, SRPA, Financial) has its own session/service to keep side effects contained and state predictable.
- **DTO boundary**: Network payloads map to DTOs to keep the UI and domain logic decoupled from backend shapes.
- **Wizard flows**: Multi-step creation flows (patient → surgery → anesthesia/SRPA/pre‑anesthesia) reduce user friction and enforce order.

## Important conventions and patterns used
- **Swift Concurrency**: async/await for network calls.
- **Dependency injection**: sessions/services receive API clients and AuthSession for testability.
- **Validation UX**: show errors only after a field is touched or on submit.
- **SendView patterns**: consistent submit states (idle, submitting, success, failure), cooldowns, and color feedback.
- **EnvironmentObject sessions**: sessions injected at root and passed down to views.

## Build/run instructions
- Open the Xcode project/workspace and run the iOS target.
- Backend base URL is configured in the API layer (see `Auth/HealthAPI.swift` and other API files).

## Quirks / gotchas
- Timezone handling is sensitive: always pass/parse ISO‑8601 from backend; avoid local time assumptions.
- Many views have wizard vs standalone modes; ensure the correct mode is used when embedding.
- Some flows expect shared_pre_anesthesia lookup data; handle 404 gracefully (create on demand).
- When adding new send actions, follow `Documentation/SendViewTypeRecomendations.md`.

## Journal
See `Journal.md` in the project root.
