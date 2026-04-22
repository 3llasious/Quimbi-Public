import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'data/tasks.dart';
import 'data/subtasks.dart';
import 'data/alerts_data.dart';
import 'data/links_data.dart';
import 'data/locations_data.dart';
import 'data/people_data.dart';
import 'data/task_people_data.dart';
import 'data/recurrence_patterns_data.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  static Future<Database>? _initFuture;

  Future<Database> get database async {
    _db ??= await (_initFuture ??= _initDatabase());
    return _db!;
  }

// intialising the db
  Future<Database> _initDatabase() async {
    debugPrint('[DB] _initDatabase start');
    final String databasePath;
    if (kIsWeb) {
      databasePath = '/';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      databasePath = dir.path;
    }
    final fullPath = join(databasePath, 'quimbi.db');
    debugPrint('[DB] opening database at $fullPath');

    final db = await openDatabase(
      fullPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createTaskCompletionsTable(db);
      },
    );
    debugPrint('[DB] database opened successfully');
    return db;
  }

  Future<void> _seedLoggedInUser(Database db) async {
    await db.insert('loggedInUser', {
      'name': 'Emmanuella Itopa',
      'gender': 'Female',
      'phone': '07700000000',
      'date_of_birth': '1990-01-01',
    });
  }

  Future<void> _createTables(Database db, int version) async {
    debugPrint('[DB] _createTables start');
    await db.execute('''
      CREATE TABLE loggedInUser (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL,
        gender        TEXT,
        phone         TEXT,
        date_of_birth TEXT
      )
    ''');
    debugPrint('[DB] loggedInUser table created');
    await _seedLoggedInUser(db);
    debugPrint('[DB] loggedInUser seeded');

  await db.execute('''
    CREATE TABLE locations (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      label      TEXT NOT NULL,
      address    TEXT,
      latitude   REAL,
      longitude  REAL
    )
  ''');
  debugPrint('[DB] locations table created');

    await db.execute('''
   CREATE TABLE people (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  phone        TEXT,
  contact_id   TEXT
)
  ''');
  debugPrint('[DB] people table created');

    await db.execute('''
     CREATE TABLE tasks (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  title          TEXT NOT NULL,
  time_sensitive INTEGER DEFAULT 0,
  due_time       TEXT,
  completed      INTEGER DEFAULT 0,
  created_at     TEXT DEFAULT (datetime('now')),
  location_id    INTEGER REFERENCES locations(id) ON DELETE SET NULL
)
    ''');
  debugPrint('[DB] tasks table created');

await db.execute('''
  CREATE TABLE task_people (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id    INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    person_id  INTEGER NOT NULL REFERENCES people(id) ON DELETE CASCADE
  )
''');
  debugPrint('[DB] task_people table created');

    await db.execute('''
      CREATE TABLE subtasks (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id     INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        title       TEXT NOT NULL,
        completed   INTEGER DEFAULT 0,
        position    INTEGER
      )
    ''');
  debugPrint('[DB] subtasks table created');

    await db.execute('''
CREATE TABLE alerts (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id      INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  alert_time   TEXT NOT NULL,
  alert_type   TEXT NOT NULL,
  is_active    INTEGER DEFAULT 1
)

   ''' );
  debugPrint('[DB] alerts table created');

    await db.execute('''
      CREATE TABLE links (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id  INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        label    TEXT NOT NULL,
        url      TEXT NOT NULL
      )
    ''');
  debugPrint('[DB] links table created');

    await db.execute('''
      CREATE TABLE recurrence_patterns (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id          INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        recurrence_type  TEXT NOT NULL,
        weekdays         TEXT,
        day_of_month     INTEGER,
        interval_count   INTEGER,
        starts_on        TEXT,
        ends_on          TEXT
      )
    ''');

    await _createTaskCompletionsTable(db);

    debugPrint('[DB] all tables created, seeding data...');
    await _seedData(db);
    debugPrint('[DB] _createTables complete');
  }

  Future<void> _createTaskCompletionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_completions (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id   INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        done_date TEXT NOT NULL,
        UNIQUE(task_id, done_date)
      )
    ''');
    debugPrint('[DB] task_completions table created');
  }

  Future<void> _seedData(Database db) async {
    for (final row in testLocations) { await db.insert('locations', row); }
    for (final row in testPeople) { await db.insert('people', row); }
    for (final row in testTasks) { await db.insert('tasks', row); }
    for (final row in testSubtasks) { await db.insert('subtasks', row); }
    for (final row in testAlerts) { await db.insert('alerts', row); }
    for (final row in testLinks) { await db.insert('links', row); }
    for (final row in testTaskPeople) { await db.insert('task_people', row); }
    for (final row in testRecurrencePatterns) { await db.insert('recurrence_patterns', row); }
  }
}
