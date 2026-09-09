import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../../ui/portal_avatar.dart';
import '../../ui/portal_badge.dart';

class SocialMobileScreen extends StatefulWidget {
  const SocialMobileScreen({super.key});

  @override
  State<SocialMobileScreen> createState() => _SocialMobileScreenState();
}

class _SocialMobileScreenState extends State<SocialMobileScreen> {
  int _navIndex = 0;

  static const _stories = ['Alex', 'Sam', 'Jordan', 'Riley'];

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Home'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
        children: [
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
              children: [
                _StoryAddTile(),
                for (final name in _stories) ...[
                  SizedBox(width: t.spacing.sm),
                  _StoryTile(name: name),
                ],
              ],
            ),
          ),
          SizedBox(height: t.spacing.md),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
            child: PortalCard(
              elevation: PortalCardElevation.soft,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(t.spacing.md),
                    child: Row(
                      children: [
                        PortalAvatar(initials: 'MN', size: PortalAvatarSize.sm),
                        SizedBox(width: t.spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Manny',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: t.spacing.xs),
                                  const PortalBadge(
                                    label: 'Verified',
                                    variant: PortalBadgeVariant.primary,
                                  ),
                                ],
                              ),
                              Text(
                                '4m ago',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: portal.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
                    child: Text(
                      'Exploring new design patterns with Portal UI Kit — clean cards, '
                      'rounded corners, and thoughtful spacing.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  SizedBox(height: t.spacing.md),
                  AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary.withValues(alpha: 0.25),
                            cs.secondary.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: cs.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(t.spacing.md),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      t.spacing.md,
                      0,
                      t.spacing.md,
                      t.spacing.md,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          height: 24,
                          child: Stack(
                            children: [
                              Positioned(left: 0, child: PortalAvatar(initials: 'AB', size: PortalAvatarSize.sm)),
                              Positioned(left: 16, child: PortalAvatar(initials: 'CD', size: PortalAvatarSize.sm)),
                              Positioned(left: 32, child: PortalAvatar(initials: 'EF', size: PortalAvatarSize.sm)),
                            ],
                          ),
                        ),
                        SizedBox(width: t.spacing.sm),
                        Text(
                          'Liked by Alex and 42 others',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: portal.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StoryAddTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(t.radii.md),
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.add, color: cs.primary),
            ),
          ),
          SizedBox(height: t.spacing.xs),
          Text('Your Story', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary, width: 2),
            ),
            child: PortalAvatar(initials: name.substring(0, 2), size: PortalAvatarSize.md),
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
