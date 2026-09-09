import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../../ui/portal_aspect_ratio.dart';
import '../../ui/portal_avatar.dart';
import '../../ui/portal_badge.dart';

class HealthcareMobileScreen extends StatefulWidget {
  const HealthcareMobileScreen({super.key});

  @override
  State<HealthcareMobileScreen> createState() => _HealthcareMobileScreenState();
}

class _HealthcareMobileScreenState extends State<HealthcareMobileScreen> {
  int _navIndex = 0;

  static const _services = [
    (Icons.local_hospital_outlined, 'Clinic Visit', Color(0xFF5B8DEF)),
    (Icons.home_outlined, 'Home Visit', Color(0xFF34C759)),
    (Icons.videocam_outlined, 'Video Consult', Color(0xFFFF9500)),
    (Icons.medication_outlined, 'Pharmacy', Color(0xFFAF52DE)),
    (Icons.coronavirus_outlined, 'Diseases', Color(0xFFFF3B30)),
    (Icons.health_and_safety_outlined, 'Covid-19', Color(0xFF00C7BE)),
  ];

  static const _departments = [
    ('General Care', '12 doctors', Icons.medical_services_outlined),
    ('Pediatrics', '8 doctors', Icons.child_care_outlined),
    ('Cardiologic', '6 doctors', Icons.favorite_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              t.spacing.md,
              t.spacing.md + MediaQuery.paddingOf(context).top,
              t.spacing.md,
              t.spacing.lg,
            ),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(t.radii.xl),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    PortalAvatar(initials: 'KX', size: PortalAvatarSize.md),
                    SizedBox(width: t.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi Kaixa,',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onPrimary.withValues(alpha: 0.85),
                                ),
                          ),
                          Text(
                            'Welcome back!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: cs.onPrimary),
                      onPressed: () {},
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_outlined, color: cs.onPrimary),
                          onPressed: () {},
                        ),
                        const Positioned(
                          right: 8,
                          top: 8,
                          child: PortalBadge(
                            label: '3',
                            variant: PortalBadgeVariant.destructive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(t.spacing.md),
              children: [
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: t.spacing.sm,
                  crossAxisSpacing: t.spacing.sm,
                  childAspectRatio: 0.85,
                  children: [
                    for (final (icon, label, color) in _services)
                      PortalCard(
                        padding: EdgeInsets.all(t.spacing.sm),
                        elevation: PortalCardElevation.soft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(t.spacing.sm),
                                child: Icon(icon, color: color, size: 22),
                              ),
                            ),
                            SizedBox(height: t.spacing.xs),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: t.spacing.lg),
                Text(
                  'Departments',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: t.spacing.sm),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _departments.length,
                    separatorBuilder: (_, __) => SizedBox(width: t.spacing.sm),
                    itemBuilder: (context, index) {
                      final (title, count, icon) = _departments[index];
                      return SizedBox(
                        width: 150,
                        child: PortalCard(
                          elevation: PortalCardElevation.soft,
                          padding: EdgeInsets.all(t.spacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, color: cs.primary, size: 24),
                              const Spacer(),
                              Text(
                                title,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                count,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: portal.onSurfaceVariant,
                                    ),
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
                  'Top Hospitals',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: t.spacing.sm),
                PortalCard(
                  elevation: PortalCardElevation.card,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PortalAspectRatio(
                        aspectRatio: 16 / 7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withValues(alpha: 0.3),
                                cs.tertiary.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.local_hospital, size: 48),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(t.spacing.md),
                        child: Text(
                          'General Doctor — City Medical Center',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Book'),
              NavigationDestination(icon: Icon(Icons.chat_outlined), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}
