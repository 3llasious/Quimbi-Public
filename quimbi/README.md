# Quimbi

A Flutter task manager app with a local SQLite database.

---

## 1. Running the project

```bash
flutter run -d chrome
```

The app targets Chrome for development. Make sure Flutter is installed and `flutter doctor` reports no critical issues before running.

---

## 2. Database schema

The local SQLite database (`quimbi.db`) is set up in `lib/db/database_setup.dart`. Tables are created in dependency order so foreign keys are always satisfied.

### `locations`
Reusable places that can be attached to a task.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `label` | TEXT | display name, e.g. "Supermarket" |
| `address` | TEXT | optional street address |
| `latitude` | REAL | optional GPS coordinate |
| `longitude` | REAL | optional GPS coordinate |

---

### `people`
Contacts that can be associated with a task.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `name` | TEXT | required |
| `phone` | TEXT | optional phone number |
| `contact_id` | TEXT | optional — links to a device contact |

---

### `tasks`
The core table. Every other table hangs off this one.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `title` | TEXT | required |
| `time_sensitive` | INTEGER | `0` = false, `1` = true |
| `due_time` | TEXT | ISO datetime string, nullable |
| `completed` | INTEGER | `0` = false, `1` = true |
| `created_at` | TEXT | defaults to `datetime('now')` |
| `location_id` | INTEGER FK | references `locations(id)`, nullable, `SET NULL` on delete |

---

### `task_people` (junction table)
Links tasks to people — many-to-many.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `task_id` | INTEGER FK | references `tasks(id)`, `CASCADE` on delete |
| `person_id` | INTEGER FK | references `people(id)`, `CASCADE` on delete |

---

### `subtasks`
Checklist items nested under a task.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `task_id` | INTEGER FK | references `tasks(id)`, `CASCADE` on delete |
| `title` | TEXT | required |
| `completed` | INTEGER | `0` = false, `1` = true |
| `position` | INTEGER | display order |

---

### `alerts`
Scheduled reminders for a task.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `task_id` | INTEGER FK | references `tasks(id)`, `CASCADE` on delete |
| `alert_time` | TEXT | ISO datetime string |
| `alert_type` | TEXT | e.g. `"notification"`, `"phone_alarm"`, `"imessage"` |
| `is_active` | INTEGER | `1` = active, `0` = dismissed |

---

### `links`
URLs attached to a task.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `task_id` | INTEGER FK | references `tasks(id)`, `CASCADE` on delete |
| `label` | TEXT | display label, e.g. "notes" |
| `url` | TEXT | the full URL |

---

### `recurrence_patterns`
How and when a task repeats. One row per task.

| column | type | notes |
|---|---|---|
| `id` | INTEGER PK | autoincrement |
| `task_id` | INTEGER FK | references `tasks(id)`, `CASCADE` on delete |
| `recurrence_type` | TEXT | e.g. `"daily"`, `"weekly"`, `"monthly"` |
| `weekdays` | TEXT | comma-separated day names for weekly recurrence |
| `day_of_month` | INTEGER | e.g. `1` for the 1st of each month |
| `interval_count` | INTEGER | e.g. `2` means every 2 weeks |
| `starts_on` | TEXT | ISO date string |
| `ends_on` | TEXT | ISO date string, nullable |

---

## 3. Architecture and data flow

The app is split into four layers. Data moves down to the database and back up through the same layers in the opposite direction.

```
widget  (UI layer)
  │  renders List<TaskModel>, dispatches user actions
  ▼
task_manager  (logic layer)
  │  handles business logic — decides what to fetch, when to mutate
  ▼
task_repository  (data layer)
  │  builds SQL queries, talks to the database
  ▼
database_helper  (connection layer)
  │  opens / initialises the SQLite connection (singleton)
  ▼
  SQLite (quimbi.db)
```

On the way back up:

```
  SQLite returns raw rows  (List<Map<String, dynamic>>)
  ▲
task_repository  groups rows, handles JOIN fan-out, calls fromMap()
  ▲
models  (shape layer)
  │  SubtaskModel, AlertModel, RecurrenceModel, LinkModel,
  │  LocationModel, PersonModel — define what the data looks like
  │  fromMap() converts SQLite integers/strings into typed Dart fields
  │  e.g. completed: 0  →  isCompleted: false
  ▲
task_manager  receives List<TaskModel>, applies any extra logic
  ▲
widget  receives List<TaskModel> and renders
```

### File locations

| layer | file |
|---|---|
| UI — screens | `lib/screens/` |
| UI — widgets | `lib/widgets/` |
| Logic | `lib/logic/task_manager.dart` |
| Data | `lib/repositories/task_repository.dart` |
| Models | `lib/models/` |
| DB connection | `lib/db/database_setup.dart` |
| DB seed data | `lib/db/data/` |
| DB seeder | `lib/db/seed.dart` |
