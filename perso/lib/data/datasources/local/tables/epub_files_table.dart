import 'package:drift/drift.dart';

class EpubFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get lastPosition => text().nullable()();
  /// Chemin vers l'image de couverture extraite du epub (PNG), si disponible.
  TextColumn get coverPath => text().nullable()();
  /// Nombre total de chapitres, calculé une fois à l'import — permet de
  /// calculer une progression de lecture sans reparser le fichier.
  IntColumn get totalChapters => integer().nullable()();
}
