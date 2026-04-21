class DatabaseHelper {
// all instances of this share the SAME _db
//static — where it lives (on the class, shared) static but not final, so it's shared but mutable
// can be null OR a Database
// without "?" Dart would freak out if null - must ALWAYS be a Database, null would be a compile error
  static Database? _db;

//Future<Database> - is just Dart is strictly typed so it's forcing you to declare upfront what the promise resolves to.
// this is database getter is the connection, first time the db is needed it ititliases and everytime after it simply connects (call this when you need a connection)
//final db = await helper.database;   // getter — no parentheses
//final db = await helper.database(); // method — this would be wrong
  Future<Database> get database async {

// if db is null then assign it to be whatever this initilisation function resolves to
    _db ??= await _initDatabase();
    return _db!;
  }

// intialising the db
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final fullPath = join(databasePath, 'quimbi.db');

    return openDatabase(
      fullPath,
      version: 1,
      onCreate: _createTables,
    );
  }
// Future<void> this will be a this is async but resolves to nothing" — it's a promise that has no return value.
// verson's how SQLite tracks whether your schema has changed. The number gets stored inside the .db file itself. When the app opens the database it compares the stored number against the number in your code
//stored version 1, code says 2  →  run onUpgrade, schema has changed
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        title          TEXT NOT NULL,
        time_sensitive INTEGER DEFAULT 0,
        due_time       TEXT,
        alert_time     TEXT,
        completed      INTEGER DEFAULT 0,
        created_at     TEXT DEFAULT (datetime('now')),
        location_id    INTEGER REFERENCES locations(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id     INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        title       TEXT NOT NULL,
        completed   INTEGER DEFAULT 0,
        position    INTEGER
      )
    ''');

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
  }
}