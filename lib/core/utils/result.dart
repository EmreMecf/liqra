/// Fonksiyonel hata yönetimi — dartz'a gerek yok
/// Use case ve repository dönüş tipi
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get data => (this as Success<T>).data;
  AppFailure get failure => (this as Failure<T>).failure;

  /// Sonuca göre dallanma
  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success<T> s => success(s.data),
      Failure<T> f => failure(f.failure),
    };
  }

  /// Sadece başarı durumunda çalışır
  void onSuccess(void Function(T data) action) {
    if (this is Success<T>) action((this as Success<T>).data);
  }

  /// Sadece hata durumunda çalışır
  void onFailure(void Function(AppFailure failure) action) {
    if (this is Failure<T>) action((this as Failure<T>).failure);
  }
}

final class Success<T> extends Result<T> {
  @override
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  @override
  final AppFailure failure;
  const Failure(this.failure);
}

/// Uygulama hataları
sealed class AppFailure {
  final String message;
  const AppFailure(this.message);
}

final class NetworkFailure extends AppFailure {
  final int? statusCode;
  const NetworkFailure(super.message, {this.statusCode});
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message);
}

final class CacheFailure extends AppFailure {
  const CacheFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
