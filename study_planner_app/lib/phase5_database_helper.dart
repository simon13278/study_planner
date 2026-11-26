import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase 5 — DatabaseHelper
//
// All SQLite code lives here and nowhere else (brief requirement).
// Singleton pattern: only one Database connection is ever open.
//
// Table: goals
//   id      INTEGER  PRIMARY KEY AUTOINCREMENT
//   subject TEXT     NOT NULL
//   hours   INTEGER  NOT NULL
//   done    INTEGER  NOT NULL DEFAULT 0   (0 = false, 1 = true)
//
// Note: SQLite has no boolean type. done is stored as 0 or 1 and
//       converted to/from Dart bool by the caller.
// ─────────────────────────────────────────────────────────────────────────────

class DatabaseHelper {
  // LOGIC: private constructor — no external instantiation
  DatabaseHelper._internal();

  // LOGIC: single shared instance used throughout the app
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // LOGIC: cached Database object; null until initDatabase() is called
  Database? _database;

  // ── LOGIC: initDatabase ───────────────────────────────────────────────────
  // Opens goals.db if it already exists, or creates it on first run.
  // Called once from main() before runApp().
  Future<void> initDatabase() async {
    if (_database != null) return; // already open

    // LOGIC: getDatabasesPath() returns the correct platform storage directory.
    // join() (from the path package) safely combines it with the filename.
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'goals.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // LOGIC: create the goals table on the very first launch
        await db.execute('''
          CREATE TABLE goals (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT    NOT NULL,
            hours   INTEGER NOT NULL,
            done    INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // LOGIC: internal getter — throws if initDatabase() was not called first
  Database get _db {
    if (_database == null) {
      throw StateError('Database not initialised. Call initDatabase() first.');
    }
    return _database!;
  }

  // ── LOGIC: insertGoal ─────────────────────────────────────────────────────
  // Inserts a goal row and returns the auto-assigned integer id.
  // Input Map must contain: subject (String), hours (int), done (int 0|1).
  Future<int> insertGoal(Map<String, dynamic> goal) async {
    return await _db.insert('goals', goal);
  }

  // ── LOGIC: getGoals ───────────────────────────────────────────────────────
  // Returns all rows ordered by id ascending.
  // 'done' column is INTEGER — caller converts to bool.
  Future<List<Map<String, dynamic>>> getGoals() async {
    return await _db.query('goals', orderBy: 'id ASC');
  }

  // ── LOGIC: updateGoal ─────────────────────────────────────────────────────
  // Changes the done value of one row.
  // LOGIC: bool → int conversion: true → 1, false → 0
  Future<void> updateGoal(int id, bool done) async {
    await _db.update(
      'goals',
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── LOGIC: deleteGoal ─────────────────────────────────────────────────────
  // Permanently removes the row with the given id.
  Future<void> deleteGoal(int id) async {
    await _db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
