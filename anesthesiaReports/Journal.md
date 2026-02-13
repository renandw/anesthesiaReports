# Journal.md (Learning Journal)

## The Big Picture
Imagine a coffee with a friend who’s an anesthesiologist. They say, “I just want a smooth way to log patients, surgeries, anesthesia, SRPA, and pre‑anesthesia without jumping through a thousand hoops.” That’s this app. It’s a calm, guided workflow that turns real‑world chaos into structured, shareable data — with good UX and strong permissions.

## Architecture Deep Dive
Think of the app like a restaurant:
- **Sessions = Head chefs**. Each domain (Auth, Patient, Surgery, Anesthesia, PreAnesthesia, SRPA, Financial) has a session that coordinates the work.
- **APIs = Ingredient suppliers**. They deliver raw JSON.
- **DTOs = Prep cooks**. They clean and portion the ingredients so the UI can cook.
- **Views = The dining room**. They present the finished plate to the user, ideally without the kitchen drama showing.

The flow is: UI asks Session → Session calls API → API returns DTO → Session updates state → UI refreshes.

## The Codebase Map
- `Auth/` → login, health, tokens, session state
- `Patient/`, `Surgery/`, `Anesthesia/`, `PreAnesthesia/` → feature modules
- `Surgery/Financial/`, `Surgery/SharedPreAnesthesia/` → subdomains
- `DTO/` → network contracts
- `Helper/` → formatting, pickers, utility helpers
- `Documentation/` → API/UX references and decisions
- `Startup/` → health checks & boot flow
- `User/` → user profile and account management

## Tech Stack & Why
- **SwiftUI**: fast iteration, native UI, and consistent form patterns.
- **Swift Concurrency (async/await)**: clean asynchronous code; fewer callback pyramids.
- **DTO boundaries**: decouple backend JSON from UI types (future‑proofing).
- **Session pattern**: keeps side effects contained and makes UI predictable.

## The Journey
### War Stories (Bugs & Fixes)
- **Timezone gremlins**: anesthesia timestamps shifted after save. Root cause was mixed timezone handling between client and backend. Fix: consistent ISO‑8601 usage and careful date parsing.
- **“Invalid payload” mystery**: payloads looked correct but backend rejected them. Culprit was sending optional end times on create. Solution: align create/patch payloads to backend expectations.
- **Shared pre‑anesthesia data mismatch**: ASA/techniques weren’t showing in SRPA/pre‑anesthesia because we relied on direct anesthesia endpoints. Fix: introduce a shared_pre_anesthesia lookup and reuse it across flows.

### Aha! Moments
- A single shared_pre_anesthesia model simplifies ASA + technique handling across pre‑anesthesia, anesthesia, and SRPA.
- Wizards dramatically reduce UX errors by enforcing order (patient → surgery → anesthesia/SRPA/pre‑anesthesia).

### Pitfalls
- **“Looks optional” fields**: UI must match backend requirements or payloads will fail.
- **Over‑eager validation**: showing errors before a user touches a field leads to rage‑clicks.
- **State leaks**: passing state without scoping (or failing to inject EnvironmentObjects) causes crashes.

## Engineer’s Wisdom
- **Make the happy path stupid‑easy**: wizards and clear submit feedback.
- **Don’t trust timezones**: always normalize dates; logs are your friends.
- **Design for graceful 404s**: missing lookup data isn’t an error; create on demand.
- **Consistency beats cleverness**: reuse SendView patterns and validation rules everywhere.

## If I Were Starting Over...
- I’d formalize a “status helper” early to avoid status spaghetti in surgery/anesthesia/pre‑anesthesia/SRPA.
- I’d add a tiny integration test suite for date/time handling from day one.
- I’d enforce payload schemas across iOS and backend with a shared spec.

## The Journey (Running Log)
- **2026‑02‑09**: Consolidated pre‑anesthesia clearance into the pre‑anesthesia endpoint (removed dedicated clearance route). Simplified mobile flow and reduced sync bugs.
- **2026‑02‑09**: Added PreAnesthesia wizard and detail view; aligned UI with shared_pre_anesthesia lookup.
- **2026‑02‑09**: Standardized submit feedback states and cooldowns in user profile view.

## Next Steps
- **Preanesthesia comorbities section**: cardiovascular, endocrinal, neurological, oncological, nephrological, hematological (and related categories).
- **Medications**: current meds and peri‑op adjustments.
- **Allergies**: documented allergies and prior reactions.
- **Physical exam**: basic exam summary (e.g., vitals/inspection as needed).
- **Airway evaluation**: structured airway assessment block.
- **Labs & imaging**: attach or summarize relevant exams.
- **Surgery history**: past surgeries and complications.
- **Anesthesia history**: prior anesthesia events, issues, reactions.
- **Special populations**: infant and pregnancy flows.
- **Environment**: drugs, alcohol, sedentarism, pollution.
- **NVPO**: post‑op nausea/vomiting risk and notes.
