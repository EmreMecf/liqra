import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../models/ai_request_dto.dart';

/// AI repository implementasyonu — hata eşlemesi ve model dönüşümü burada.
class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource _remoteDataSource;
  const AiRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AiMessageEntity>> sendMessage({
    required String systemPrompt,
    required String message,
    required String mode,
    required List<Map<String, String>> history,
    int maxTokens = 2048,
  }) async {
    try {
      final dto = await _remoteDataSource.sendMessage(AiRequestDto(
        systemPrompt: systemPrompt,
        message:      message,
        history:      history,
        maxTokens:    maxTokens,
      ));

      return Success(AiMessageEntity(
        id:        dto.id,
        role:      AiRole.assistant,
        content:   dto.content,
        timestamp: DateTime.tryParse(dto.timestamp) ?? DateTime.now(),
        mode:      mode,
      ));
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> complete({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 4096,
  }) async {
    try {
      final dto = await _remoteDataSource.sendMessage(AiRequestDto(
        systemPrompt: systemPrompt,
        message:      userPrompt,
        maxTokens:    maxTokens,
      ));
      return Success(dto.content);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> clearHistory(String userId) async {
    // Geçmiş şu an yalnızca bellekte tutuluyor; kalıcı hâle gelirse burada
    // silinecek.
    return const Success(null);
  }

  AppFailure _mapExceptionToFailure(AppException ex) => switch (ex) {
        NetworkException e   => NetworkFailure(e.message),
        ServerException e    => ServerFailure(e.message),
        RateLimitException e => NetworkFailure(e.message),
        ClaudeException e    => ServerFailure(e.message),
        _                    => UnknownFailure(ex.userMessage),
      };
}
