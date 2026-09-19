import 'package:dental_lab_app/features/assistant/data/models/assistant_models.dart';
import 'package:dental_lab_app/features/assistant/data/repos/assistant_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class AssistantState {
  const AssistantState();
}

class AssistantLoading extends AssistantState {
  const AssistantLoading();
}

class AssistantError extends AssistantState {
  const AssistantError(this.message);
  final String message;
}

/// The assistant panel: what can be asked, and the answer to the last thing
/// that was.
class AssistantReady extends AssistantState {
  const AssistantReady({
    required this.capabilities,
    this.answer,
    this.suggestions = const [],
    this.query = '',
    this.isAsking = false,
  });

  /// Already narrowed by the server to this caller's permissions — nothing
  /// here can come back refused.
  final List<AssistantCapabilityModel> capabilities;

  /// The last answer, or null before anything was asked.
  final AssistantAnswerModel? answer;

  /// Cases and doctors matching what is typed.
  final List<AssistantSuggestionModel> suggestions;

  final String query;
  final bool isAsking;

  /// The capabilities matching what is typed, filtered **on the device** —
  /// the catalogue is already held, so this costs no request and the typed
  /// text stays put.
  List<AssistantCapabilityModel> get matches => [
    for (final capability in capabilities)
      if (capability.matches(query)) capability,
  ];

  /// The chips shown before anything is typed.
  List<AssistantCapabilityModel> get quickPrompts => [
    for (final capability in capabilities)
      if (capability.isQuickPrompt) capability,
  ];

  AssistantReady copyWith({
    AssistantAnswerModel? answer,
    List<AssistantSuggestionModel>? suggestions,
    String? query,
    bool? isAsking,
  }) => AssistantReady(
    capabilities: capabilities,
    answer: answer ?? this.answer,
    suggestions: suggestions ?? this.suggestions,
    query: query ?? this.query,
    isAsking: isAsking ?? this.isAsking,
  );
}

/// The rule-based assistant.
///
/// **The typed text stays on the device.** Capabilities are matched locally
/// against the catalogue this cubit already holds, and `/ask` is sent the
/// resolved intent id. The one exception is [suggest], which looks up real
/// laboratory rows and cannot be answered without the fragment.
class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this._repo) : super(const AssistantLoading());

  final AssistantRepo _repo;

  Future<void> load() async {
    emit(const AssistantLoading());

    final result = await _repo.getCapabilities();
    if (isClosed) return;

    result.fold(
      (failure) => emit(AssistantError(failure.errorMessage)),
      (capabilities) => emit(AssistantReady(capabilities: capabilities)),
    );
  }

  /// Records what is typed and refreshes the local capability matches.
  ///
  /// Does **not** hit the network: entity suggestions are asked for
  /// separately, by [suggest], so a screen can decide when a fragment is
  /// worth sending.
  void setQuery(String query) {
    final current = state;
    if (current is! AssistantReady) return;

    emit(
      current.copyWith(
        query: query,
        suggestions: query.trim().isEmpty ? const [] : current.suggestions,
      ),
    );
  }

  /// Looks up cases and doctors matching [query] — the one call that carries
  /// a piece of what the user typed.
  Future<void> suggest(String query) async {
    final current = state;
    if (current is! AssistantReady) return;
    if (query.trim().length < 2) {
      emit(current.copyWith(suggestions: const []));
      return;
    }

    final result = await _repo.suggest(query);
    if (isClosed) return;

    final latest = state;
    if (latest is! AssistantReady) return;

    result.fold(
      // A failed lookup leaves the capability matches usable rather than
      // taking the panel down: the local half still answers.
      (_) => emit(latest.copyWith(suggestions: const [])),
      (suggestions) => emit(latest.copyWith(suggestions: suggestions)),
    );
  }

  /// Asks one capability, sending [AssistantCapabilityModel.id] rather than
  /// the sentence — and the query only where the capability consumes it.
  Future<void> ask(AssistantCapabilityModel capability) async {
    final current = state;
    if (current is! AssistantReady) return;

    emit(current.copyWith(isAsking: true));

    final result = await _repo.ask(
      intentId: capability.id,
      query: capability.acceptsQuery ? current.query.trim() : null,
    );
    if (isClosed) return;

    final latest = state;
    if (latest is! AssistantReady) return;

    result.fold(
      (failure) {
        emit(latest.copyWith(isAsking: false));
        emit(AssistantError(failure.errorMessage));
        emit(latest.copyWith(isAsking: false));
      },
      (answer) => emit(latest.copyWith(answer: answer, isAsking: false)),
    );
  }
}
