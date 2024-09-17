// lib/services/database_helper.dart

import 'dart:async';
import 'dart:convert'; // Import necessário para JSON
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Inicializa o banco de dados se ainda não estiver
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Obter o diretório onde o banco de dados será armazenado
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'books.db');

    // Abrir o banco de dados
    return await openDatabase(
      path,
      version: 7, // Incrementar a versão para aplicar a nova migração
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Criar a tabela quando o banco de dados for criado pela primeira vez
  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isbn TEXT UNIQUE,
        title TEXT,
        authors TEXT,
        publish_date TEXT,
        number_of_pages INTEGER,
        cover_url TEXT, -- Armazenar a capa única
        user_cover_path TEXT, -- Caminho da capa do usuário
        description TEXT, -- Descrição do livro
        source TEXT, -- Origem dos dados
        is_read INTEGER DEFAULT 0
      )
    ''');
  }

  // Migrar o banco de dados para incluir o campo user_cover_path
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Iniciando migração do banco de dados de versão $oldVersion para $newVersion');

    if (oldVersion < 7) {
      // Adicionar coluna user_cover_path
      await db.execute('''
        ALTER TABLE books ADD COLUMN user_cover_path TEXT
      ''');

      print('Adicionada a coluna user_cover_path');
    }

    // Caso haja outras migrações futuras, adicione-as aqui
    print('Migração do banco de dados concluída');
  }

  // Inserir um novo livro no banco de dados
  Future<int> insertBook(Book book) async {
    final db = await database;
    return await db.insert(
      'books',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora duplicatas
    );
  }

  // Obter todos os livros do banco de dados
  Future<List<Book>> getBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('books', orderBy: 'id DESC');

    return List.generate(maps.length, (i) {
      return Book.fromMap(maps[i]);
    });
  }

  // Remover todos os livros do banco de dados
  Future<int> deleteAllBooks() async {
    final db = await database;
    return await db.delete('books');
  }

  // Remover um livro específico pelo ID
  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Atualizar o status de leitura de um livro
  Future<int> updateReadStatus(int id, bool isRead) async {
    final db = await database;
    return await db.update(
      'books',
      {'is_read': isRead ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Atualizar o caminho da capa do usuário
  Future<int> updateUserCoverPath(int id, String userCoverPath) async {
    final db = await database;
    return await db.update(
      'books',
      {'user_cover_path': userCoverPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Função para deletar o banco de dados (usada apenas durante o desenvolvimento)
  Future<void> deleteDatabaseFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'books.db');
    await deleteDatabase(path);
    print('Banco de dados deletado');
  }
}
