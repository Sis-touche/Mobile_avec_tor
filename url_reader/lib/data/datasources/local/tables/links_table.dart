import 'package:drift/drift.dart';

import 'folders_table.dart';

class Links extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get folderId => integer().nullable().references(Folders, #id)();
  BoolColumn get openedViaTor => boolean().withDefault(const Constant(false))();
}
