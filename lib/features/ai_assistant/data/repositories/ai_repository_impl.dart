import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../models/ai_request_dto.dart';

/// AI repository implementasyonu — hata yakalama ve model dönüşümü burada
class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource _remoteDataSource;
  const AiRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AiMessageEntity>> sendMessage({
    required String message,
    required String mode,
    required AiContextDto context,
    required List<Map<String, String>> history,
  }) async {
    try {
      final request = AiRequestDto(
        message: message,
        mode: mode,
        context: context,
        history: history,
      );

      final dto = await _remoteDataSource.sendMessage(request);

      final entity = AiMessageEntity(
        id: dto.id,
        role: AiRole.assistant,
        content: dto.content,
        timestamp: DateTime.tryParse(dto.timestamp) ?? DateTime.now(),
        mode: mode,
      );

      return Success(entity);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> clearHistory(String userId) async {
    // TODO: Yerel cache + backend senkronizasyonu
    return const Success(null);
  }

  AppFailure _mapExceptionToFailure(AppException ex) => switch (ex) {
    NetworkException e => NetworkFailure(e.message),
    ServerException e  => ServerFailure(e.message),
    RateLimitException e => NetworkFailure(e.message),
    ClaudeException e  => ServerFailure(e.message),
    _                  => UnknownFailure(ex.userMessage),
  };
}
