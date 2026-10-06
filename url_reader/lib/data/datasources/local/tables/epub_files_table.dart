import 'package:drift/drift.dart';

class EpubFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get lastPosition => text().nullable()();
}
