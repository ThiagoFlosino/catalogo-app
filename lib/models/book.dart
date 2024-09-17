import 'dart:convert'; // Import necessário para JSON

class Book {
  final int? id; // ID para o banco de dados
  final String? isbn;
  final String? title;
  final String? authors;
  final String? publishDate;
  final int? numberOfPages;
  final String? coverUrl; // URL única da capa (da API)
  final String? userCoverPath; // Caminho da imagem de capa do usuário
  final String? description; // Descrição do livro
  final String? source; // Origem dos dados (não será exibido na UI)
  bool isRead; // Campo mutável para indicar se o livro foi lido

  Book({
    this.id,
    this.isbn,
    this.title,
    this.authors,
    this.publishDate,
    this.numberOfPages,
    this.coverUrl, // Inicializado como nulo por padrão
    this.userCoverPath, // Inicializado como nulo por padrão
    this.description, // Inicializado como nulo por padrão
    this.source, // Inicializado como nulo por padrão
    this.isRead = false, // Valor padrão: não lido
  });

  // Converter um Map para um objeto Book
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      isbn: map['isbn'],
      title: map['title'],
      authors: map['authors'],
      publishDate: map['publish_date'],
      numberOfPages: map['number_of_pages'],
      coverUrl: map['cover_url'], // Mapeia o campo cover_url
      userCoverPath: map['user_cover_path'], // Mapeia o campo user_cover_path
      description: map['description'],
      source: map['source'], // Mapeia o campo source
      isRead: map['is_read'] == 1, // 1 = lido, 0 = não lido
    );
  }

  // Converter um objeto Book para um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'publish_date': publishDate,
      'number_of_pages': numberOfPages,
      'cover_url': coverUrl, // Armazena a capa única
      'user_cover_path': userCoverPath, // Armazena o caminho da capa do usuário
      'description': description, // Armazena o campo description
      'source': source, // Armazena o campo source
      'is_read': isRead ? 1 : 0, // Armazenar como 1 ou 0
    };
  }
}
