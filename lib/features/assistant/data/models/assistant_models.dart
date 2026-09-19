import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// One thing the assistant can answer (`AssistantCapabilityDto`).
///
/// The catalogue is **data, not code**: adding a feature server-side is a row
/// here plus a handler, with no client release — which is why nothing in this
/// app switches on a hardcoded list of intents.
///
/// What arrives is already narrowed to what the caller may see, so a user
/// without `Finance` is never offered "من عليه مستحقات؟" and then shown an
/// error. Offering an action somebody cannot perform is itself a small leak —
/// it confirms the feature exists.
class AssistantCapabilityModel {
  const AssistantCapabilityModel({
    required this.id,
    this.category,
    this.label,
    this.labelAr,
    this.keywords = const [],
    this.answerShape,
    this.isQuickPrompt = false,
    this.acceptsQuery = false,
  });

  /// Stable, never localized, never renamed — this is what `/ask` is sent.
  final String id;

  /// Groups the quick-prompt chips: cases | money | people | ops.
  final String? category;

  final String? label;
  final String? labelAr;

  /// Match terms in both languages, compared client-side after Arabic
  /// normalization. Replaces what would otherwise be a hand-maintained list
  /// of patterns in this app.
  final List<String> keywords;

  /// Which answer shape this returns, so the right skeleton can be shown
  /// before the answer lands.
  final String? answerShape;

  final bool isQuickPrompt;

  /// True when the capability consumes the user's free text (case lookup).
  /// Everything else is resolved to an id on the client, so the typed text
  /// never leaves the device — which is the assistant's whole privacy claim.
  final bool acceptsQuery;

  String get displayLabel {
    final ar = labelAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return label?.trim() ?? id;
  }

  /// Whether this capability matches what the user typed, compared against
  /// both languages' keywords and the labels themselves.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;

    if (displayLabel.toLowerCase().contains(needle)) return true;
    if (label?.toLowerCase().contains(needle) ?? false) return true;

    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(needle)) return true;
    }
    return false;
  }

  factory AssistantCapabilityModel.fromJson(Map<String, dynamic> json) {
    return AssistantCapabilityModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String?,
      label: json['label'] as String?,
      labelAr: json['labelAr'] as String?,
      keywords: [
        for (final keyword in json['keywords'] as List<dynamic>? ?? const [])
          if (keyword is String) keyword,
      ],
      answerShape: json['answerShape'] as String?,
      isQuickPrompt: json['isQuickPrompt'] as bool? ?? false,
      acceptsQuery: json['acceptsQuery'] as bool? ?? false,
    );
  }
}

/// A labelled number in an answer (`AssistantStatDto`).
class AssistantStatModel {
  const AssistantStatModel({
    required this.key,
    this.label,
    this.labelAr,
    this.value = 0,
    this.tone,
  });

  final String key;
  final String? label;
  final String? labelAr;
  final double value;

  /// neutral | critical | warning | success | info.
  final String? tone;

  String get displayLabel {
    final ar = labelAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return label?.trim() ?? key;
  }

  factory AssistantStatModel.fromJson(Map<String, dynamic> json) {
    return AssistantStatModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String?,
      labelAr: json['labelAr'] as String?,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      tone: json['tone'] as String?,
    );
  }
}

/// An amount in one currency, inside an answer row.
class AssistantMoneyModel {
  const AssistantMoneyModel({this.amount = 0, this.currency});

  final double amount;
  final CurrencyModel? currency;

  /// Never a bare number: a doctor can owe in several currencies at once and
  /// those are never blended into one figure.
  String get label =>
      currency?.format(amount) ?? amount.toStringAsFixed(2);

  factory AssistantMoneyModel.fromJson(Map<String, dynamic> json) {
    return AssistantMoneyModel(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
    );
  }
}

/// A row in an answer's list (`AssistantEntityDto`).
///
/// Deliberately generic: cases, doctors, employees, clinics and invoices all
/// render through this one shape, which is what lets a new assistant feature
/// be a backend-only change.
class AssistantEntityModel {
  const AssistantEntityModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeTextAr,
    this.badgeVariant,
    this.imagePath,
    this.tone,
    this.ratio,
    this.trailingText,
    this.trailingMoney = const [],
    this.actionUrl,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final String? badgeTextAr;
  final String? badgeVariant;
  final String? imagePath;
  final String? tone;

  /// 0..1, drives a small proportion bar. Null hides it.
  final double? ratio;

  final String? trailingText;
  final List<AssistantMoneyModel> trailingMoney;

  /// Where this row goes, picked by the server so the client never has to
  /// know which route an entity type lives at.
  ///
  /// Null when the row genuinely has nowhere to go — a per-user work count has
  /// no screen of its own. It then renders as a plain row: a control that
  /// looks tappable and does nothing is worse than one that never offered.
  final String? actionUrl;

  String? get badgeLabel {
    final ar = badgeTextAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    final en = badgeText?.trim();
    return en != null && en.isNotEmpty ? en : null;
  }

  factory AssistantEntityModel.fromJson(Map<String, dynamic> json) {
    return AssistantEntityModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      badgeText: json['badgeText'] as String?,
      badgeTextAr: json['badgeTextAr'] as String?,
      badgeVariant: json['badgeVariant'] as String?,
      imagePath: json['imagePath'] as String?,
      tone: json['tone'] as String?,
      ratio: (json['ratio'] as num?)?.toDouble(),
      trailingText: json['trailingText'] as String?,
      trailingMoney: [
        for (final money in json['trailingMoney'] as List<dynamic>? ?? const [])
          AssistantMoneyModel.fromJson(money as Map<String, dynamic>),
      ],
      actionUrl: json['actionUrl'] as String?,
    );
  }
}

/// One point on a mini chart.
class AssistantSeriesPointModel {
  const AssistantSeriesPointModel({this.label, this.value = 0});

  final String? label;
  final double value;

  factory AssistantSeriesPointModel.fromJson(Map<String, dynamic> json) {
    return AssistantSeriesPointModel(
      label: json['label'] as String?,
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One line of a chart answer (`AssistantSeriesDto`).
///
/// An answer carries a list of these, not a list of points: money is never
/// summed across currencies here any more than anywhere else, so a revenue
/// answer is one series **per currency**, each with its own total.
class AssistantSeriesModel {
  const AssistantSeriesModel({
    this.label,
    this.currency,
    this.total = 0,
    this.points = const [],
  });

  final String? label;
  final CurrencyModel? currency;
  final double total;
  final List<AssistantSeriesPointModel> points;

  String get totalLabel =>
      currency?.format(total) ?? total.toStringAsFixed(2);

  factory AssistantSeriesModel.fromJson(Map<String, dynamic> json) {
    return AssistantSeriesModel(
      label: json['label'] as String?,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      points: [
        for (final point in json['points'] as List<dynamic>? ?? const [])
          AssistantSeriesPointModel.fromJson(point as Map<String, dynamic>),
      ],
    );
  }
}

/// One assistant answer, in one of four shapes (`AssistantAnswerDto`).
///
/// `stats`, `entities`, `series` and `message` — nothing else. Any number of
/// capabilities map onto them, which is what makes a new assistant feature a
/// backend-only change.
class AssistantAnswerModel {
  const AssistantAnswerModel({
    required this.intentId,
    required this.shape,
    this.text,
    this.textAr,
    this.totalCount = 0,
    this.stats = const [],
    this.entities = const [],
    this.series = const [],
  });

  final String intentId;

  /// stats | entities | series | message.
  final String shape;

  final String? text;
  final String? textAr;

  /// Total matches **before** truncation — both the "and N more" line and the
  /// plural argument for the headline.
  final int totalCount;

  final List<AssistantStatModel> stats;
  final List<AssistantEntityModel> entities;
  final List<AssistantSeriesModel> series;

  String get headline {
    final ar = textAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return text?.trim() ?? '';
  }

  /// How many rows were left out of [entities] — what the "and N more" line
  /// reports, and zero when everything fit.
  int get truncatedCount {
    final shown = entities.length;
    return totalCount > shown ? totalCount - shown : 0;
  }

  factory AssistantAnswerModel.fromJson(Map<String, dynamic> json) {
    return AssistantAnswerModel(
      intentId: json['intentId'] as String? ?? '',
      shape: json['shape'] as String? ?? 'message',
      text: json['text'] as String?,
      textAr: json['textAr'] as String?,
      totalCount: json['totalCount'] as int? ?? 0,
      stats: [
        for (final stat in json['stats'] as List<dynamic>? ?? const [])
          AssistantStatModel.fromJson(stat as Map<String, dynamic>),
      ],
      entities: [
        for (final entity in json['entities'] as List<dynamic>? ?? const [])
          AssistantEntityModel.fromJson(entity as Map<String, dynamic>),
      ],
      series: [
        for (final line in json['series'] as List<dynamic>? ?? const [])
          AssistantSeriesModel.fromJson(line as Map<String, dynamic>),
      ],
    );
  }
}

/// A concrete thing the user might have been reaching for
/// (`AssistantSuggestionDto`) — this case, that doctor.
///
/// The one place a fragment of what the user typed leaves the device: there is
/// no way to know "خالد" is a doctor without asking. Gated on the same
/// permissions and doctor scope as the screens these rows link to.
class AssistantSuggestionModel {
  const AssistantSuggestionModel({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeTextAr,
    this.badgeVariant,
    this.imagePath,
    required this.actionUrl,
  });

  /// case | doctor — drives the icon and the grouping, not the routing.
  final String kind;

  final String id;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final String? badgeTextAr;
  final String? badgeVariant;
  final String? imagePath;
  final String actionUrl;

  String? get badgeLabel {
    final ar = badgeTextAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    final en = badgeText?.trim();
    return en != null && en.isNotEmpty ? en : null;
  }

  factory AssistantSuggestionModel.fromJson(Map<String, dynamic> json) {
    return AssistantSuggestionModel(
      kind: json['kind'] as String? ?? '',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      badgeText: json['badgeText'] as String?,
      badgeTextAr: json['badgeTextAr'] as String?,
      badgeVariant: json['badgeVariant'] as String?,
      imagePath: json['imagePath'] as String?,
      actionUrl: json['actionUrl'] as String? ?? '',
    );
  }
}

/// A deterministic operational recommendation (`SmartAssistantItemDto`).
///
/// Rule-based, with no AI service behind it: the server supplies the rule, the
/// urgency, the evidence and a safe destination; the wording is the client's.
class SmartAssistantItemModel {
  const SmartAssistantItemModel({
    required this.rule,
    required this.severity,
    required this.caseId,
    required this.caseNumber,
    this.relevantAt,
    this.ageHours = 0,
    required this.actionUrl,
  });

  final String rule;

  /// The urgency the server assigned — drives the row's colour.
  final String severity;

  final String caseId;
  final String caseNumber;
  final DateTime? relevantAt;

  /// How long this has been true — the evidence behind the recommendation.
  final int ageHours;

  final String actionUrl;

  /// The Arabic sentence behind the server's rule key. An unrecognised rule
  /// falls back to the key rather than to silence: a recommendation this
  /// client has not been taught yet is still worth surfacing.
  String get label => switch (rule) {
    'stalled' => 'حالة متوقفة بلا حركة',
    'late' => 'حالة تخطّت الوقت المتوقع',
    'due-today' => 'حالة مستحقة اليوم',
    'awaiting-material' => 'حالة بانتظار استلام العمل',
    'no-expected-completion' => 'حالة بلا وقت تنفيذ متوقع',
    final other => other,
  };

  factory SmartAssistantItemModel.fromJson(Map<String, dynamic> json) {
    return SmartAssistantItemModel(
      rule: json['rule'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      caseNumber: json['caseNumber'] as String? ?? '',
      relevantAt: DateTime.tryParse(json['relevantAt'] as String? ?? ''),
      ageHours: json['ageHours'] as int? ?? 0,
      actionUrl: json['actionUrl'] as String? ?? '',
    );
  }
}
