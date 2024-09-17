// lib/services/book_service.dart

import 'dart:convert'; // Import necessário para JSON
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'database_helper.dart';

class BookService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Buscar informações do livro via APIs e salvar no banco de dados
  Future<Book?> fetchAndSaveBookInfo(String isbn) async {
    // Primeiro, verificar se o livro já está no banco de dados
    List<Book> existingBooks = await _dbHelper.getBooks();
    Book? existingBook;

    try {
      existingBook = existingBooks.firstWhere((book) => book.isbn == isbn);
    } catch (e) {
      existingBook = null;
    }

    if (existingBook != null) {
      // Livro já está salvo
      return existingBook;
    }

    // Tentar buscar na API do OpenLibrary
    Book? openLibraryBook = await _fetchFromOpenLibrary(isbn);

    // Tentar buscar na API do Google Books
    Book? googleBooksBook = await _fetchFromGoogleBooks(isbn);

    if (openLibraryBook == null && googleBooksBook == null) {
      // Livro não encontrado em nenhuma das APIs
      print('Livro não encontrado em nenhuma das APIs para ISBN: $isbn');
      return null;
    }

    // Combinar os dados das duas APIs
    Book combinedBook = _combineBookData(openLibraryBook, googleBooksBook);

    // Salvar no banco de dados
    int id = await _dbHelper.insertBook(combinedBook);

    // Atualizar o caminho da capa do usuário (inicialmente nulo)
    // Se você deseja permitir que o usuário faça upload imediatamente, implemente aqui
    // Por enquanto, deixamos como está

    print('Livro combinado e salvo com ID: $id');

    // Obter o livro recém-salvo com o ID
    List<Book> updatedBooks = await _dbHelper.getBooks();
    Book? savedBook =
        updatedBooks.firstWhere((book) => book.id == id, orElse: () => combinedBook);

    return savedBook;
  }

  // Função para buscar na API do OpenLibrary
  Future<Book?> _fetchFromOpenLibrary(String isbn) async {
    final url =
        'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final bookKey = 'ISBN:$isbn';
        final bookData = data[bookKey];
        if (bookData != null) {
          // Extrair informações do livro
          String title = bookData['title'] ?? 'Título não disponível';
          List<dynamic>? authorsList = bookData['authors'];
          String authors = 'Não disponível';
          if (authorsList != null && authorsList.isNotEmpty) {
            authors = authorsList.map((a) => a['name']).join(', ');
          }
          String publishDate = bookData['publish_date'] ?? 'Não disponível';
          int? numberOfPages = bookData['number_of_pages'];
          String? coverUrl =
              bookData['cover'] != null ? bookData['cover']['medium'] : null;
          String? description;

          // Extrair a descrição se disponível
          if (bookData['excerpts'] != null && bookData['excerpts'].isNotEmpty) {
            description = bookData['excerpts'][0]['text'];
          } else if (bookData['description'] != null) {
            if (bookData['description'] is String) {
              description = bookData['description'];
            } else if (bookData['description'] is Map &&
                bookData['description']['value'] != null) {
              description = bookData['description']['value'];
            }
          }

          Book book = Book(
            isbn: isbn,
            title: title,
            authors: authors,
            publishDate: publishDate,
            numberOfPages: numberOfPages,
            coverUrl: coverUrl, // Armazena apenas uma capa
            description: description,
          );

          print('Livro encontrado na OpenLibrary: ${book.title}');

          return book;
        } else {
          // Livro não encontrado na API do OpenLibrary
          print('Livro não encontrado na OpenLibrary para ISBN: $isbn');
          return null;
        }
      } else {
        throw Exception(
            'Erro ao chamar a API do OpenLibrary: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar na OpenLibrary: $e');
      return null;
    }
  }

  // Função para buscar na API do Google Books
  Future<Book?> _fetchFromGoogleBooks(String isbn) async {
    final url = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn&key=AIzaSyD0aw3LQK_qeX5Ix5oEe7e4W8tuZB8euDQ';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic>? items = data['items'];

        if (items != null && items.isNotEmpty) {
          final bookData = items[0]['volumeInfo'];

          // Extrair informações do livro
          String title = bookData['title'] ?? 'Título não disponível';
          List<dynamic>? authorsList = bookData['authors'];
          String authors = 'Não disponível';
          if (authorsList != null && authorsList.isNotEmpty) {
            authors = authorsList.join(', ');
          }
          String publishDate = bookData['publishedDate'] ?? 'Não disponível';
          int? numberOfPages = bookData['pageCount'];
          String? coverUrl = bookData['imageLinks'] != null
              ? bookData['imageLinks']['thumbnail']
              : null;
          String? description =
              bookData['description'] ?? 'Descrição não disponível';

          Book book = Book(
            isbn: isbn,
            title: title,
            authors: authors,
            publishDate: publishDate,
            numberOfPages: numberOfPages,
            coverUrl: coverUrl, // Armazena apenas uma capa
            description: description,
          );

          print('Livro encontrado na Google Books: ${book.title}');

          return book;
        } else {
          // Livro não encontrado na API do Google Books
          print('Livro não encontrado na Google Books para ISBN: $isbn');
          return null;
        }
      } else {
        throw Exception(
            'Erro ao chamar a API do Google Books: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar na Google Books: $e');
      return null;
    }
  }

  // Combinar os dados das duas APIs
  Book _combineBookData(Book? openLibraryBook, Book? googleBooksBook) {
    String? title =
        openLibraryBook?.title ?? googleBooksBook?.title ?? 'Título não disponível';
    String? authors =
        openLibraryBook?.authors ?? googleBooksBook?.authors ?? 'Não disponível';
    String? publishDate = openLibraryBook?.publishDate ??
        googleBooksBook?.publishDate ??
        'Não disponível';
    int? numberOfPages =
        openLibraryBook?.numberOfPages ?? googleBooksBook?.numberOfPages;
    String? description = openLibraryBook?.description ??
        googleBooksBook?.description ??
        'Descrição não disponível';

    // Priorizar a capa de maior resolução
    String? coverUrl = openLibraryBook?.coverUrl ?? googleBooksBook?.coverUrl;

    return Book(
      isbn: openLibraryBook?.isbn ?? googleBooksBook?.isbn,
      title: title,
      authors: authors,
      publishDate: publishDate,
      numberOfPages: numberOfPages,
      coverUrl: coverUrl,
      description: description,
      source: openLibraryBook?.source ?? googleBooksBook?.source,
    );
  }

  // Obter todos os livros salvos no banco de dados
  Future<List<Book>> getAllBooks() async {
    return await _dbHelper.getBooks();
  }

  // Remover todos os livros do banco de dados
  Future<void> deleteAllBooks() async {
    await _dbHelper.deleteAllBooks();
  }

  // Remover um livro específico pelo ID
  Future<void> deleteBook(int id) async {
    await _dbHelper.deleteBook(id);
  }

  // Atualizar o status de leitura de um livro
  Future<void> updateReadStatus(int id, bool isRead) async {
    await _dbHelper.updateReadStatus(id, isRead);
  }

  // Atualizar o caminho da capa do usuário
  Future<void> updateUserCoverPath(int id, String userCoverPath) async {
    await _dbHelper.updateUserCoverPath(id, userCoverPath);
  }
}
