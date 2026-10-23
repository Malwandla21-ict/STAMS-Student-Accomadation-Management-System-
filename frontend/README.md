# STAMS — Flutter app

Material 3 app for landlords and students, built from the STAMS design handoff
(Roofline brand, 390×844 screens A1–A6, L1–L10, S1–S6d).

## Run it

```bash
flutter pub get

# Real backend (Spring Boot on :8081, start it first). The app finds it at
# 10.0.2.2:8081 on the Android emulator and localhost:8081 in Chrome/desktop.
flutter run
flutter run -d chrome

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

Outside demo mode everything comes from the Spring API, and every account only sees its own data:

| Screen | Endpoint |
| --- | --- |
| Sign in / sign up / session | `/api/auth/*`, `GET /api/me` |
| Properties, rooms, assign/remove students, student search | `/api/properties`, `/api/rooms`, `/api/students/search` |
| Issue inbox (landlord) / My issues (student) | `GET /api/issues` — the token decides which |
| Issue detail + timeline | `GET /api/issues/{id}` |
| Report an issue (photos first via `POST /api/uploads`) | `POST /api/issues` |
| Update status / priority / note | `PATCH /api/issues/{id}` |
| Nudge (once per 24h, open issues only) | `POST /api/issues/{id}/nudge` |
| Room detail issues | `GET /api/rooms/{id}/issues` |
| Alerts | `GET /api/notifications`, `POST /api/notifications/{id}/read`, `POST /api/notifications/read-all` |
| Student's room + shared spaces | `GET /api/me/room` (204 until they're assigned) |

## Progress & celebrations

- **Landlord setup checklist** on the dashboard (property → rooms → student → first report), hidden once done.
- **Student tracker** "Reported → Seen → Fixing → Fixed" on cards and the issue page, plus a "getting set up" checklist while they wait for a room.
- **Celebrations** (`lib/widgets/celebration.dart`) after adding a property or room, assigning a student, reporting, and resolving — each suggests the next step. Confetti is skipped when the device asks for reduced motion.

## Code map

```
lib/
  theme/        ColorScheme, Archivo text theme, StatusColors / PriorityColors extensions, spacing
  models/       User, Property, Room, Issue (+ events, filter), notifications — mirror the backend DTOs
  data/         Dio client, JWT storage, repository interfaces + API impls, demo/ in-memory store
  providers/    Riverpod: auth, repositories, lists, mutations (AppActions), report draft
  widgets/      Design-system components: StatusChip, PriorityBadge, NudgePill, IssueCard, progress
                (checklist, issue tracker), celebration,
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
