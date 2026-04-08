import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/market_data_entity.dart';

part 'portfolio_state.freezed.dart';

@freezed
sealed class PortfolioState with _$PortfolioState {
  const factory PortfolioState.initial()                                           = PortfolioInitial;
  const factory PortfolioState.loading()                                           = PortfolioLoading;
  const factory PortfolioState.loaded({required PortfolioEntity portfolio})        = PortfolioLoaded;
  const factory PortfolioState.error({required String message})                    = PortfolioError;
}

@freezed
sealed class MarketState with _$MarketState {
  const factory MarketState.initial()                                                             = MarketInitial;
  const factory MarketState.loading()                                                             = MarketLoading;
  const factory MarketState.loaded({required List<MarketDataEntity> data, required List<TopFundEntity> topFunds}) = MarketLoaded;
  const factory MarketState.error({required String message, List<MarketDataEntity>? staleData})  = MarketError;
}

extension PortfolioStateX on PortfolioState {
  bool get isLoading => this is PortfolioLoading;
  PortfolioEntity? get portfolio =>
      this is PortfolioLoaded ? (this as PortfolioLoaded).portfolio : null;
}

extension MarketStateX on MarketState {
  bool get isLoading => this is MarketLoading;
  List<MarketDataEntity> get marketData => switch (this) {
    MarketLoaded s => s.data,
    MarketError s  => s.staleData ?? const [],
    _              => const [],
  };
  List<TopFundEntity>? get topFunds => switch (this) {
    MarketLoaded s => s.topFunds,
    _              => null,
  };
}
