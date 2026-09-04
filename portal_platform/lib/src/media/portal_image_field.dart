import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'portal_image_picker_sheet.dart';
import 'portal_image_search_service.dart';
import 'portal_media_service.dart';

/// The one way a Portal form asks for an image.
///
/// Empty it is a single tap target; filled it is the image itself with change
/// and remove overlaid on it. The URL text box that used to sit beside this in
/// every form now lives inside [PortalImagePickerSheet], so there is one entry
/// point instead of two competing ones.
class PortalImageField extends StatelessWidget {
  const PortalImageField({
    super.key,
    required this.value,
    required this.onChanged,
    this.searchQuery = '',
    this.suggestions = const [],
    this.height = 180,
    this.emptyLabel = 'Add image',
    this.service,
    this.mediaService,
  });

  /// The current image URL, or null/empty for none.
  final String? value;

  /// Called with the new URL, or null when the user removes the image.
  final ValueChanged<String?> onChanged;

  /// Seeds the picker's search box — usually whatever the user has typed into
  /// the name field, so the sheet opens on relevant results.
  final String searchQuery;

  /// Extra one-tap queries offered as chips in the picker.
  final List<String> suggestions;

  final double height;
  final String emptyLabel;

  /// Injectable for tests; forwarded to the picker.
  final PortalImageSearchService? service;

  /// Injectable for tests; forwarded to the picker.
  final PortalMediaService? mediaService;

  Future<void> _openPicker(BuildContext context) async {
    final url = await PortalImagePickerSheet.show(
      context,
      initialQuery: searchQuery.trim(),
      suggestions: suggestions,
      currentUrl: _url,
      service: service,
      mediaService: mediaService,
    );
    if (url != null) onChanged(url);
  }

  String? get _url {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _url;

    if (url == null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _openPicker(context),
          icon: const Icon(Icons.image_search_rounded),
          label: Text(emptyLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            side: BorderSide(color: cs.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              height: height,
              color: cs.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => Container(
              height: height,
              color: cs.errorContainer,
              child: Center(
                child: Icon(Icons.broken_image, color: cs.onErrorContainer),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OverlayButton(
                  icon: Icons.image_search_rounded,
                  tooltip: 'Change image',
                  onPressed: () => _openPicker(context),
                ),
                const SizedBox(width: 4),
                _OverlayButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Remove image',
                  onPressed: () => onChanged(null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      // Fixed dark chrome rather than the colour scheme: this sits on top of an
      // arbitrary photo, where a themed tonal button can vanish.
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        minimumSize: const Size(36, 36),
      ),
    );
  }
}
