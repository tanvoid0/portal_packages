import 'package:flutter/material.dart';

import 'portal_app_identity.dart';
import 'portal_startup_splash.dart';

/// Runs an app's startup steps *after* `runApp`, showing [PortalStartupSplash]
/// while they go.
///
/// Work done before `runApp` happens behind the frozen native splash, where a
/// slow network call looks exactly like a crash. Move that work into [steps]
/// and every second of it is accounted for on screen.
///
/// Steps run in order and each one owns its own results; keep them in locals
/// the [builder] closes over:
///
/// ```dart
/// late AppConfig config;
/// late bool isLoggedIn;
/// runApp(PortalStartupGate(
///   icon: Symbols.shopping_cart_rounded,
///   title: 'Portal Shopping',
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   steps: [
///     PortalStartupStep('Reading your settings', () async {
///       await dotenv.load(fileName: '.env');
///       config = AppConfig.fromEnv().copyWith(appTitle: 'Portal Shopping');
///     }),
///     PortalStartupStep('Checking your session', () async {
///       isLoggedIn = await PortalBootstrap.init(configOverride: config);
///     }),
///   ],
///   builder: (_) => ShoppingApp(config: config, isLoggedIn: isLoggedIn),
/// ));
/// ```
class PortalStartupGate extends StatefulWidget {
  const PortalStartupGate({
    super.key,
    this.identity,
    @Deprecated('Pass identity instead') this.icon,
    @Deprecated('Pass identity instead') this.title,
    required this.steps,
    required this.builder,
    @Deprecated('Pass identity instead') this.subtitle,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.onError,
  }) : assert(
         identity != null || (icon != null && title != null),
         'pass identity, or both icon and title',
       );

  /// The app's mark, name and line, forwarded to [PortalStartupSplash].
  final PortalAppIdentity? identity;

  @Deprecated('Pass identity instead')
  final IconData? icon;
  @Deprecated('Pass identity instead')
  final String? title;
  @Deprecated('Pass identity instead')
  final String? subtitle;

  /// Startup work, run in order. A step that throws stops the run and shows
  /// the failure with a retry that starts again from the first step.
  final List<PortalStartupStep> steps;

  /// The real app, built once every step has finished.
  final WidgetBuilder builder;

  /// Theme for the splash only. The app's own theme takes over in [builder],
  /// so these just keep the splash from flashing default Material colors.
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;

  /// Called when a step throws. Return a trace id to show under the error.
  final String? Function(Object error, StackTrace stack)? onError;

  @override
  State<PortalStartupGate> createState() => _PortalStartupGateState();
}

class _PortalStartupGateState extends State<PortalStartupGate> {
  int _index = 0;
  bool _done = false;
  Object? _error;
  String? _traceId;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _index = 0;
      _error = null;
      _traceId = null;
    });

    for (var i = 0; i < widget.steps.length; i++) {
      if (!mounted) return;
      setState(() => _index = i);
      try {
        await widget.steps[i].run();
      } catch (e, st) {
        final traceId = widget.onError?.call(e, st);
        if (!mounted) return;
        setState(() {
          _error = e;
          _traceId = traceId;
        });
        return;
      }
    }

    if (!mounted) return;
    // Bumped past the last step so the bar reads full for the frame before
    // the app replaces it.
    setState(() {
      _index = widget.steps.length;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.builder(context);

    final steps = widget.steps;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: widget.theme,
      darkTheme: widget.darkTheme,
      themeMode: widget.themeMode,
      home: PortalStartupSplash(
        identity: widget.identity,
        // ignore: deprecated_member_use_from_same_package
        icon: widget.icon,
        // ignore: deprecated_member_use_from_same_package
        title: widget.title,
        // ignore: deprecated_member_use_from_same_package
        subtitle: widget.subtitle,
        stepCount: steps.length,
        stepIndex: _index,
        stepLabel: _index < steps.length ? steps[_index].label : 'Ready',
        error: _error,
        traceId: _traceId,
        onRetry: _error != null ? _run : null,
      ),
    );
  }
}
