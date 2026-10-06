import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/check_tor_connection.dart';
import '../../domain/usecases/create_folder.dart';
import '../../domain/usecases/delete_link.dart';
import '../../domain/usecases/get_links.dart';
import '../../domain/usecases/open_epub.dart';
import '../../domain/usecases/save_link.dart';
import '../../domain/usecases/save_reading_position.dart';
import '../../domain/usecases/set_tor_port.dart';
import '../../domain/usecases/toggle_tor.dart';
import 'repository_providers.dart';

final getLinksProvider = Provider((ref) => GetLinks(ref.watch(linkRepositoryProvider)));
final saveLinkProvider = Provider((ref) => SaveLink(ref.watch(linkRepositoryProvider)));
final deleteLinkProvider = Provider((ref) => DeleteLink(ref.watch(linkRepositoryProvider)));
final toggleTorProvider = Provider((ref) => ToggleTor(ref.watch(torRepositoryProvider)));
final checkTorConnectionProvider =
    Provider((ref) => CheckTorConnection(ref.watch(torRepositoryProvider)));
final setTorPortProvider = Provider((ref) => SetTorPort(ref.watch(torRepositoryProvider)));
final openEpubProvider = Provider((ref) => OpenEpub(ref.watch(epubRepositoryProvider)));
final saveReadingPositionProvider =
    Provider((ref) => SaveReadingPosition(ref.watch(epubRepositoryProvider)));
final createFolderProvider = Provider((ref) => CreateFolder(ref.watch(folderRepositoryProvider)));
