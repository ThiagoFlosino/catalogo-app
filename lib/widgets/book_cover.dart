// lib/widgets/book_cover.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';

class BookCover extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCover({Key? key, required this.book, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definindo uma proporção típica de capa de livro, por exemplo, 2/3
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 2 / 3, // Ajuste conforme a proporção da capa
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    spreadRadius: 2,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.error),
                        ),
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/placeholder_cover.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            // Ícone de "Lido" no canto superior direito
            if (book.isRead)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
