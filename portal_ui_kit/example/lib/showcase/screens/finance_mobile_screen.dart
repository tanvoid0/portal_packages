import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../../ui/portal_avatar.dart';
import '../../ui/portal_badge.dart';
import '../../ui/portal_toggle.dart';
import 'showcase_sparkline.dart';

class FinanceMobileScreen extends StatefulWidget {
  const FinanceMobileScreen({super.key});

  @override
  State<FinanceMobileScreen> createState() => _FinanceMobileScreenState();
}

class _FinanceMobileScreenState extends State<FinanceMobileScreen> {
  int _navIndex = 0;
  int _filterIndex = 0;
  bool _balanceVisible = true;

  static const _filters = ['Name', '24h', 'Portfolio'];

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(t.spacing.md),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Have you invested today?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: t.spacing.md),
                  PortalCard(
                    variant: PortalCardVariant.hero,
                    elevation: PortalCardElevation.card,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    padding: EdgeInsets.all(t.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your current balance',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onPrimary.withValues(alpha: 0.85),
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                _balanceVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: cs.onPrimary,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _balanceVisible = !_balanceVisible),
                            ),
                          ],
                        ),
                        Text(
                          _balanceVisible ? '\$235,554' : '••••••',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: t.spacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: PortalButton(
                                label: 'Deposit',
                                size: PortalButtonSize.sm,
                                leading: const Icon(Icons.arrow_upward, size: 16),
                                onPressed: () {},
                              ),
                            ),
                            SizedBox(width: t.spacing.sm),
                            Expanded(
                              child: PortalButton(
                                label: 'Withdraw',
                                variant: PortalButtonVariant.secondary,
                                size: PortalButtonSize.sm,
                                leading: const Icon(Icons.arrow_downward, size: 16),
                                onPressed: () {},
                              ),
                            ),
                            SizedBox(width: t.spacing.sm),
                            Expanded(
                              child: PortalButton(
                                label: 'History',
                                variant: PortalButtonVariant.outline,
                                size: PortalButtonSize.sm,
                                leading: const Icon(Icons.history, size: 16),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: t.spacing.lg),
                  Row(
                    children: [
                      Text(
                        'My Portfolio',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        'See all',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: t.spacing.sm),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => SizedBox(width: t.spacing.sm),
                      itemBuilder: (context, index) {
                        final names = ['USD', 'BNB/USD', 'ETH/USD'];
                        final values = ['\$12,400', '\$8,220', '\$5,100'];
                        return SizedBox(
                          width: 140,
                          child: PortalCard(
                            elevation: PortalCardElevation.soft,
                            padding: EdgeInsets.all(t.spacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  names[index],
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  values[index],
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                ShowcaseSparkline(
                                  color: index.isEven ? Colors.green : cs.primary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: t.spacing.lg),
                  Text(
                    'Trade Crypto',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: t.spacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _filters.length; i++) ...[
                          PortalToggle(
                            pressed: _filterIndex == i,
                            onPressed: () => setState(() => _filterIndex = i),
                            child: Text(_filters[i]),
                          ),
                          SizedBox(width: t.spacing.xs),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: t.spacing.md),
                  ..._tradeRows(context),
                ],
              ),
            ),
            NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: (i) => setState(() => _navIndex = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.show_chart_outlined), label: 'Trade'),
                NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tradeRows(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final assets = [
      ('US Dollar', 'USD', '\$1.00', '+0.01%', true),
      ('Binance Coin', 'BNB', '\$312.40', '+2.4%', true),
      ('Ethereum', 'ETH', '\$2,845', '-1.2%', false),
    ];

    return [
      for (final (name, ticker, price, change, up) in assets) ...[
        Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
          child: Row(
            children: [
              PortalAvatar(initials: ticker.substring(0, 2), size: PortalAvatarSize.sm),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      ticker,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: PortalUiTheme.of(context).onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: Theme.of(context).textTheme.labelLarge),
                  PortalBadge(
                    label: change,
                    variant: up ? PortalBadgeVariant.primary : PortalBadgeVariant.destructive,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ];
  }
}
