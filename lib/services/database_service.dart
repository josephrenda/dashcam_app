import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/clip_model.dart';
import '../models/incident_model.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dashcam.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clips (
        id TEXT PRIMARY KEY,
        filePath TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        durationSeconds INTEGER,
        fileSizeBytes INTEGER,
        latitude REAL,
        longitude REAL,
        status TEXT,
        incidentId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE incidents (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        description TEXT,
        videoPath TEXT,
        speed REAL,
        heading REAL,
        userId TEXT NOT NULL,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE buffer_segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        durationSeconds INTEGER,
        fileSizeBytes INTEGER
      )
    ''');
  }

  // Clip operations
  Future<int> insertClip(ClipModel clip) async {
    final db = await database;
    return await db.insert('clips', clip.toMap());
  }

  Future<List<ClipModel>> getAllClips() async {
    final db = await database;
    final maps = await db.query('clips', orderBy: 'timestamp DESC');
    return maps.map((map) => ClipModel.fromMap(map)).toList();
  }

  Future<ClipModel?> getClip(String id) async {
    final db = await database;
    final maps = await db.query('clips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ClipModel.fromMap(maps.first);
  }

  Future<int> updateClip(ClipModel clip) async {
    final db = await database;
    return await db.update(
      'clips',
      clip.toMap(),
      where: 'id = ?',
      whereArgs: [clip.id],
    );
  }

  Future<int> deleteClip(String id) async {
    final db = await database;
    return await db.delete('clips', where: 'id = ?', whereArgs: [id]);
  }

  // Incident operations
  Future<int> insertIncident(IncidentModel incident) async {
    final db = await database;
    return await db.insert('incidents', incident.toMap());
  }

  Future<List<IncidentModel>> getAllIncidents() async {
    final db = await database;
    final maps = await db.query('incidents', orderBy: 'timestamp DESC');
    return maps.map((map) => IncidentModel.fromMap(map)).toList();
  }

  Future<int> deleteIncident(String id) async {
    final db = await database;
    return await db.delete('incidents', where: 'id = ?', whereArgs: [id]);
  }

  // Buffer segment operations
  Future<int> insertBufferSegment(Map<String, dynamic> segment) async {
    final db = await database;
    return await db.insert('buffer_segments', segment);
  }

  Future<List<Map<String, dynamic>>> getBufferSegments() async {
    final db = await database;
    return await db.query('buffer_segments', orderBy: 'timestamp ASC');
  }

  Future<int> deleteOldestBufferSegment() async {
    final db = await database;
    final segments = await getBufferSegments();
    if (segments.isEmpty) return 0;
    return await db.delete(
      'buffer_segments',
      where: 'id = ?',
      whereArgs: [segments.first['id']],
    );
  }

  Future<int> clearBufferSegments() async {
    final db = await database;
    return await db.delete('buffer_segments');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
