import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/fsm.dart';
import '../models/fsm_state.dart';
import '../models/transition.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fsm_editor.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE states ADD COLUMN color TEXT');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fsms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        machineType TEXT NOT NULL DEFAULT 'mealy',
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE states (
        id TEXT PRIMARY KEY,
        fsmId TEXT NOT NULL,
        label TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        isInitial INTEGER NOT NULL DEFAULT 0,
        isFinal INTEGER NOT NULL DEFAULT 0,
        output TEXT,
        color TEXT,
        FOREIGN KEY (fsmId) REFERENCES fsms(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE transitions (
        id TEXT PRIMARY KEY,
        fsmId TEXT NOT NULL,
        fromStateId TEXT NOT NULL,
        toStateId TEXT NOT NULL,
        label TEXT NOT NULL,
        output TEXT,
        FOREIGN KEY (fsmId) REFERENCES fsms(id) ON DELETE CASCADE,
        FOREIGN KEY (fromStateId) REFERENCES states(id) ON DELETE CASCADE,
        FOREIGN KEY (toStateId) REFERENCES states(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> insertFSM(FSM fsm) async {
    final db = await database;
    await db.insert('fsms', fsm.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FSM>> getAllFSMs() async {
    final db = await database;
    final maps = await db.query('fsms', orderBy: 'createdAt DESC');
    return maps.map((map) => FSM.fromMap(map)).toList();
  }

  Future<FSM?> getFSM(String id) async {
    final db = await database;
    final maps = await db.query('fsms', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return FSM.fromMap(maps.first);
  }

  Future<void> updateFSM(FSM fsm) async {
    final db = await database;
    await db.update('fsms', fsm.toMap(), where: 'id = ?', whereArgs: [fsm.id]);
  }

  Future<void> deleteFSM(String id) async {
    final db = await database;
    await db.delete('transitions', where: 'fsmId = ?', whereArgs: [id]);
    await db.delete('states', where: 'fsmId = ?', whereArgs: [id]);
    await db.delete('fsms', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertState(FSMState state) async {
    final db = await database;
    await db.insert('states', state.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FSMState>> getStatesForFSM(String fsmId) async {
    final db = await database;
    final maps = await db.query('states', where: 'fsmId = ?', whereArgs: [fsmId]);
    return maps.map((map) => FSMState.fromMap(map)).toList();
  }

  Future<void> updateState(FSMState state) async {
    final db = await database;
    await db.update('states', state.toMap(), where: 'id = ?', whereArgs: [state.id]);
  }

  Future<void> deleteState(String id) async {
    final db = await database;
    await db.delete('transitions', where: 'fromStateId = ? OR toStateId = ?', whereArgs: [id, id]);
    await db.delete('states', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertTransition(Transition transition) async {
    final db = await database;
    await db.insert('transitions', transition.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Transition>> getTransitionsForFSM(String fsmId) async {
    final db = await database;
    final maps = await db.query('transitions', where: 'fsmId = ?', whereArgs: [fsmId]);
    return maps.map((map) => Transition.fromMap(map)).toList();
  }

  Future<void> updateTransition(Transition transition) async {
    final db = await database;
    await db.update('transitions', transition.toMap(), where: 'id = ?', whereArgs: [transition.id]);
  }

  Future<void> deleteTransition(String id) async {
    final db = await database;
    await db.delete('transitions', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getNextLabel(String fsmId) async {
    final states = await getStatesForFSM(fsmId);
    if (states.isEmpty) return 'A';
    final labels = states.map((s) => s.label).toSet();
    int index = 0;
    while (labels.contains(_indexToLabel(index))) {
      index++;
    }
    return _indexToLabel(index);
  }

  String _indexToLabel(int index) {
    String label = '';
    int n = index;
    while (n >= 0) {
      label = String.fromCharCode(65 + (n % 26)) + label;
      n = (n ~/ 26) - 1;
    }
    return label;
  }
}
