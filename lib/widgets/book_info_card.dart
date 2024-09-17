// lib/widgets/book_info_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';

class BookInfoCard extends StatelessWidget {
  final Book book;

  const BookInfoCard({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              book.title ?? 'Título não disponível',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Autores
            book.authors != null && book.authors!.isNotEmpty
                ? Text(
                    'Autor(es): ${book.authors}',
                    style: TextStyle(fontSize: 16),
                  )
                : Text(
                    'Autor(es): Não disponível',
                    style: TextStyle(fontSize: 16),
                  ),
            SizedBox(height: 10),
            // Publicação
            Text(
              'Publicação: ${book.publishDate ?? 'Não disponível'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            // Número de Páginas
            Text(
              'Número de Páginas: ${book.numberOfPages ?? 'Não disponível'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            // Capa do Livro
            book.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: book!.coverUrl ?? '',
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    height: 200, // Define uma altura para a imagem
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/placeholder_cover.png',
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          ],
        ),
      ),
    );
  }
}
