import 'package:equatable/equatable.dart';

class Folder extends Equatable {
  const Folder({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
