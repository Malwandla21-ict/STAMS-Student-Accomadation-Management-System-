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

## Getting started (frontend)

```bash
cd frontend
flutter pub get
flutter run
```
