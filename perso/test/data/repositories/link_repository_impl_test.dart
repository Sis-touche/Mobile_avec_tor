import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:url_reader/data/datasources/local/app_database.dart';
import 'package:url_reader/data/repositories/link_repository_impl.dart';

void main() {
  late AppDatabase database;
  late LinkRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LinkRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('saveLink puis getLinks retourne le lien inséré', () async {
    final saveResult = await repository.saveLink(url: 'https://example.com', title: 'Exemple');
    expect(saveResult.isSuccess, isTrue);

    final listResult = await repository.getLinks();
    listResult.when(
      success: (links) {
        expect(links, hasLength(1));
        expect(links.first.url, 'https://example.com');
        expect(links.first.title, 'Exemple');
      },
      failure: (f) => fail('Attendu un succès, reçu : ${f.message}'),
    );
  });

  test('deleteLink retire le lien de la liste', () async {
    final saved = await repository.saveLink(url: 'https://example.com');
    final id = saved.when(success: (l) => l.id, failure: (_) => -1);

    await repository.deleteLink(id);

    final listResult = await repository.getLinks();
    listResult.when(
      success: (links) => expect(links, isEmpty),
      failure: (f) => fail('Attendu un succès, reçu : ${f.message}'),
    );
  });

  test('getLinks filtre par folderId', () async {
    await repository.saveLink(url: 'https://a.com', folderId: 1);
    await repository.saveLink(url: 'https://b.com', folderId: 2);

    final listResult = await repository.getLinks(folderId: 1);
    listResult.when(
      success: (links) {
        expect(links, hasLength(1));
        expect(links.first.url, 'https://a.com');
      },
      failure: (f) => fail('Attendu un succès, reçu : ${f.message}'),
    );
  });
}
