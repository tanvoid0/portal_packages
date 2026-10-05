import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// The G5 reference screens, with realistic content: what the components are
/// for. Each is a recipe over G1-G4, not a new atom. The goldens in
/// `test/screens_golden_test.dart` draw them in light and dark at 1.0 and 1.3
/// text scale, so a token change shows what it did.
class ScreensPage extends StatelessWidget {
  const ScreensPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalScrollPage(
      title: 'Screens',
      subtitle: 'G5 references',
      children: [
        PortalListSection(
          header: 'Recipes',
          children: [
            for (final (title, subtitle, icon, builder) in _screens)
              PortalListItem(
                title: title,
                subtitle: subtitle,
                leading: PortalListLeading.tile(icon),
                trailing: const PortalListAccessory.navigate(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: builder),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

final List<(String, String, IconData, WidgetBuilder)> _screens = [
  ('Transactions', 'Detail recipe: hero amount, sections', Icons.receipt_long_outlined,
      (_) => const TransactionsScreen()),
  ('Settings', 'Settings recipe: inset sections of rows', Icons.settings_outlined,
      (_) => const SettingsScreen()),
  ('Edit profile', 'Form recipe: fields, prompt, dock', Icons.edit_outlined,
      (_) => const EditFormScreen()),
  ('Result', 'PortalResultScreen: error with retry', Icons.error_outline,
      (_) => const ResultDemoScreen()),
];

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final f = PortalFormat.of(context);
    return PortalScrollPage(
      title: 'Spending',
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.lg),
          child: const PortalAmount(
            1284.5,
            'GBP',
            size: PortalAmountSize.hero,
            delta: PortalAmountDelta(
              icon: Icons.trending_down,
              text: '-8% on August',
            ),
          ),
        ),
        PortalPrompt(
          sentiment: PortalSentiment.warning,
          title: 'Groceries is 92% spent',
          message: 'About £18 a day left until the 30th.',
          onDismiss: () {},
        ),
        PortalListSection(
          header: 'Today',
          children: [
            _tx(f, 'Salary', 'Acme Ltd', Icons.payments_outlined, 2450),
            _tx(f, 'Tesco Express', 'Groceries', Icons.shopping_basket_outlined, -24.6),
          ],
        ),
        PortalListSection(
          header: 'Yesterday',
          children: [
            _tx(f, 'Refund, Uniqlo', 'Clothes', Icons.undo, 19.99),
            _tx(f, 'Rent', 'Home', Icons.home_outlined, -1150),
          ],
        ),
      ],
    );
  }

  /// Money in is signed and green; money out stays ink with a hyphen-minus.
  PortalListItem _tx(
    PortalFormat f,
    String title,
    String subtitle,
    IconData icon,
    num amount,
  ) =>
      PortalListItem(
        title: title,
        subtitle: subtitle,
        leading: PortalListLeading.tile(icon),
        trailing: PortalListAccessory.value(
          f.signed(amount, 'GBP'),
          sentiment: amount > 0
              ? PortalValueSentiment.positive
              : PortalValueSentiment.neutral,
        ),
      );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _lock = true;
  var _sync = false;

  @override
  Widget build(BuildContext context) {
    return PortalScrollPage(
      title: 'Settings',
      children: [
        PortalListSection(
          children: [
            PortalListItem(
              title: 'Alex Morgan',
              subtitle: 'alex@example.com',
              leading: PortalListLeading.avatar('AM', large: true),
              trailing: const PortalListAccessory.navigate(),
              onTap: () {},
            ),
          ],
        ),
        PortalListSection(
          header: 'Privacy',
          children: [
            PortalListItem(
              title: 'Lock the app',
              subtitle: 'Ask for your fingerprint on open',
              leading: PortalListLeading.tile(Icons.lock_outline),
              trailing: PortalListAccessory.switchControl(
                checked: _lock,
                onChanged: (v) => setState(() => _lock = v),
              ),
            ),
            PortalListItem(
              title: 'Sync over mobile data',
              leading: PortalListLeading.tile(Icons.sync),
              disabledReason: 'Sign in to turn on sync',
              trailing: PortalListAccessory.switchControl(
                checked: _sync,
                onChanged: (v) => setState(() => _sync = v),
              ),
            ),
          ],
        ),
        PortalListSection(
          header: 'Appearance',
          children: [
            PortalListItem(
              title: 'Theme',
              trailing: const PortalListAccessory.navigate(value: 'System'),
              onTap: () {},
            ),
            PortalListItem(
              title: 'Text size',
              trailing: const PortalListAccessory.navigate(value: 'Default'),
              onTap: () {},
            ),
          ],
        ),
        const PortalListSection(
          header: 'About',
          detail: true,
          children: [
            PortalListItem(
              title: 'Version',
              trailing: PortalListAccessory.value('2.4.0'),
            ),
            PortalListItem(
              title: 'Storage',
              trailing: PortalListAccessory.value('586 MB'),
            ),
          ],
        ),
      ],
    );
  }
}

class EditFormScreen extends StatefulWidget {
  const EditFormScreen({super.key});

  @override
  State<EditFormScreen> createState() => _EditFormScreenState();
}

class _EditFormScreenState extends State<EditFormScreen> {
  final _email = TextEditingController(text: 'alex@example');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = PortalUiTheme.of(context).tokens.spacing;
    return PortalScrollPage(
      title: 'Edit profile',
      bottom: PortalButtonDock(
        primary: PortalButton(
          label: 'Save changes',
          size: PortalButtonSize.lg,
          onPressed: () {},
        ),
        secondary: PortalButton(
          label: 'Cancel',
          variant: PortalButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Name')),
        SizedBox(height: sp.lg),
        TextField(
          controller: _email,
          // The inline prompt takes the helper slot under the field: one per
          // field, and the field draws its own error edge.
          decoration: const InputDecoration(
            labelText: 'Email',
            error: PortalPrompt(
              message: 'Enter a full address, like alex@example.com',
              sentiment: PortalSentiment.negative,
              size: PortalPromptSize.inline,
            ),
          ),
        ),
      ],
    );
  }
}

class ResultDemoScreen extends StatelessWidget {
  const ResultDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalResultScreen(
      state: PortalResultState.error,
      title: 'Payment not sent',
      body: 'Check your connection, then try again. Nothing was charged.',
      art: const Icon(Icons.cloud_off, size: 72),
      onClose: () => Navigator.of(context).maybePop(),
      dock: PortalButtonDock(
        primary: PortalButton(
          label: 'Retry',
          size: PortalButtonSize.lg,
          onPressed: () {},
        ),
        secondary: PortalButton(
          label: 'Save as draft',
          variant: PortalButtonVariant.ghost,
          onPressed: () {},
        ),
      ),
    );
  }
}
