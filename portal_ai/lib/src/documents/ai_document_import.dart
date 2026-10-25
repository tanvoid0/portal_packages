import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../chat/ai_proposal.dart';
import '../clients/ai_completion_client.dart';
import 'ai_document_client.dart';

/// A file the user chose, in memory.
class AiPickedFile {
  const AiPickedFile({required this.bytes, required this.name});

  final List<int> bytes;
  final String name;
}

/// Puts a file in front of the user and returns it, or null if they backed out.
typedef AiDocumentPick = Future<AiPickedFile?> Function();

/// The default picker: PDFs, images and text, read into memory.
Future<AiPickedFile?> pickAiDocument() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const [
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'heic',
      'txt',
      'csv',
    ],
  );
  if (file == null) return null;
  return AiPickedFile(bytes: await file.readAsBytes(), name: file.name);
}

/// Upload a document, review what the assistant found in it, apply the rest.
///
/// The sheet owns the pattern every app repeats -- pick, read, wait, review,
/// apply, report -- and nothing about any one app's data. A host supplies
/// three things:
///
/// * [instruction], the prompt saying what to pull out and in what JSON
///   shape. This is where a BNPL contract differs from a recipe photo.
/// * [toProposals], which turns that JSON into [AiProposal]s to show, each
///   carrying the host's real model in [AiProposal.payload].
/// * [onApply], which writes the ones the user kept.
///
/// Nothing is written until the user presses apply, because a model reading a
/// scanned document gets things wrong and the fix has to be "untick it", not
/// "go and delete six rows".
class AiDocumentImportSheet extends StatefulWidget {
  const AiDocumentImportSheet({
    super.key,
    required this.documents,
    required this.client,
    required this.instruction,
    required this.toProposals,
    required this.onApply,
    this.pick = pickAiDocument,
    this.title = 'Import from a document',
    this.hint = 'A PDF, a photo or a screenshot.',
    this.applyLabel = 'Add selected',
    this.autoStart = false,
    this.intro,
    this.emptyTitle = 'Nothing to import from that file.',
    this.emptyMessage,
    this.pickLabel = 'Choose another file',
    this.footerBuilder,
  });

  final AiDocumentClient documents;

  /// Whichever backend the user picked -- server, cloud, Ollama or on-device.
  final AiCompletionClient client;

  final String instruction;

  /// Decoded JSON in, rows to review out. Throw to reject a bad reply.
  final List<AiProposal> Function(dynamic json) toProposals;

  /// Writes what the user kept. Errors surface in the sheet.
  final Future<void> Function(List<AiProposal> accepted) onApply;

  final AiDocumentPick pick;
  final String title;
  final String hint;
  final String applyLabel;

  /// Opens the picker as the sheet mounts, for a host that already asked
  /// ("Scan a receipt" has no use for a "Choose a file" step first).
  final bool autoStart;

  /// A muted line over the rows saying what was read and where it goes:
  /// ("3 receipts found in receipts.jpg"). Given the count and the file name.
  final String Function(int count, String fileName)? intro;

  /// The nothing-found state: its title, a hint under it, and the retry label.
  final String emptyTitle;
  final String? emptyMessage;
  final String pickLabel;

  /// Read-only extra under the rows, e.g. an agreement's instalments. Given
  /// the rows found.
  final Widget Function(List<AiProposal> found)? footerBuilder;

  /// Shows the sheet. Resolves to how many rows were applied, or null if the
  /// user closed it without applying any.
  static Future<int?> show(
    BuildContext context, {
    required AiDocumentClient documents,
    required AiCompletionClient client,
    required String instruction,
    required List<AiProposal> Function(dynamic json) toProposals,
    required Future<void> Function(List<AiProposal> accepted) onApply,
    AiDocumentPick pick = pickAiDocument,
    String title = 'Import from a document',
    String hint = 'A PDF, a photo or a screenshot.',
    String applyLabel = 'Add selected',
    String Function(int count, String fileName)? intro,
    String emptyTitle = 'Nothing to import from that file.',
    String? emptyMessage,
    String pickLabel = 'Choose another file',
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AiDocumentImportSheet(
        documents: documents,
        client: client,
        instruction: instruction,
        toProposals: toProposals,
        onApply: onApply,
        pick: pick,
        title: title,
        hint: hint,
        applyLabel: applyLabel,
        intro: intro,
        emptyTitle: emptyTitle,
        emptyMessage: emptyMessage,
        pickLabel: pickLabel,
      ),
    );
  }

  @override
  State<AiDocumentImportSheet> createState() => _AiDocumentImportSheetState();
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

enum _Stage { idle, reading, review, applying, failed, empty }

class _AiDocumentImportSheetState extends State<AiDocumentImportSheet> {
  _Stage _stage = _Stage.idle;
  String? _error;
  AiPickedFile? _file;
  List<AiProposal> _found = const [];
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _choose();
  }

  /// Picks a file, then reads it.
  Future<void> _choose() async {
    final file = await widget.pick();
    if (file == null || !mounted) return;
    _file = file;
    await _read();
  }

  /// Reads [_file] again: the retry after a failure, without another pick.
  Future<void> _read() async {
    final file = _file!;
    setState(() {
      _stage = _Stage.reading;
      _error = null;
    });

    try {
      final json = await widget.documents.extractJson(
        client: widget.client,
        bytes: file.bytes,
        filename: file.name,
        instruction: widget.instruction,
      );
      final found = widget.toProposals(json);
      if (!mounted) return;
      setState(() {
        _found = found;
        _selected
          ..clear()
          ..addAll(found.map((p) => p.id));
        _stage = found.isEmpty ? _Stage.empty : _Stage.review;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _error = error is AiCompletionException ? error.message : '$error';
      });
    }
  }

  Future<void> _apply() async {
    final accepted = _found.where((p) => _selected.contains(p.id)).toList();
    if (accepted.isEmpty) return;

    setState(() {
      _stage = _Stage.applying;
      _error = null;
    });
    try {
      await widget.onApply(accepted);
      if (mounted) Navigator.of(context).pop(accepted.length);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.review;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final reading = _stage == _Stage.reading;
    final applying = _stage == _Stage.applying;
    final reviewing = _stage == _Stage.review || applying;
    final name = _file?.name;

    // Only the rows bring their own gutter; the rest of the sheet needs it.
    Widget gutter(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.lg),
      child: child,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: t.spacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + t.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          gutter(
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: t.textStyles.title.copyWith(color: cs.onSurface),
                  ),
                ),
                PortalButton.icon(
                  icon: PortalIcons.close_rounded,
                  tooltip: 'Close',
                  onPressed: reading || applying
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          SizedBox(height: t.spacing.xs),
          gutter(
            Text(
              name ?? widget.hint,
              style: t.textStyles.body.copyWith(color: cs.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: t.spacing.lg),
          if (reading)
            Semantics(
              liveRegion: true,
              label: 'Reading the document',
              child: PortalListSection.skeleton(
                rows: 3,
                leading: PortalSkeletonLeading.none,
                trailing: PortalSkeletonTrailing.checkbox,
              ),
            )
          else if (_stage == _Stage.failed)
            gutter(
              PortalEmptyState.error(
                title: "Couldn't read ${name ?? 'that file'}",
                message: _error,
                onRetry: _read,
                icon: PortalIcons.description_rounded,
                inCard: false,
              ),
            )
          else if (_stage == _Stage.empty)
            gutter(
              PortalEmptyState(
                icon: PortalIcons.search_off_rounded,
                title: widget.emptyTitle,
                message: widget.emptyMessage,
                actionLabel: widget.pickLabel,
                onAction: _choose,
                inCard: false,
              ),
            )
          else if (reviewing) ...[
            if (_error case final e?) ...[
              gutter(
                PortalPrompt(
                  size: PortalPromptSize.compact,
                  sentiment: PortalSentiment.negative,
                  message: e,
                ),
              ),
              SizedBox(height: t.spacing.sm),
            ],
            if (widget.intro case final intro?) ...[
              gutter(
                Text(
                  intro(_found.length, name ?? ''),
                  style: t.textStyles.body.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              SizedBox(height: t.spacing.sm),
            ],
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // A plain row: `.checklist(done:)` would strike a ticked
                  // proposal through, and here ticked means "will be added".
                  for (final proposal in _found)
                    PortalListItem(
                      title: proposal.title,
                      subtitle: [
                        proposal.badge,
                        proposal.subtitle,
                      ].where((x) => x.isNotEmpty).join(' · ').nullIfEmpty,
                      trailing: PortalListAccessory.checkbox(
                        checked: _selected.contains(proposal.id),
                        onChanged: applying
                            ? null
                            : (on) => setState(() {
                                if (on) {
                                  _selected.add(proposal.id);
                                } else {
                                  _selected.remove(proposal.id);
                                }
                              }),
                      ),
                    ),
                  if (widget.footerBuilder case final footer?)
                    gutter(footer(_found)),
                ],
              ),
            ),
          ],
          SizedBox(height: t.spacing.lg),
          if (reviewing)
            gutter(
              PortalButton(
                label: '${widget.applyLabel} (${_selected.length})',
                leading: const Icon(Icons.check),
                isLoading: applying,
                busyLabel: 'Saving...',
                onPressed: _selected.isEmpty ? null : _apply,
              ),
            )
          else if (_stage == _Stage.idle)
            gutter(
              PortalButton(
                label: 'Choose a file',
                leading: const Icon(Icons.upload_file),
                onPressed: _choose,
              ),
            ),
        ],
      ),
    );
  }
}
