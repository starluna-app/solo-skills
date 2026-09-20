# Paceful iCloud Sync Contract

Use this reference only for Paceful (`/Users/sl/Projects/time-ios`). Re-verify the repository and Apple APIs before implementation; this records product decisions, not proof of current framework behavior.

## Product scope

- Paceful remains local-first and fully functional without iCloud. iCloud is private Apple-account cloud persistence and eventual cross-device sync, not an app account, backend, or live-control service.
- Sync is automatic when iCloud is available. There is no Paceful login and no ordinary in-app sync toggle.
- First release includes a paired Apple Watch companion. Watch shows current/today state and triggers start, stop, and switch commands; it does not edit history or Ideal Days.

## Data policy

- Time entries are additive. Independent entries from different devices survive.
- Edits to the same record use the latest saved edit; delete versus edit resolves to deletion.
- Individual entry deletion keeps the existing short undo experience, with cloud deletion deferred until undo expires.
- Built-in activity types are application catalog data, not separately synchronized records. Future custom activities may be synchronized.
- Durable device-independent preferences to sync: onboarding completion and shared planning data. Theme, sound, haptics, reminder enablement, and Live Activity enablement remain device-local.

## Ideal Days

- Keep versioned Ideal Day templates. Only one is active at a time; older templates are retained for history/fallback.
- Expose prior templates as **Saved Rhythms** in the first release. People can name, activate, and delete them.
- Concurrent active-template selections resolve to the most recently saved selection. Both templates remain.

## Watch commands

- Use immediate WatchConnectivity requests when reachable.
- When disconnected, Watch records a unique durable command locally, renders a provisional state, and queues the command for ordered later delivery.
- iPhone canonicalizes and acknowledges commands; Watch reconciles to that acknowledgement. If competing offline timers exist, the later action closes the earlier one at its start time.
- A pending command remains until acknowledgement or explicit user discard; it never expires automatically.
- The first companion release requires watchOS 10 or later on a paired compatible Apple Watch.

## iCloud lifecycle and user-facing behavior

- Normal Settings status is quiet and trustworthy: iCloud Sync On, Restoring from iCloud, Unavailable (local data remains), or Needs Attention. Do not claim global completion/progress without evidence.
- A new device joins the same shared iCloud data set. Additive data may converge normally; Ideal Day versions avoid destructive merging.
- An Apple Account change is a privacy boundary: do not expose or sync the prior account's mirror under the new account.
- If a person removes Paceful's iCloud data through system iCloud Storage settings, do not silently re-upload. Make any renewed backup a clear explicit action.
- In-app **Delete all Paceful data** is global: it removes local data immediately and queues removal of private iCloud data and other connected devices when connectivity resumes. State this in the confirmation. Never use deletion/reset as sync repair.
- No dedicated "About iCloud Sync" screen is required. The app's accessible Privacy Policy must describe collection/storage, retention, and deletion.

## Release gate

1. Migrate and test real development stores plus two physical iPhones and a paired Watch against CloudKit Development.
2. Review the schema and get explicit user approval before deploying CloudKit Production schema.
3. TestFlight uses Production, so validate the actual TestFlight build there before any App Store submission claim.
