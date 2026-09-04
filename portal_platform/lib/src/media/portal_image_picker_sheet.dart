import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'portal_image_search_service.dart';
import 'portal_media_service.dart';

/// The bottom sheet every Portal app uses to pick an image.
///
/// Four ways in, one way out. Gallery, camera, a photo-library search result,
/// or a pasted link all end up stored on our own server, and [show] resolves
/// to *that* URL — never the Unsplash CDN link or whatever the user pasted.
/// Persisting a third party's URL means the user's photo disappears the day
/// that host rotates it.
///
/// A dismissed sheet returns null, which is distinct from "cleared" — clearing
/// is the caller's own affordance.
class PortalImagePickerSheet extends StatefulWidget {
  const PortalImagePickerSheet({
    super.key,
    this.initialQuery = '',
    this.suggestions = const [],
    this.currentUrl,
    this.service,
    this.mediaService,
  });

  /// Searched immediately on open when non-empty.
  final String initialQuery;

  /// Tappable chips under the search box. Give the user the words they would
  /// have typed — "chicken curry", "dinner", "italian" — so the common case is
  /// a tap instead of a keyboard.
  final List<String> suggestions;

  /// Pre-fills the "paste a link" field and marks the matching result as
  /// selected, so re-opening the sheet shows where you already are.
  final String? currentUrl;

  /// Injectable for tests; defaults to the shared proxy client.
  final PortalImageSearchService? service;

  /// Injectable for tests; defaults to the shared media store client.
  final PortalMediaService? mediaService;

  /// Presents the picker and resolves to the chosen URL, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    String initialQuery = '',
    List<String> suggestions = const [],
    String? currentUrl,
    PortalImageSearchService? service,
    PortalMediaService? mediaService,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PortalImagePickerSheet(
        initialQuery: initialQuery,
        suggestions: suggestions,
        currentUrl: currentUrl,
        service: service,
        mediaService: mediaService,
      ),
    );
  }

  @override
  State<PortalImagePickerSheet> createState() => _PortalImagePickerSheetState();
}

class _PortalImagePickerSheetState extends State<PortalImagePickerSheet> {
  late final PortalImageSearchService _service =
      widget.service ?? PortalImageSearchService();
  late final PortalMediaService _media =
      widget.mediaService ?? PortalMediaService();
  final _searchCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<PortalImageResult> _photos = const [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _error;
  String? _selectedUrl;
  bool _saving = false;
  Timer? _debounce;

  /// Guards against an in-flight search overwriting a newer one. Each search
  /// takes a ticket; only the latest ticket may publish its results.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.currentUrl;
    _linkCtrl.text = widget.currentUrl ?? '';
    if (widget.initialQuery.trim().isNotEmpty) {
      _searchCtrl.text = widget.initialQuery.trim();
      _search(widget.initialQuery.trim());
    } else {
      _searchFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _linkCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _photos = const [];
        _hasSearched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(trimmed),
    );
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    final ticket = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _service.search(query);
      if (!mounted || ticket != _requestId) return;
      setState(() {
        _photos = results;
        _loading = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted || ticket != _requestId) return;
      setState(() {
        _loading = false;
        _hasSearched = true;
        _error = 'Could not reach the photo library.';
      });
    }
  }

  /// Every route out of this sheet funnels through here: the image is stored
  /// on our server first, and only the resulting URL is handed back.
  Future<void> _resolve(Future<String> stored) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final url = await stored;
      if (!mounted) return;
      Navigator.of(context).pop(url);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that image. Try again.')),
      );
    }
  }

  Future<void> _pickFromDevice(ImageSource source) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        // Keeps the upload under the server's 5 MB cap without a resize step
        // on either side; a phone camera original blows past it easily.
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _resolve(_media.uploadBytes(bytes, file.name));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _buildDeviceRow(),
                  _buildSearchField(cs),
                  if (widget.suggestions.isNotEmpty) _buildSuggestions(),
                  // A 2px bar rather than swapping the grid for a spinner: the
                  // results you were looking at stay put while the next set loads.
                  SizedBox(
                    height: 2,
                    child: _loading && _photos.isNotEmpty
                        ? const LinearProgressIndicator(minHeight: 2)
                        : null,
                  ),
                  Expanded(child: _buildBody(cs, scrollController)),
                  _buildLinkRow(cs),
                ],
              ),
              // Blocks the whole sheet during the upload: a second tap while
              // the first image is still going up would race two entities.
              if (_saving)
                Positioned.fill(
                  child: ColoredBox(
                    color: cs.surface.withValues(alpha: 0.7),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The device sources sit above the search box because a photo you took of
  /// your own dinner beats a stock photo of someone else's.
  Widget _buildDeviceRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _pickFromDevice(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _pickFromDevice(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Camera'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        onChanged: _onQueryChanged,
        onSubmitted: (v) {
          _debounce?.cancel();
          _search(v.trim());
        },
        decoration: InputDecoration(
          hintText: 'Search photos',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchCtrl.clear();
                    _onQueryChanged('');
                    _searchFocus.requestFocus();
                  },
                ),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        itemCount: widget.suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = widget.suggestions[i];
          return ActionChip(
            label: Text(s),
            onPressed: () {
              _debounce?.cancel();
              _searchCtrl.text = s;
              _searchFocus.unfocus();
              _search(s);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, ScrollController scrollController) {
    if (_loading && _photos.isEmpty) return _buildSkeleton(cs);

    if (_error != null) {
      return _buildMessage(
        cs,
        icon: Icons.cloud_off_rounded,
        title: _error!,
        color: cs.error,
        action: FilledButton.tonal(
          onPressed: () => _search(_searchCtrl.text.trim()),
          child: const Text('Try again'),
        ),
      );
    }

    if (_photos.isEmpty) {
      return _buildMessage(
        cs,
        icon: _hasSearched
            ? Icons.image_not_supported_outlined
            : Icons.image_search_rounded,
        title: _hasSearched
            ? 'No photos for "${_searchCtrl.text.trim()}"'
            : 'Search for a photo, or paste a link below',
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, i) {
        final photo = _photos[i];
        return _PhotoTile(
          photo: photo,
          selected: photo.regularUrl == _selectedUrl,
          onTap: () => _resolve(_media.importUrl(photo.regularUrl)),
        );
      },
    );
  }

  Widget _buildSkeleton(ColorScheme cs) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMessage(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    Color? color,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: color ?? cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: color ?? cs.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }

  Widget _buildLinkRow(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _linkCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) {
                    if (isUsableImageLink(v))
                      _resolve(_media.importUrl(v.trim()));
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Or paste an image link',
                    prefixIcon: Icon(Icons.link, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isUsableImageLink(_linkCtrl.text) && !_saving
                    ? () => _resolve(_media.importUrl(_linkCtrl.text.trim()))
                    : null,
                child: const Text('Use'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Photos by Unsplash',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A link is usable if it parses as an absolute http(s) URL. Anything stricter
/// (sniffing for a file extension) rejects the perfectly valid extensionless
/// CDN URLs the photo proxy itself returns.
bool isUsableImageLink(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.selected,
    required this.onTap,
  });

  final PortalImageResult photo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: photo.description ?? 'Photo by ${photo.authorName}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.smallUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => ColoredBox(
                  color:
                      parseHexColor(photo.color) ?? cs.surfaceContainerHighest,
                ),
                errorWidget: (_, _, _) => ColoredBox(
                  color: cs.errorContainer,
                  child: Icon(Icons.broken_image, color: cs.onErrorContainer),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    photo.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.primary, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: cs.primary,
                        child: Icon(Icons.check, size: 14, color: cs.onPrimary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unsplash hands back a `#rrggbb` dominant colour; null when it is missing or
/// malformed, so callers fall back to a theme surface.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  final code = hex.replaceFirst('#', '');
  if (code.length != 6) return null;
  final value = int.tryParse(code, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}
