import 'package:flutter/material.dart';

enum PetType {
  dog,
  cat;

  String get displayName {
    switch (this) {
      case PetType.dog:
        return 'Chó';
      case PetType.cat:
        return 'Mèo';
    }
  }

  String get emoji {
    switch (this) {
      case PetType.dog:
        return '🐕';
      case PetType.cat:
        return '🐈';
    }
  }

  IconData get icon {
    switch (this) {
      case PetType.dog:
        return Icons.pets_rounded;
      case PetType.cat:
        return Icons.cruelty_free_rounded;
    }
  }
}

