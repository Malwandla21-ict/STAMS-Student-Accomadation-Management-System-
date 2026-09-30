# STAMS — Flutter app

Material 3 app for landlords and students, built from the STAMS design handoff
(Roofline brand, 390×844 screens A1–A6, L1–L10, S1–S6d).

## Run it

```bash
flutter pub get

# Real backend (Spring Boot on :8081) from the Android emulator
flutter run

# No backend at all - every screen runs on seeded demo data
flutter run --dart-define=STAMS_DEMO=true

# Backend somewhere else (e.g. a phone on your Wi-Fi)
flutter run --dart-define=STAMS_API_URL=http://192.168.1.20:8081
```

Building the Windows desktop target needs **Developer Mode** turned on
(Settings → System → For developers) so Flutter can create plugin symlinks.
Android and web builds work without it.

### Demo accounts (`STAMS_DEMO=true`)

All seeded accounts use the password `stams-demo`. The sign-in screen also has one-tap buttons.

| Who | Email | Shows |
| --- | --- | --- |
| Tom Hadley (landlord) | tom.hadley@hadleylets.co.uk | Dashboard, 4 properties, nudged issues |
| Aisha Bello (student) | aisha.bello@uni.ac.uk | Room 2 at Parkview, open issues, nudge button |
| Maya Thomas (student) | maya.thomas@uni.ac.uk | Not in a room yet (S1u) — assign her from Tom's L10 |

Demo data lives in memory and resets when the app restarts. Nudges alert the landlord and
status changes alert the student, so the whole nudge loop can be tried by switching accounts.

## What talks to the backend

| Feature | Source |
| --- | --- |
| Sign in / sign up / session (`/api/auth/*`, `/api/me`) | Spring API |
| Properties, rooms, assign/remove students, student search | Spring API |
| Issues, nudges, timeline, alerts, the student's own room | **Demo store** — no endpoints yet |

Until those endpoints exist, API mode shows the demo issues as landlord Tom or student Aisha.
Each one is behind an interface in `lib/data/repositories.dart` (`IssueRepository`,
`NotificationRepository`, `StudentHomeRepository`); add an `Api…` implementation and switch
the provider in `lib/providers/repositories.dart`. Endpoints the screens expect:

- `GET /api/issues` (landlord inbox), `GET /api/me/issues` (student), `GET /api/issues/{id}` with events
- `POST /api/issues` (title, description, roomId, photos), `PATCH /api/issues/{id}` (status, priority, note)
- `POST /api/issues/{id}/nudge` — 24h cooldown, open issues only
- `GET /api/notifications`, `POST /api/notifications/{id}/read`, `POST /api/notifications/read-all`
- `GET /api/me/room` — the student's room, roommates, landlord and the property's communal rooms

## Code map

```
lib/
  theme/        ColorScheme, Archivo text theme, StatusColors / PriorityColors extensions, spacing
  models/       User, Property, Room, Issue (+ events, filter), notifications — mirror the backend DTOs
  data/         Dio client, JWT storage, repository interfaces + API impls, demo/ in-memory store
  providers/    Riverpod: auth, repositories, lists, mutations (AppActions), report draft
  widgets/      Design-system components: StatusChip, PriorityBadge, NudgePill, IssueCard,
                RoomCard, NudgeButton, StatusTimeline, list states, StamsMark/Wordmark
  features/     auth/ (A1–A3), landlord/ (L1–L10), student/ (S1–S6), shared/ (alerts, profile, nav shell)
  router.dart   go_router with role-based redirects and a bottom-nav shell per role
```

Brand assets are in `stams-1c-roofline/`; the Android launcher icon and launch screen are
vector versions of the Roofline mark.

## Tests

```bash
flutter analyze
flutter test
```
