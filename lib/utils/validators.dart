// lib/utils/validators.dart

bool isValidISBN(String isbn) {
  // Remove quaisquer traços ou espaços
  isbn = isbn.replaceAll('-', '').replaceAll(' ', '');

  // Verifica se o ISBN possui 10 ou 13 caracteres
  if (isbn.length != 10 && isbn.length != 13) {
    return false;
  }

  // Validação específica para ISBN-10
  if (isbn.length == 10) {
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      if (int.tryParse(isbn[i]) == null) {
        return false;
      }
      sum += (10 - i) * int.parse(isbn[i]);
    }

    // O último caractere pode ser um número ou 'X'
    String lastChar = isbn[9].toUpperCase();
    if (lastChar != 'X' && int.tryParse(lastChar) == null) {
      return false;
    }

    sum += (lastChar == 'X') ? 10 : int.parse(lastChar);

    return sum % 11 == 0;
  }

  // Validação específica para ISBN-13
  if (isbn.length == 13) {
    int sum = 0;
    for (int i = 0; i < 13; i++) {
      int? digit = int.tryParse(isbn[i]);
      if (digit == null) {
        return false;
      }
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    return sum % 10 == 0;
  }

  return false;
}
