# STAMS — Student Accommodation Management System

A portfolio project: a platform where landlords manage their student accommodation — properties,
rooms and the students living in them — and students report maintenance issues (with photos) that
landlords track through to resolution. Students can **nudge** a landlord about an issue that has
stalled, and both sides get notified as an issue moves from Reported → Acknowledged → In Progress →
Resolved.

## Tech stack

| Layer      | Choice                          |
|------------|----------------------------------|
| Frontend   | Flutter / Dart (cross-platform mobile) |
| Backend    | Java 21 / Spring Boot            |
| Database   | PostgreSQL                       |
| Auth       | Spring Security + JWT            |
| ORM        | Spring Data JPA / Hibernate      |
| API        | REST / JSON                      |
| API testing| Postman                          |
| CI/CD      | GitHub Actions *(Phase 3)*       |
| Deployment | Docker + docker-compose, Railway/Render *(Phase 3)* |

## Project layout

```
STAMS/
├── backend/      Spring Boot REST API
├── frontend/     Flutter mobile app
└── README.md
```

## Roadmap

- **Phase 1** — Core CRUD functionality and end-to-end authentication working
- **Phase 2** — Professional polish: Swagger/OpenAPI docs, unit tests, polished README
- **Phase 3** — Deployment: Docker + docker-compose, GitHub Actions CI/CD, live hosting

## Getting started (backend)

Prerequisites: JDK 21, PostgreSQL running locally with an empty database called `stams_db`.

1. Copy `backend/.env.example` to `backend/.env` and fill in your local PostgreSQL password and a
   long random `JWT_SECRET`. `.env` is git-ignored.
2. Open the `backend/` folder in IntelliJ (it's a Maven project) and run `StamsBackendApplication`.

The API starts on `http://localhost:8081`. Hibernate creates the tables on first run.

## API so far

All endpoints except sign-up and sign-in need `Authorization: Bearer <token>`. Errors always come back as
JSON with a `message` (and `fieldErrors` for invalid forms).

| Method | Endpoint | Who | What |
|---|---|---|---|
| POST | `/api/auth/register` | anyone | Create a landlord or student account, returns a token |
| POST | `/api/auth/login` | anyone | Sign in, returns a token |
| GET | `/api/me` | signed in | The current account |
| GET / POST | `/api/properties` | landlord | List my properties (with bed, issue and nudge counts) / add one |
| GET / PUT / DELETE | `/api/properties/{id}` | landlord | Property detail with rooms / edit / delete |
| GET / POST | `/api/properties/{id}/rooms` | landlord | Rooms in a property / add a room |
| GET / PUT / DELETE | `/api/rooms/{id}` | landlord | Room detail with students / edit / delete |
| POST | `/api/rooms/{id}/students` | landlord | Assign (or move) a student into a room |
| DELETE | `/api/rooms/{id}/students/{studentId}` | landlord | Remove a student from a room |
| GET | `/api/students/search?email=` | landlord | Find registered students by email |
| GET | `/api/me/room` | student | My room, roommates, landlord and shared spaces (204 until assigned) |
| GET | `/api/issues` | signed in | Landlord: every issue in my properties. Student: issues I reported |
| GET | `/api/issues/{id}` | owner / reporter | Issue detail with its timeline |
| POST | `/api/issues` | student | Report an issue in my room or a shared space (up to 3 photo URLs) |
| PATCH | `/api/issues/{id}` | landlord | Move the status forward, set priority, leave a note (notifies the student) |
| POST | `/api/issues/{id}/nudge` | student | Nudge the landlord - once per 24h, open issues only |
| GET | `/api/rooms/{id}/issues` | landlord | Issues in one room |
| GET | `/api/notifications` | signed in | My alerts |
| POST | `/api/notifications/{id}/read`, `/api/notifications/read-all` | signed in | Mark alerts read |
| POST / GET | `/api/uploads`, `/api/uploads/{name}` | student / anyone | Upload an issue photo (max 5 MB) / fetch it |

A ready-made Postman collection is in `backend/postman/STAMS.postman_collection.json`.

## Getting started (frontend)

```bash
cd frontend
flutter pub get
flutter run
```
