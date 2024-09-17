import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/book.dart';
import '../services/book_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late bool _isRead;
  final BookService _bookService = BookService();
  String? _coverUrl;
  String? _userCoverPath;

  @override
  void initState() {
    super.initState();
    _isRead = widget.book.isRead;
    _coverUrl = widget.book.userCoverPath != null
        ? widget.book.userCoverPath
        : widget.book.coverUrl;
    _userCoverPath = widget.book.userCoverPath;
  }

  Future<void> _toggleReadStatus() async {
    if (widget.book.id != null) {
      bool newStatus = !_isRead;
      await _bookService.updateReadStatus(widget.book.id!, newStatus);

      if (!mounted) return; // Verifica se o widget ainda está montado

      setState(() {
        _isRead = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Livro "${widget.book.title}" marcado como ${newStatus ? 'lido' : 'não lido'}.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Excluir Livro'),
          content: Text(
              'Tem certeza de que deseja excluir "${widget.book.title}" da sua lista?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Não excluir
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar exclusão
              },
              child: Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteBook();
    }
  }


  Future<void> _deleteBook() async {
    if (widget.book.id != null) {
      await _bookService.deleteBook(widget.book.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Livro "${widget.book.title}" foi excluído com sucesso.')),
      );
      Navigator.of(context).pop(true); // Retornar com resultado de exclusão
    }
  }

  // Função para selecionar uma imagem e atualizar a capa
  Future<void> _uploadCoverImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      // Obter o diretório para salvar a imagem
      Directory appDir = await getApplicationDocumentsDirectory();
      String fileName = basename(pickedFile.path);
      String savedPath = join(appDir.path, 'user_covers', fileName);

      // Criar o diretório se não existir
      await Directory(join(appDir.path, 'user_covers')).create(recursive: true);

      // Salvar a imagem
      File imageFile = File(pickedFile.path);
      await imageFile.copy(savedPath);

      // Atualizar o estado e o banco de dados
      if (widget.book.id != null) {
        await _bookService.updateUserCoverPath(widget.book.id!, savedPath);
        if (!mounted) return; // Verifica se o widget ainda está montado
        setState(() {
          _userCoverPath = savedPath;
          _coverUrl = savedPath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capa do livro atualizada com sucesso.')),
        );
      }
    }
  }

  // Função para formatar a data no formato MÊS/ANO
  String _formatPublishDate(String? publishDate) {
    if (publishDate == null || publishDate.isEmpty) return 'Não disponível';

    try {
      DateTime parsedDate = DateTime.parse(publishDate);
      return "${_getMonthName(parsedDate.month)}/${parsedDate.year}";
    } catch (e) {
      // Tentar extrair apenas mês e ano de strings como "January 2000"
      RegExp regExp = RegExp(r'([A-Za-z]+)\s+(\d{4})');
      Match? match = regExp.firstMatch(publishDate);
      if (match != null) {
        String monthStr = match.group(1)!.toLowerCase();
        String yearStr = match.group(2)!;
        int? month = _getMonthNumber(monthStr);
        if (month != null) {
          return "${_getMonthName(month)}/$yearStr";
        }
      }
      return publishDate; // Retorna como está se não conseguir formatar
    }
  }

  // Função auxiliar para obter o nome do mês
  String _getMonthName(int month) {
    const List<String> monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return monthNames[month - 1];
  }

  // Função auxiliar para obter o número do mês a partir do nome
  int? _getMonthNumber(String monthStr) {
    const Map<String, int> monthsMap = {
      'janeiro': 1,
      'fevereiro': 2,
      'março': 3,
      'abril': 4,
      'maio': 5,
      'junho': 6,
      'julho': 7,
      'agosto': 8,
      'setembro': 9,
      'outubro': 10,
      'novembro': 11,
      'dezembro': 12,
    };

    return monthsMap[monthStr.toLowerCase()];
  }

  @override
  Widget build(BuildContext context) {
    // Obter a altura total da tela para calcular 30%
    double screenHeight = MediaQuery.of(context).size.height;
    double coverHeight = screenHeight * 0.3;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title ?? 'Detalhes do Livro'),
        actions: [
          IconButton(
            icon: Icon(
              _isRead ? Icons.check_circle : Icons.check_circle_outline,
              color: _isRead ? Colors.greenAccent : Colors.white,
            ),
            onPressed: _toggleReadStatus,
            tooltip: _isRead ? 'Marcar como Não Lido' : 'Marcar como Lido',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Excluir Livro',
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: _uploadCoverImage,
            tooltip: 'Upload de Capa',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capa do Livro
            _coverUrl != null
                ? (widget.book.userCoverPath != null
                    ? Image.file(
                        File(_coverUrl!),
                        height: coverHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: _coverUrl!,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        height: coverHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/placeholder_cover.png',
                        height: coverHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: Colors.black54,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            widget.book.title ?? 'Título',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            // Título
            Text(
              widget.book.title ?? 'Título não disponível',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Autores
            widget.book.authors != null && widget.book.authors!.isNotEmpty
                ? Text(
                    'Autor(es): ${widget.book.authors}',
                    style: TextStyle(fontSize: 18),
                  )
                : Text(
                    'Autor(es): Não disponível',
                    style: TextStyle(fontSize: 18),
                  ),
            SizedBox(height: 10),
            // Publicação (Formato MÊS/ANO)
            Text(
              'Publicação: ${_formatPublishDate(widget.book.publishDate)}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            // Número de Páginas
            Text(
              'Número de Páginas: ${widget.book.numberOfPages ?? 'Não disponível'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            // Status de Leitura
            Row(
              children: [
                Icon(
                  _isRead ? Icons.check_circle : Icons.check_circle_outline,
                  color: _isRead ? Colors.greenAccent : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  _isRead ? 'Já lido' : 'Ainda não lido',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Descrição
            Text(
              'Descrição:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            widget.book.description != null && widget.book.description!.isNotEmpty
                ? Text(
                    widget.book.description!,
                    style: TextStyle(fontSize: 16),
                  )
                : Text(
                    'Descrição não disponível.',
                    style:
                        TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
          ],
        ),
      ),
    );
  }
}
