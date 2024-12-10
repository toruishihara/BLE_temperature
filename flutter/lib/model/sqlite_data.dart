import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Private constructor for singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Database instance
  Database? _database;

  // Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize the database
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'temp_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE temperature (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            temp_value REAL
          )
        ''');
      },
    );
  }

  // Close the database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}
