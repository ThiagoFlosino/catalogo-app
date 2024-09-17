// lib/screens/barcode_scanner_home.dart

import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../utils/validators.dart';
import '../widgets/book_cover.dart';
import 'barcode_scanner_page.dart';
import 'book_detail_screen.dart';
import '../models/book.dart';

class BarcodeScannerHome extends StatefulWidget {
  @override
  _BarcodeScannerHomeState createState() => _BarcodeScannerHomeState();
}

class _BarcodeScannerHomeState extends State<BarcodeScannerHome> {
  List<Book> _scannedBooks = []; // Lista de livros escaneados
  bool _isLoading = false;
  final BookService _bookService = BookService();

  @override
  void initState() {
    super.initState();
    _loadScannedBooks();
  }

  // Carregar livros salvos no banco de dados
  Future<void> _loadScannedBooks() async {
    setState(() {
      _isLoading = true;
    });

    List<Book> books = await _bookService.getAllBooks();

    setState(() {
      _scannedBooks = books;
      _isLoading = false;
    });
  }

  Future<void> _scanBarcode() async {
    String? scannedBarcode = '';

    // Navega para a página de scanner e aguarda o resultado
    scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => BarcodeScannerPage()),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      // Chama a API com o ISBN escaneado e salva no banco de dados
      _fetchAndAddBook(scannedBarcode);
    } else {
      // O usuário voltou sem escanear um código
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum código escaneado.')),
      );
    }
  }

  Future<void> _fetchAndAddBook(String isbn) async {
    if (!mounted) return; // Verifica se o widget ainda está montado

    // Verifica se o ISBN é válido antes de chamar a API
    if (!isValidISBN(isbn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ISBN inválido.')),
      );
      return;
    }

    // **Adicionando Validação para Evitar Livros Duplicados**
    bool alreadyScanned = _scannedBooks.any((book) => book.isbn == isbn);
    if (alreadyScanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Este livro já foi escaneado.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Book? book = await _bookService.fetchAndSaveBookInfo(isbn);

      if (book != null) {
        setState(() {
          _scannedBooks.insert(0, book); // Adiciona o livro à lista no início
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Livro "${book.title}" adicionado à lista.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Nenhum resultado encontrado para o ISBN: $isbn.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Remover todos os livros da lista e do banco de dados
  Future<void> _clearAllBooks() async {
    await _bookService.deleteAllBooks();
    setState(() {
      _scannedBooks.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lista de livros limpa.')),
    );
  }

  // Remover um livro específico da lista e do banco de dados
  Future<void> _removeBook(int index) async {
    Book book = _scannedBooks[index];
    if (book.id != null) {
      await _bookService.deleteBook(book.id!);
      setState(() {
        _scannedBooks.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Livro "${book.title}" removido.')),
      );
    }
  }

  // Atualizar o status de leitura de um livro
  Future<void> _toggleReadStatus(int index) async {
    Book book = _scannedBooks[index];
    if (book.id != null) {
      bool newStatus = !book.isRead;
      await _bookService.updateReadStatus(book.id!, newStatus);
      setState(() {
        _scannedBooks[index].isRead = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Livro "${book.title}" marcado como ${newStatus ? 'lido' : 'não lido'}.')),
      );
    }
  }

  Widget _buildBookGrid() {
    if (_scannedBooks.isEmpty) {
      return Center(
        child: Text(
          'Nenhum livro escaneado. Pressione o botão de câmera para começar.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 capas por linha
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2 / 3, // Proporção da capa
      ),
      itemCount: _scannedBooks.length,
      itemBuilder: (context, index) {
        final book = _scannedBooks[index];
        return Dismissible(
          key: Key(book.id.toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            await _removeBook(index);
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          child: GestureDetector(
            onLongPress: () {
              // Alternativa para marcar como lido/não lido
              _toggleReadStatus(index);
            },
            child: BookCover(
              book: book,
              onTap: () async {
                bool? wasDeleted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
                  ),
                );

                if (wasDeleted == true) {
                  setState(() {
                    _scannedBooks.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Livro "${book.title}" excluído.')),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner de Código de Barras'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _scannedBooks.isNotEmpty ? _clearAllBooks : null,
            tooltip: 'Limpar Lista',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        child: Icon(Icons.camera_alt),
        tooltip: 'Escanear Código de Barras',
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildBookGrid(),
      ),
    );
  }
}
