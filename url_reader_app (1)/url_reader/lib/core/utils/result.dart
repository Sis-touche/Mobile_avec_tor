import '../errors/failures.dart';

/// Type "Either" allégé, pour éviter d'ajouter une dépendance complète de
/// programmation fonctionnelle (dartz, fpdart…) pour ce seul besoin.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    if (self is Error<T>) return failure(self.failure);
    throw StateError('Sous-type de Result inconnu');
  }

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
