import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../../ui/portal_alert.dart';
import '../../ui/portal_badge.dart';
import '../../ui/portal_breadcrumb.dart';
import '../../ui/portal_progress.dart';
import '../../ui/portal_sidebar.dart';
import '../../ui/portal_table.dart';
import '../../ui/portal_tabs.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _sidebarIndex = 0;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortalSidebar(
            width: 200,
            selectedIndex: _sidebarIndex,
            onSelected: (i) => setState(() => _sidebarIndex = i),
            header: Row(
              children: [
                Icon(Icons.dashboard_customize_outlined, color: cs.primary, size: 20),
                SizedBox(width: t.spacing.sm),
                Text(
                  'Portal Admin',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            items: const [
              PortalSidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
              PortalSidebarItem(label: 'Projects', icon: Icons.folder_outlined, badge: '3'),
              PortalSidebarItem(label: 'Analytics', icon: Icons.bar_chart_outlined),
              PortalSidebarItem(label: 'Settings', icon: Icons.settings_outlined),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(t.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PortalBreadcrumb(
                    items: const [
                      PortalBreadcrumbItem(label: 'Home'),
                      PortalBreadcrumbItem(label: 'Dashboard'),
                    ],
                  ),
                  SizedBox(height: t.spacing.lg),
                  PortalTabs(
                    tabViewHeight: 420,
                    tabs: const ['Overview', 'Analytics'],
                    children: [
                      _OverviewTab(),
                      Center(
                        child: Text(
                          'Analytics charts would appear here.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: portal.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: _StatCard(title: 'Revenue', value: '\$48,290', change: '+12%', up: true)),
              SizedBox(width: t.spacing.md),
              const Expanded(child: _StatCard(title: 'Users', value: '2,847', change: '+8%', up: true)),
              SizedBox(width: t.spacing.md),
              const Expanded(child: _StatCard(title: 'Orders', value: '1,204', change: '-3%', up: false)),
              SizedBox(width: t.spacing.md),
              const Expanded(child: _StatCard(title: 'Conversion', value: '4.2%', change: '+0.5%', up: true)),
            ],
          ),
          SizedBox(height: t.spacing.lg),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: t.spacing.sm),
          PortalTable(
            columns: const ['User', 'Action', 'Status', 'Time'],
            rows: const [
              ['Alex Chen', 'Created project', 'Active', '2m ago'],
              ['Sam Rivera', 'Updated settings', 'Pending', '15m ago'],
              ['Jordan Lee', 'Deployed v2.1', 'Complete', '1h ago'],
              ['Riley Park', 'Invited member', 'Active', '3h ago'],
            ],
          ),
          SizedBox(height: t.spacing.lg),
          const PortalAlert(
            title: 'System notice',
            description: 'Scheduled maintenance tonight at 2:00 AM UTC.',
            variant: PortalAlertVariant.primary,
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.up,
  });

  final String title;
  final String value;
  final String change;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return PortalCard(
      elevation: PortalCardElevation.soft,
      padding: EdgeInsets.all(t.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: portal.onSurfaceVariant,
                ),
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: t.spacing.sm),
          Row(
            children: [
              PortalBadge(
                label: change,
                variant: up ? PortalBadgeVariant.primary : PortalBadgeVariant.destructive,
              ),
              const Spacer(),
              SizedBox(
                width: 48,
                child: PortalProgress(value: up ? 0.72 : 0.35),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
