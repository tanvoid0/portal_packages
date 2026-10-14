import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../clients/ollama_model_manager.dart';
import '../clients/openai_compatible_completion_client.dart';
import '../discovery/ai_backend_discovery.dart';
import '../local/local_llm_engine.dart';
import '../discovery/ollama_lan_scan.dart';
import '../models/ai_backend_kind.dart';
import '../models/ai_backend_labels.dart';
import '../models/ai_backend_option.dart';
import '../models/ai_backend_option_models.dart';
import '../models/ai_model_manager.dart';
import '../models/ai_routing_mode.dart';
import '../platform/edge_gallery_launcher.dart';
import '../platform/portal_ai_platform.dart';
import '../prefs/ai_backend_store.dart';
import 'ai_models_page.dart';

/// The whole AI group for a settings screen: which provider, which of that
/// provider's models, and the one setting a provider needs to be reachable.
///
/// Drop it into `PortalSettingsPage(aiSection: ...)`. Every model name shown
/// comes from the provider itself — Ollama's tags, the platform's own report
/// of the device model, and `.env` for Gemini, which is the only list this
/// codebase writes down.
class AiSettingsSection extends StatefulWidget {
  const AiSettingsSection({
    super.key,
    required this.store,
    this.onChanged,
    this.labels = const AiBackendLabels(),
    this.discovery,
    this.cloudEligible = true,
    this.showModelConfig = true,
    this.trailingBuilder,
    this.onRescan,
    this.hasServer = false,
    this.localLlm,
    this.showRouting = true,
  });

  final AiBackendStore store;

  /// Fires whenever the selected provider or its model changes, so the app can
  /// re-point its `PortalAiRuntime` without a restart.
  final ValueChanged<AiBackendOption>? onChanged;

  final AiBackendLabels labels;
  final AiBackendDiscovery? discovery;
  final bool cloudEligible;

  /// False renders the provider list alone, which is what [AiBackendSelector]
  /// asks for.
  final bool showModelConfig;

  /// Whether this app has a Portal server transport at all. The routing
  /// control (server vs. local, or both) is meaningless without one -- there
  /// is nothing to route between -- so it stays hidden until the host says a
  /// server exists.
  final bool hasServer;

  /// False hides the routing control even with [hasServer], for a host that
  /// shows routing as a row of its own ([AiSettingsGroup]).
  final bool showRouting;

  final Widget? Function(AiBackendOption option)? trailingBuilder;
  final VoidCallback? onRescan;

  /// The in-process inference engine, in an app that bundles one. Supplying
  /// it here is what puts the on-device provider in the list and gives its
  /// row a Models button; without it the row is absent.
  final LocalLlmEngine? localLlm;

  /// Opens shared preferences and builds the store, for an app that has no
  /// [AiBackendStore] of its own to hand in.
  ///
  /// Warms the secure-storage-backed API key here too: this is the store an
  /// app hands straight to `PortalAiRuntime.create` at boot, and that read is
  /// sync-only (see [AiBackendStore.openAiApiKey]) -- without this, the
  /// runtime built before AI settings is ever opened sends an empty key and
  /// gets a 401 from a provider the user already configured.
  static Future<AiBackendStore> openStore(String keyPrefix) async {
    final store = AiBackendStore(
      prefs: await SharedPreferences.getInstance(),
      keyPrefix: keyPrefix,
    );
    await store.loadOpenAiApiKey();
    return store;
  }

  @override
  State<AiSettingsSection> createState() => _AiSettingsSectionState();
}

class _AiSettingsSectionState extends State<AiSettingsSection> {
  late final AiBackendDiscovery _discovery;
  List<AiBackendOption> _options = const [];
  AiBackendKind? _selected;
  bool _loading = true;
  bool _downloading = false;
  bool _scanningLan = false;
  bool _lanScanFailed = false;

  @override
  void initState() {
    super.initState();
    _discovery =
        widget.discovery ?? AiBackendDiscovery(localLlm: widget.localLlm);
    _scan();
  }

  AiBackendOption? get _selectedOption {
    for (final option in _options) {
      if (option.kind == _selected) return option;
    }
    return null;
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    final options = await _discovery.discover(
      cloudEligible: widget.cloudEligible,
      ollamaHost: widget.store.ollamaHost,
      openAiBaseUrl: widget.store.openAiBaseUrl,
      openAiModel: widget.store.modelFor(AiBackendKind.openAiCompatible) ?? '',
    );
    final kind = await widget.store.resolveSelectedKind(options);
    if (!mounted) return;
    setState(() {
      _options = options;
      _selected = kind;
      _loading = false;
    });
  }

  Future<void> _select(AiBackendOption option) async {
    if (!option.available) return;
    await widget.store.setSelectedKind(option.kind);
    if (option.supportsInAppInference) {
      await widget.store.ensureModelFor(option);
    }
    if (!mounted) return;
    setState(() => _selected = option.kind);
    widget.onChanged?.call(option);
    // Edge Gallery is not an in-app backend: picking it means "take me there".
    if (option.kind == AiBackendKind.edgeGalleryDelegate) {
      await EdgeGalleryLauncher.launch();
    }
  }

  Future<void> _setModel(AiBackendKind kind, String model) async {
    await widget.store.setModelFor(kind, model);
    if (!mounted) return;
    setState(() {});
    final option = _selectedOption;
    if (option != null) widget.onChanged?.call(option);
  }

  /// Sweeps the network for a daemon and adopts the first one found.
  ///
  /// The desktop running Ollama is on the same wifi but on an address the user
  /// has no reason to know, and the default host is the emulator alias, which
  /// is nowhere on a real phone. Without this the provider looks broken until
  /// someone goes and reads their router's DHCP table.
  Future<void> _findOllama() async {
    setState(() {
      _scanningLan = true;
      _lanScanFailed = false;
    });
    final found = await OllamaLanScan.find();
    if (!mounted) return;
    if (found == null) {
      setState(() {
        _scanningLan = false;
        _lanScanFailed = true;
      });
      return;
    }
    await widget.store.setOllamaHost(found);
    if (!mounted) return;
    setState(() => _scanningLan = false);
    await _scan();
  }

  /// The backends that keep model files of their own get one shared page.
  /// Ollama's host can change between builds of this widget, so its manager
  /// is built per call rather than held.
  AiModelManager? _managerFor(AiBackendOption option) => switch (option.kind) {
    AiBackendKind.ollama =>
      option.available
          ? OllamaModelManager(baseUrl: widget.store.ollamaHost)
          : null,
    AiBackendKind.localLlm => widget.localLlm,
    _ => null,
  };

  Future<void> _manageModels(AiModelManager manager) async {
    final changed = await AiModelsPage.open(
      context,
      manager: manager,
      labels: widget.labels,
    );
    if (!changed || !mounted) return;
    await _scan();
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    await PortalAiPlatform.downloadSystemAi();
    if (!mounted) return;
    setState(() => _downloading = false);
    await _scan();
  }

  /// The app's trailing widget wins; otherwise a device model that is
  /// supported but not yet fetched gets a download button, so that row is one
  /// tap from working instead of a dead "unavailable".
  Widget? _trailingFor(AiBackendOption option) {
    final custom = widget.trailingBuilder?.call(option);
    if (custom != null) return custom;
    if (option.kind == AiBackendKind.systemOnDevice) {
      if (option.metadata['downloadable'] != true) return null;
      return _DownloadButton(
        busy: _downloading,
        labels: widget.labels,
        onPressed: _download,
      );
    }
    final manager = _managerFor(option);
    if (manager == null) return null;
    return PortalButton(
      label: widget.labels.manageModels,
      size: PortalButtonSize.sm,
      variant: PortalButtonVariant.ghost,
      onPressed: () => _manageModels(manager),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;

    if (_loading) {
      return PortalListSection.skeleton(hasHeader: true, rows: 2);
    }

    final inference = _options.where((o) => o.supportsInAppInference).toList();
    final delegates = _options.where((o) => !o.supportsInAppInference).toList();

    if (inference.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: PortalPrompt(
          size: PortalPromptSize.compact,
          sentiment: PortalSentiment.warning,
          message: labels.noProviders,
        ),
      );
    }

    int? indexOf(List<AiBackendOption> list) {
      final i = list.indexWhere((o) => o.kind == _selected);
      return i < 0 ? null : i;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalListSection.selectable(
          header: labels.selectProvider,
          selected: indexOf(inference),
          children: [for (final option in inference) _tile(option)],
        ),
        // Each provider's settings sit directly under the list. A phone that
        // cannot see Ollama yet still needs its address field, and that row is
        // disabled -- so hiding the field behind "is selected" leaves the one
        // control that would fix it unreachable. Actions live here too, not in
        // the row: a disabled row is inert, and a download is for exactly the
        // provider that is not ready yet.
        for (final option in inference) ..._extrasFor(option),
        if (delegates.isNotEmpty)
          PortalListSection.selectable(
            header: labels.external,
            selected: indexOf(delegates),
            children: [for (final option in delegates) _tile(option)],
          ),
        for (final option in delegates) ..._extrasFor(option),
        if (widget.hasServer &&
            widget.showRouting &&
            widget.showModelConfig) ...[
          _gutter(PortalSectionHeader(title: labels.routingTitle)),
          _RoutingModeControl(
            labels: labels,
            mode: widget.store.routingMode,
            onChanged: (mode) async {
              await widget.store.setRoutingMode(mode);
              if (!mounted) return;
              setState(() {});
              // Nothing about the selected backend moved, but routing mode
              // alone changes what the runtime should be running --
              // `applyBackend` re-resolves from the store as a whole
              // (routing mode included), not just from this option, so
              // re-firing it here is the same path a backend switch takes.
              final opt = _selectedOption;
              if (opt != null) widget.onChanged?.call(opt);
            },
          ),
        ],
        _gutter(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PortalButton(
              label: labels.rescan,
              size: PortalButtonSize.sm,
              variant: PortalButtonVariant.ghost,
              onPressed: () {
                widget.onRescan?.call();
                _scan();
              },
            ),
          ),
        ),
      ],
    );
  }

  /// A bare header or button has no page gutter of its own (the list sections
  /// draw theirs); line it up with the form rows beneath it.
  Widget _gutter(Widget child) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: PortalUiTheme.of(context).tokens.layout.pageHorizontal,
    ),
    child: child,
  );

  PortalListItem _tile(AiBackendOption option) {
    final labels = widget.labels;
    final description = labels.descriptionFor(option.kind);
    final highlighted = option.kind == _selected && option.available;
    return PortalListItem(
      title: labels.titleFor(option.kind),
      titleMaxLines: 2,
      subtitle: option.available
          ? [description, ?option.modelsSummary].join('\n')
          : null,
      leading: PortalListLeading.tile(labels.iconFor(option.kind)),
      disabledReason: option.available
          ? null
          : (option.unavailableReason ?? labels.unavailable),
      // Words, not colour alone: the radio dot is not the only mark.
      chips: [
        if (highlighted)
          PortalBadge(
            label: labels.selectedBadge,
            tone: PortalBadgeTone.primary,
          )
        else if (!option.available)
          PortalBadge(label: labels.unavailable, tone: PortalBadgeTone.danger),
      ],
      trailing: PortalListAccessory.radio(
        checked: option.kind == _selected,
        onChanged: option.available ? (_) => _select(option) : null,
      ),
    );
  }

  /// What sits under the list for [option]: its action, then its settings.
  List<Widget> _extrasFor(AiBackendOption option) {
    final trailing = _trailingFor(option);
    final config = widget.showModelConfig
        ? _configFor(option)
        : const <Widget>[];
    if (trailing == null && config.isEmpty) return const [];
    return [
      _gutter(PortalSectionHeader(title: widget.labels.titleFor(option.kind))),
      PortalFormStack(
        children: [
          if (trailing != null)
            Align(alignment: AlignmentDirectional.centerStart, child: trailing),
          ...config,
        ],
      ),
    ];
  }

  /// Settings belonging to [option].
  ///
  /// The model dropdown is for the selected provider only — a settings page
  /// listing every provider's models at once is noise. Ollama's address is the
  /// exception: it is what makes the provider selectable in the first place.
  List<Widget> _configFor(AiBackendOption option) {
    final labels = widget.labels;
    final selected = option.kind == _selected;
    final widgets = <Widget>[];

    if (option.kind == AiBackendKind.ollama &&
        (selected || !option.available)) {
      widgets.addAll([
        _OllamaHostField(
          // Keyed on the host so a value found by the scan replaces what is in
          // the field, rather than the old text outliving the state it came
          // from.
          key: ValueKey('ollama-host-${widget.store.ollamaHost}'),
          initial: widget.store.ollamaHost,
          label: labels.ollamaHost,
          onSubmitted: (host) async {
            await widget.store.setOllamaHost(host);
            await _scan();
          },
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PortalButton(
            label: labels.findOllama,
            busyLabel: labels.searchingOllama,
            isLoading: _scanningLan,
            size: PortalButtonSize.sm,
            variant: PortalButtonVariant.secondary,
            leading: const Icon(Icons.wifi_find_outlined),
            onPressed: _findOllama,
          ),
        ),
        if (_lanScanFailed)
          PortalPrompt(
            size: PortalPromptSize.inline,
            sentiment: PortalSentiment.negative,
            message: labels.ollamaNotFound,
          ),
      ]);
    }

    // Free-typed base URL and model rather than a dropdown from a probe --
    // there is no daemon to ask, only what the user (or a preset) fills in.
    if (option.kind == AiBackendKind.openAiCompatible &&
        (selected || !option.available)) {
      widgets.add(
        _OpenAiCompatibleFields(
          // No key tied to a store value: unlike Ollama's host, nothing
          // outside this widget ever changes the base URL, so remounting on
          // it only ever meant losing whatever the user had not submitted
          // yet in the *other* fields (model, key) when the preset dropdown
          // wrote a new base URL.
          store: widget.store,
          labels: labels,
          onSubmitted: () async {
            await _scan();
            if (!mounted) return;
            final opt = _selectedOption;
            if (opt != null) widget.onChanged?.call(opt);
          },
        ),
      );
      return widgets;
    }

    if (!selected || !option.supportsInAppInference) return widgets;

    final stored = widget.store.modelFor(option.kind);
    if (option.models.isNotEmpty) {
      widgets.add(
        PortalSelect<String>(
          key: ValueKey(
            'ai-model-${option.models.contains(stored) ? stored : option.models.first}',
          ),
          label: labels.model,
          items: [
            for (final m in option.models) PortalSelectItem(value: m, label: m),
          ],
          // A stored model the provider no longer lists must not become the
          // dropdown's value, or Flutter asserts on a missing item.
          value: option.models.contains(stored) ? stored : option.models.first,
          onChanged: (model) {
            if (model != null) _setModel(option.kind, model);
          },
        ),
      );
    } else if (option.kind == AiBackendKind.systemOnDevice) {
      widgets.add(
        PortalPrompt(size: PortalPromptSize.inline, message: labels.noModels),
      );
    }
    return widgets;
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.busy,
    required this.onPressed,
    required this.labels,
  });

  final bool busy;
  final VoidCallback onPressed;
  final AiBackendLabels labels;

  @override
  Widget build(BuildContext context) => PortalButton(
    label: labels.download,
    busyLabel: labels.downloading,
    isLoading: busy,
    size: PortalButtonSize.sm,
    variant: PortalButtonVariant.secondary,
    onPressed: onPressed,
  );
}

class _OllamaHostField extends StatefulWidget {
  const _OllamaHostField({
    super.key,
    required this.initial,
    required this.label,
    required this.onSubmitted,
  });

  final String initial;
  final String label;
  final ValueChanged<String> onSubmitted;

  @override
  State<_OllamaHostField> createState() => _OllamaHostFieldState();
}

class _OllamaHostFieldState extends State<_OllamaHostField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PortalTextField(
      controller: _controller,
      label: widget.label,
      hint: defaultOllamaBaseUrl,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
    );
  }
}

/// Server vs. local backend, when there is a choice to make.
class _RoutingModeControl extends StatelessWidget {
  const _RoutingModeControl({
    required this.labels,
    required this.mode,
    required this.onChanged,
  });

  final AiBackendLabels labels;
  final AiRoutingMode mode;
  final ValueChanged<AiRoutingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalSegmentedTabs(
          labels: [
            for (final m in AiRoutingMode.values) labels.routingLabelFor(m),
          ],
          index: AiRoutingMode.values.indexOf(mode),
          semanticLabel: labels.routingTitle,
          onChanged: (i) => onChanged(AiRoutingMode.values[i]),
        ),
        const SizedBox(height: 4),
        Text(
          labels.routingDescriptionFor(mode),
          style: PortalUiTheme.of(context).tokens.textStyles.caption,
        ),
      ],
    );
  }
}

/// Preset, base URL, model and API key for [AiBackendKind.openAiCompatible],
/// plus a Test button that probes the values as they currently stand.
class _OpenAiCompatibleFields extends StatefulWidget {
  const _OpenAiCompatibleFields({
    required this.store,
    required this.labels,
    required this.onSubmitted,
  });

  final AiBackendStore store;
  final AiBackendLabels labels;
  final VoidCallback onSubmitted;

  @override
  State<_OpenAiCompatibleFields> createState() =>
      _OpenAiCompatibleFieldsState();
}

class _OpenAiCompatibleFieldsState extends State<_OpenAiCompatibleFields> {
  late final TextEditingController _baseUrlController = TextEditingController(
    text: widget.store.openAiBaseUrl,
  );
  late final TextEditingController _modelController = TextEditingController(
    text: widget.store.modelFor(AiBackendKind.openAiCompatible) ?? '',
  );
  late final TextEditingController _apiKeyController = TextEditingController(
    text: widget.store.openAiApiKey,
  );
  final FocusNode _baseUrlFocus = FocusNode();
  final FocusNode _modelFocus = FocusNode();
  final FocusNode _apiKeyFocus = FocusNode();
  bool _testing = false;
  bool? _testOk;

  @override
  void initState() {
    super.initState();
    // Secure storage has no synchronous read -- a key set in an earlier run
    // is not in the field until this resolves.
    widget.store.loadOpenAiApiKey().then((_) {
      if (!mounted || _apiKeyController.text.isNotEmpty) return;
      final key = widget.store.openAiApiKey;
      if (key.isNotEmpty) setState(() => _apiKeyController.text = key);
    });
    // Submitting (keyboard "done") is not the only way to leave a field --
    // tapping Test or another field is losing focus just as much, and a
    // paste-then-tap-Test used to leave the store holding the old value.
    _baseUrlFocus.addListener(_onBaseUrlFocusChange);
    _modelFocus.addListener(_onModelFocusChange);
    _apiKeyFocus.addListener(_onApiKeyFocusChange);
  }

  @override
  void dispose() {
    _baseUrlFocus.removeListener(_onBaseUrlFocusChange);
    _modelFocus.removeListener(_onModelFocusChange);
    _apiKeyFocus.removeListener(_onApiKeyFocusChange);
    _baseUrlFocus.dispose();
    _modelFocus.dispose();
    _apiKeyFocus.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onBaseUrlFocusChange() {
    if (!_baseUrlFocus.hasFocus) _saveBaseUrl();
  }

  void _onModelFocusChange() {
    if (!_modelFocus.hasFocus) _saveModel();
  }

  void _onApiKeyFocusChange() {
    if (!_apiKeyFocus.hasFocus) _saveApiKey();
  }

  Future<void> _saveBaseUrl() async {
    await widget.store.setOpenAiBaseUrl(_baseUrlController.text);
    widget.onSubmitted();
  }

  Future<void> _saveModel() async {
    await widget.store.setModelFor(
      AiBackendKind.openAiCompatible,
      _modelController.text,
    );
    widget.onSubmitted();
  }

  /// Writes the key to secure storage. That write can genuinely fail (unlike
  /// the plain-prefs fields above) -- caught here and surfaced as a SnackBar
  /// rather than swallowed, so a paste that silently did not save is not
  /// mistaken for one that did.
  Future<void> _saveApiKey() async {
    try {
      await widget.store.setOpenAiApiKey(_apiKeyController.text);
      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.labels.openAiApiKeySaveFailed}: $e')),
      );
    }
  }

  OpenAiCompatiblePreset? _presetForLabel(String? label) {
    for (final preset in openAiCompatiblePresets) {
      if (preset.label == label) return preset;
    }
    return null;
  }

  OpenAiCompatiblePreset? _presetForBaseUrl(String baseUrl) {
    for (final preset in openAiCompatiblePresets) {
      if (preset.baseUrl == baseUrl) return preset;
    }
    return null;
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testOk = null;
    });
    // Test probes (and leaves persisted) exactly what is on screen, not
    // whatever was last submitted -- a pasted key never reaches here
    // otherwise, since typing alone does not write to the store.
    await _saveBaseUrl();
    await _saveModel();
    await _saveApiKey();
    final client = OpenAiCompatibleCompletionClient(
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
      apiKey: _apiKeyController.text,
    );
    final ok = await client.isAvailable();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final currentPreset = _presetForBaseUrl(_baseUrlController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PortalUiTheme.of(context).tokens.spacing.lg,
      children: [
        PortalSelect<String>(
          value: currentPreset?.label,
          label: labels.openAiPreset,
          // No item for "custom": it is what shows when the URL matches none.
          hint: labels.openAiCustomPreset,
          items: [
            for (final preset in openAiCompatiblePresets)
              PortalSelectItem(value: preset.label, label: preset.label),
          ],
          onChanged: (label) {
            final preset = _presetForLabel(label);
            if (preset == null) return;
            setState(() => _baseUrlController.text = preset.baseUrl);
            _saveBaseUrl();
          },
        ),
        PortalTextField(
          controller: _baseUrlController,
          focusNode: _baseUrlFocus,
          label: labels.openAiBaseUrl,
          keyboardType: TextInputType.url,
          onSubmitted: (_) => _saveBaseUrl(),
        ),
        PortalTextField(
          controller: _modelController,
          focusNode: _modelFocus,
          label: labels.model,
          onSubmitted: (_) => _saveModel(),
        ),
        PortalTextField(
          controller: _apiKeyController,
          focusNode: _apiKeyFocus,
          label: labels.openAiApiKey,
          obscureText: true,
          obscureToggle: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveApiKey(),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PortalButton(
            label: labels.openAiTest,
            size: PortalButtonSize.sm,
            variant: PortalButtonVariant.secondary,
            isLoading: _testing,
            onPressed: _test,
          ),
        ),
        if (_testOk != null)
          PortalPrompt(
            size: PortalPromptSize.inline,
            sentiment: _testOk!
                ? PortalSentiment.positive
                : PortalSentiment.negative,
            message: _testOk! ? labels.openAiTestOk : labels.openAiTestFail,
          ),
      ],
    );
  }
}
