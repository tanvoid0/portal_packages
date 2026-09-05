import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
      ),
    );
  }

  @override
  State<AiDocumentImportSheet> createState() => _AiDocumentImportSheetState();
}

enum _Stage { idle, reading, review, applying }

class _AiDocumentImportSheetState extends State<AiDocumentImportSheet> {
  _Stage _stage = _Stage.idle;
  String? _error;
  String? _filename;
  List<AiProposal> _found = const [];
  final Set<String> _selected = <String>{};

  Future<void> _read() async {
    final file = await widget.pick();
    if (file == null || !mounted) return;

    setState(() {
      _stage = _Stage.reading;
      _error = null;
      _filename = file.name;
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
        _stage = found.isEmpty ? _Stage.idle : _Stage.review;
        _error = found.isEmpty ? 'Nothing to import from that file.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
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
    final theme = Theme.of(context);
    final busy = _stage == _Stage.reading || _stage == _Stage.applying;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title, style: theme.textTheme.titleMedium),
              ),
              IconButton(
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _filename ?? widget.hint,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_stage == _Stage.reading)
            const _Busy(label: 'Reading the document...')
          else if (_stage == _Stage.applying)
            const _Busy(label: 'Saving...')
          else if (_stage == _Stage.review)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _found.length,
                itemBuilder: (context, index) {
                  final proposal = _found[index];
                  return CheckboxListTile(
                    value: _selected.contains(proposal.id),
                    onChanged: (on) => setState(() {
                      if (on ?? false) {
                        _selected.add(proposal.id);
                      } else {
                        _selected.remove(proposal.id);
                      }
                    }),
                    title: Text(proposal.title),
                    subtitle: proposal.subtitle.isEmpty
                        ? null
                        : Text(proposal.subtitle),
                    secondary: proposal.badge.isEmpty
                        ? null
                        : Chip(
                            label: Text(proposal.badge),
                            labelStyle: theme.textTheme.labelSmall,
                            visualDensity: VisualDensity.compact,
                          ),
                    dense: true,
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: _stage == _Stage.review
                ? FilledButton.icon(
                    onPressed: _selected.isEmpty ? null : _apply,
                    icon: const Icon(Icons.check),
                    label: Text('${widget.applyLabel} (${_selected.length})'),
                  )
                : FilledButton.icon(
                    onPressed: busy ? null : _read,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose a file'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
