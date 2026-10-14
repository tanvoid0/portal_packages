/// What an app card and an ask card draw, as JSON-only data.
///
/// Blocks are persisted inside a chat turn (see `AiBlock`), so these hold
/// strings and numbers, never widgets: the app's mark is supplied by the host
/// page (`AiAssistantPage.appMark`) from [AiCard.app], not stored.
library;

Map<String, dynamic> _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : const {};

String? _text(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;

/// One row of an app card (or of an ask): a record, with an optional figure.
class AiCardRow {
  const AiCardRow(
    this.title, {
    this.subtitle,
    this.value,
    this.unit,
    this.imageUrl,
    this.openLabel,
  });

  final String title;
  final String? subtitle;
  final String? value;

  /// Muted after [value] ('2,240' kg).
  final String? unit;

  /// Leads the row as a thumbnail; decorative, the title names it.
  final String? imageUrl;

  /// Non-null: the row opens its record, and is heard as this button
  /// ("Open Northwind credit card in Finance").
  final String? openLabel;

  Map<String, dynamic> toJson() => {
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (value != null) 'value': value,
    if (unit != null) 'unit': unit,
    if (imageUrl != null) 'image_url': imageUrl,
    if (openLabel != null) 'open_label': openLabel,
  };

  factory AiCardRow.fromJson(Map<String, dynamic> json) => AiCardRow(
    _text(json['title']) ?? '',
    subtitle: _text(json['subtitle']),
    value: _text(json['value']),
    unit: _text(json['unit']),
    imageUrl: _text(json['image_url']),
    openLabel: _text(json['open_label']),
  );
}

/// The one figure a card is about, with its "of" and a caption under it.
class AiCardSummary {
  const AiCardSummary(this.amount, {this.of, this.caption});

  final String amount;
  final String? of;
  final String? caption;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    if (of != null) 'of': of,
    if (caption != null) 'caption': caption,
  };

  factory AiCardSummary.fromJson(Map<String, dynamic> json) => AiCardSummary(
    _text(json['amount']) ?? '',
    of: _text(json['of']),
    caption: _text(json['caption']),
  );
}

/// What was done, and where to see it ([openLabel] names Open).
class AiCardReceipt {
  const AiCardReceipt(this.label, {this.openLabel});

  final String label;
  final String? openLabel;

  Map<String, dynamic> toJson() => {
    'label': label,
    if (openLabel != null) 'open_label': openLabel,
  };

  factory AiCardReceipt.fromJson(Map<String, dynamic> json) => AiCardReceipt(
    _text(json['label']) ?? '',
    openLabel: _text(json['open_label']),
  );
}

/// A tile from another app: its head, an optional summary figure, rows, and
/// a receipt once the assistant acted.
class AiCard {
  const AiCard({
    required this.app,
    required this.eyebrow,
    this.label,
    this.openLabel,
    this.summary,
    this.rows = const [],
    this.receipt,
  });

  /// Which app owns it; the page turns this into the head's mark.
  final String app;
  final String eyebrow;

  /// The tile's spoken name ("Finance, spending 1 to 27 September").
  /// Defaults to [eyebrow].
  final String? label;

  /// Names the head's Open for the screen reader ("Open Finance"). Null draws
  /// no Open.
  final String? openLabel;
  final AiCardSummary? summary;
  final List<AiCardRow> rows;
  final AiCardReceipt? receipt;

  Map<String, dynamic> toJson() => {
    'app': app,
    'eyebrow': eyebrow,
    if (label != null) 'label': label,
    if (openLabel != null) 'open_label': openLabel,
    if (summary != null) 'summary': summary!.toJson(),
    if (rows.isNotEmpty) 'rows': [for (final r in rows) r.toJson()],
    if (receipt != null) 'receipt': receipt!.toJson(),
  };

  factory AiCard.fromJson(Map<String, dynamic> json) => AiCard(
    app: _text(json['app']) ?? '',
    eyebrow: _text(json['eyebrow']) ?? '',
    label: _text(json['label']),
    openLabel: _text(json['open_label']),
    summary: json['summary'] is Map
        ? AiCardSummary.fromJson(_map(json['summary']))
        : null,
    rows: [
      if (json['rows'] case final List rows)
        for (final r in rows)
          if (r is Map) AiCardRow.fromJson(_map(r)),
    ],
    receipt: json['receipt'] is Map
        ? AiCardReceipt.fromJson(_map(json['receipt']))
        : null,
  );
}

/// Where a change to the user's data is: waiting for an answer, kept as a
/// receipt, or refused by the save.
enum AiAskState { waiting, saved, failed }

/// How the user answered an ask. A failed ask's Retry answers [accept].
enum AiAskAnswer { accept, decline, edit }

/// A change to the user's data, waiting for Accept; then its receipt, or what
/// went wrong -- never a receipt for a save that failed.
class AiAsk {
  const AiAsk({
    required this.title,
    this.app = '',
    this.eyebrow,
    this.label,
    this.args = const {},
    this.rows = const [],
    this.imageUrl,
    this.state = AiAskState.waiting,
    this.receipt,
    this.failure,
    this.destructive = false,
    this.acceptLabel,
  });

  final String title;

  /// Which app owns it; the page turns this into the head's mark.
  final String app;
  final String? eyebrow;

  /// The card's spoken name. Defaults to [title].
  final String? label;

  /// What will change, label to value, in order.
  final Map<String, String> args;

  /// What the change is made of, under [args] (a plan's tasks).
  final List<AiCardRow> rows;
  final String? imageUrl;
  final AiAskState state;
  final AiCardReceipt? receipt;
  final String? failure;

  /// Accept in the error fill: the change removes something.
  final bool destructive;

  /// Names the solid button; defaults to the page's Accept.
  final String? acceptLabel;

  Map<String, dynamic> toJson() => {
    'title': title,
    if (app.isNotEmpty) 'app': app,
    if (eyebrow != null) 'eyebrow': eyebrow,
    if (label != null) 'label': label,
    if (args.isNotEmpty) 'args': args,
    if (rows.isNotEmpty) 'rows': [for (final r in rows) r.toJson()],
    if (imageUrl != null) 'image_url': imageUrl,
    'state': state.name,
    if (receipt != null) 'receipt': receipt!.toJson(),
    if (failure != null) 'failure': failure,
    if (destructive) 'destructive': true,
    if (acceptLabel != null) 'accept_label': acceptLabel,
  };

  factory AiAsk.fromJson(Map<String, dynamic> json) => AiAsk(
    title: _text(json['title']) ?? '',
    app: _text(json['app']) ?? '',
    eyebrow: _text(json['eyebrow']),
    label: _text(json['label']),
    args: {for (final e in _map(json['args']).entries) e.key: '${e.value}'},
    rows: [
      if (json['rows'] case final List rows)
        for (final r in rows)
          if (r is Map) AiCardRow.fromJson(_map(r)),
    ],
    imageUrl: _text(json['image_url']),
    state: AiAskState.values.firstWhere(
      (s) => s.name == json['state'],
      orElse: () => AiAskState.waiting,
    ),
    receipt: json['receipt'] is Map
        ? AiCardReceipt.fromJson(_map(json['receipt']))
        : null,
    failure: _text(json['failure']),
    destructive: json['destructive'] == true,
    acceptLabel: _text(json['accept_label']),
  );
}
