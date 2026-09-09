import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../ui/portal_accordion.dart';
import '../ui/portal_alert.dart';
import '../ui/portal_aspect_ratio.dart';
import '../ui/portal_avatar.dart';
import '../ui/portal_badge.dart';
import '../ui/portal_breadcrumb.dart';
import '../ui/portal_calendar.dart';
import '../ui/portal_checkbox.dart';
import '../ui/portal_collapsible.dart';
import '../ui/portal_command.dart';
import '../ui/portal_dialog.dart';
import '../ui/portal_divider.dart';
import '../ui/portal_dropdown_menu.dart';
import '../ui/portal_combobox.dart';
import '../ui/portal_form.dart';
import '../ui/portal_input_otp.dart';
import '../ui/portal_popover.dart';
import '../ui/portal_sidebar.dart';
import '../ui/portal_label.dart';
import '../ui/portal_pagination.dart';
import '../ui/portal_progress.dart';
import '../ui/portal_radio_group.dart';
import '../ui/portal_scroll_area.dart';
import '../ui/portal_select.dart';
import '../ui/portal_separator.dart';
import '../ui/portal_sheet.dart';
import '../ui/portal_slidable.dart';
import '../ui/portal_slider.dart';
import '../ui/portal_spinner.dart';
import '../ui/portal_switch.dart';
import '../ui/portal_table.dart';
import '../ui/portal_tabs.dart';
import '../ui/portal_text_area.dart';
import '../ui/portal_text_field.dart';
import '../ui/portal_toggle.dart';
import '../ui/portal_tooltip.dart';

/// Live previews keyed by [ComponentEntry.id].
final Map<String, WidgetBuilder> kPreviewBuilders = {
  'portal_accordion': (context) {
    return PortalAccordion(
      initiallyExpandedIndex: 0,
      sections: [
        PortalAccordionSection(
          title: 'Shipping',
          child: Text('Free over \$50.', style: Theme.of(context).textTheme.bodyMedium),
        ),
        PortalAccordionSection(
          title: 'Returns',
          child: Text('30 days.', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  },
  'portal_alert': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PortalAlert(title: 'Heads up', description: 'You can add actions below.'),
        SizedBox(height: t.spacing.md),
        PortalAlert(
          title: 'Published',
          description: 'Your changes are live.',
          variant: PortalAlertVariant.primary,
          actions: [
            PortalButton(label: 'View', size: PortalButtonSize.sm, onPressed: () {}),
          ],
        ),
      ],
    );
  },
  'portal_aspect_ratio': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return PortalAspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(t.radii.md),
        ),
        child: const Center(child: Text('16 : 9')),
      ),
    );
  },
  'portal_avatar': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PortalAvatar(initials: 'ab', size: PortalAvatarSize.sm),
        SizedBox(width: t.spacing.md),
        PortalAvatar(initials: 'cd', size: PortalAvatarSize.md),
        SizedBox(width: t.spacing.md),
        PortalAvatar(initials: 'ef', size: PortalAvatarSize.lg),
      ],
    );
  },
  'portal_badge': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Wrap(
      spacing: t.spacing.sm,
      runSpacing: t.spacing.sm,
      children: const [
        PortalBadge(label: 'Neutral', variant: PortalBadgeVariant.neutral),
        PortalBadge(label: 'Primary', variant: PortalBadgeVariant.primary),
        PortalBadge(label: 'Destructive', variant: PortalBadgeVariant.destructive),
      ],
    );
  },
  'portal_breadcrumb': (context) => PortalBreadcrumb(
        items: [
          PortalBreadcrumbItem(label: 'Docs', onTap: () {}),
          PortalBreadcrumbItem(label: 'Components', onTap: () {}),
          const PortalBreadcrumbItem(label: 'Breadcrumb'),
        ],
      ),
  'portal_button': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Wrap(
      spacing: t.spacing.sm,
      runSpacing: t.spacing.sm,
      children: [
        PortalButton(label: 'Primary', onPressed: () {}),
        PortalButton(
          label: 'Secondary',
          variant: PortalButtonVariant.secondary,
          onPressed: () {},
        ),
        PortalButton(
          label: 'Outline',
          variant: PortalButtonVariant.outline,
          onPressed: () {},
        ),
        const PortalButton(label: 'Disabled', onPressed: null),
      ],
    );
  },
  'portal_card': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Card', style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: t.spacing.sm),
          Text('Surface with border and padding.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  },
  'portal_checkbox': (context) => const _CheckboxPreview(),
  'portal_collapsible': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return PortalCollapsible(
      title: 'Advanced',
      child: Padding(
        padding: EdgeInsets.only(top: t.spacing.sm),
        child: Text('Hidden until expanded.', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  },
  'portal_dialog': (context) => Center(
        child: PortalButton(
          label: 'Open alert dialog',
          onPressed: () {
            showPortalAlertDialog(
              context: context,
              title: 'Are you sure?',
              message: 'This uses your theme tokens.',
              cancelLabel: 'Cancel',
              confirmLabel: 'Continue',
            );
          },
        ),
      ),
  'portal_divider': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Above', style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: t.spacing.xs),
        const PortalDivider(),
        SizedBox(height: t.spacing.xs),
        Text('Below', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  },
  'portal_label': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalLabel(text: 'Email'),
        SizedBox(height: t.spacing.xs),
        const PortalTextField(label: null, hint: 'you@example.com'),
      ],
    );
  },
  'portal_pagination': (context) => const _PaginationPreview(),
  'portal_progress': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PortalProgress(value: 0.45),
        SizedBox(height: t.spacing.md),
        const PortalProgress(),
      ],
    );
  },
  'portal_radio_group': (context) => const _RadioPreview(),
  'portal_scroll_area': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return SizedBox(
      height: 160,
      child: PortalScrollArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 12; i++)
              Padding(
                padding: EdgeInsets.only(bottom: t.spacing.sm),
                child: Text('Scrollable line ${i + 1}'),
              ),
          ],
        ),
      ),
    );
  },
  'portal_select': (context) => const _SelectPreview(),
  'portal_separator': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PortalSeparator(),
        SizedBox(height: t.spacing.sm),
        Row(
          children: [
            const Text('Left'),
            PortalSeparator(
              orientation: PortalSeparatorOrientation.vertical,
              length: t.minTapTarget * 0.55,
            ),
            const Text('Right'),
          ],
        ),
      ],
    );
  },
  'portal_sheet': (context) => Center(
        child: PortalButton(
          label: 'Open bottom sheet',
          onPressed: () {
            showPortalSheet<void>(
              context: context,
              builder: (ctx) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sheet content',
                  style: Theme.of(ctx).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ),
  'portal_skeleton': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalSkeleton(width: 200),
        SizedBox(height: t.spacing.sm),
        const PortalSkeleton(width: 160, height: 12),
        SizedBox(height: t.spacing.xs),
        const PortalSkeleton(width: 120, height: 12),
      ],
    );
  },
  'portal_spinner': (context) => const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PortalSpinner(style: PortalSpinnerStyle.ring, size: 36),
        PortalSpinner(style: PortalSpinnerStyle.fadingCircle, size: 36),
        PortalSpinner(style: PortalSpinnerStyle.wave, size: 36),
      ],
    ),
  'portal_slidable': (context) => const _SlidablePreview(),
  'portal_slider': (context) => const _SliderPreview(),
  'portal_snackbar': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Wrap(
      spacing: t.spacing.sm,
      runSpacing: t.spacing.sm,
      alignment: WrapAlignment.center,
      children: [
        PortalButton(
          label: 'Neutral',
          size: PortalButtonSize.sm,
          onPressed: () => showPortalToast(context, 'Saved successfully.'),
        ),
        PortalButton(
          label: 'Success',
          size: PortalButtonSize.sm,
          variant: PortalButtonVariant.secondary,
          onPressed: () => showPortalToast(
            context,
            'Published',
            description: 'Your changes are live.',
            variant: PortalToastVariant.success,
          ),
        ),
        PortalButton(
          label: 'Destructive',
          size: PortalButtonSize.sm,
          variant: PortalButtonVariant.destructive,
          onPressed: () => showPortalToast(
            context,
            'Error',
            description: 'Something went wrong.',
            variant: PortalToastVariant.destructive,
          ),
        ),
      ],
    );
  },
  'portal_form': (context) => const _FormPreview(),
  'portal_combobox': (context) => const _ComboboxPreview(),
  'portal_input_otp': (context) => const PortalInputOtp(length: 6, autofocus: false),
  'portal_popover': (context) => PortalPopover(
        trigger: PortalButton(label: 'Open popover', onPressed: () {}),
        content: Text(
          'Dimensions, filters, or compact forms fit well here.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
  'portal_sidebar': (context) => const _SidebarPreview(),
  'portal_switch': (context) => const _SwitchPreview(),
  'portal_table': (context) => PortalTable(
        columns: const ['Name', 'Role', 'Status'],
        rows: const [
          ['Ada', 'Engineer', 'Active'],
          ['Lin', 'Designer', 'Away'],
        ],
      ),
  'portal_tabs': (context) => PortalTabs(
        tabs: const ['Account', 'Password'],
        tabViewHeight: 120,
        children: [
          Center(child: Text('Account settings', style: Theme.of(context).textTheme.bodyMedium)),
          Center(child: Text('Change password', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
  'portal_text_area': (context) => const PortalTextArea(
        label: 'Notes',
        hint: 'Type here…',
        minLines: 3,
        maxLines: 5,
      ),
  'portal_text_field': (context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PortalTextField(label: 'Email', hint: 'you@example.com'),
        SizedBox(height: t.spacing.md),
        const PortalTextField(label: 'Password', obscureText: true),
      ],
    );
  },
  'portal_toggle': (context) => const _TogglePreview(),
  'portal_tooltip': (context) => Center(
        child: PortalTooltip(
          message: 'I am a tooltip',
          child: PortalButton(label: 'Hover or long-press', onPressed: () {}),
        ),
      ),
  'portal_command': (context) => Center(
        child: PortalButton(
          label: 'Open command palette',
          onPressed: () {
            showPortalCommand<String>(
              context: context,
              title: 'Commands',
              items: const [
                PortalCommandItem(title: 'Go home', value: 'home', icon: Icons.home_outlined),
                PortalCommandItem(title: 'Settings', value: 'settings', icon: Icons.settings_outlined),
              ],
            );
          },
        ),
      ),
  'portal_dropdown_menu': (context) {
    final portal = PortalUiTheme.of(context);
    return PortalDropdownMenu(
      trigger: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Menu', style: Theme.of(context).textTheme.labelLarge),
          Icon(Icons.expand_more, color: portal.onSurfaceVariant),
        ],
      ),
      actions: [
        PortalMenuAction(label: 'Edit', icon: Icons.edit_outlined, onPressed: () {}),
        PortalMenuAction(
          label: 'Remove',
          icon: Icons.delete_outline,
          destructive: true,
          onPressed: () {},
        ),
      ],
    );
  },
  'portal_calendar': (context) => const _CalendarPreview(),
};

class _CheckboxPreview extends StatefulWidget {
  const _CheckboxPreview();

  @override
  State<_CheckboxPreview> createState() => _CheckboxPreviewState();
}

class _CheckboxPreviewState extends State<_CheckboxPreview> {
  bool? _v = false;

  @override
  Widget build(BuildContext context) {
    return PortalCheckbox(
      label: 'Accept terms',
      subtitle: 'Tap the row or the box.',
      value: _v,
      onChanged: (v) => setState(() => _v = v),
    );
  }
}

class _SwitchPreview extends StatefulWidget {
  const _SwitchPreview();

  @override
  State<_SwitchPreview> createState() => _SwitchPreviewState();
}

class _SwitchPreviewState extends State<_SwitchPreview> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return PortalSwitch(
      label: 'Notifications',
      value: _on,
      onChanged: (v) => setState(() => _on = v),
    );
  }
}

class _SelectPreview extends StatefulWidget {
  const _SelectPreview();

  @override
  State<_SelectPreview> createState() => _SelectPreviewState();
}

class _SelectPreviewState extends State<_SelectPreview> {
  String? _role = 'dev';

  @override
  Widget build(BuildContext context) {
    return PortalSelect<String>(
      label: 'Role',
      value: _role,
      items: const [
        PortalSelectItem(value: 'dev', label: 'Developer'),
        PortalSelectItem(value: 'design', label: 'Designer'),
      ],
      onChanged: (v) => setState(() => _role = v),
    );
  }
}

class _SliderPreview extends StatefulWidget {
  const _SliderPreview();

  @override
  State<_SliderPreview> createState() => _SliderPreviewState();
}

class _SliderPreviewState extends State<_SliderPreview> {
  double _v = 0.35;

  @override
  Widget build(BuildContext context) {
    return PortalSlider(
      value: _v,
      label: _v.toStringAsFixed(2),
      onChanged: (v) => setState(() => _v = v),
    );
  }
}

class _PaginationPreview extends StatefulWidget {
  const _PaginationPreview();

  @override
  State<_PaginationPreview> createState() => _PaginationPreviewState();
}

class _PaginationPreviewState extends State<_PaginationPreview> {
  int _page = 2;

  @override
  Widget build(BuildContext context) {
    return PortalPagination(
      currentPage: _page,
      totalPages: 5,
      onPageChanged: (p) => setState(() => _page = p),
    );
  }
}

class _RadioPreview extends StatefulWidget {
  const _RadioPreview();

  @override
  State<_RadioPreview> createState() => _RadioPreviewState();
}

class _RadioPreviewState extends State<_RadioPreview> {
  String _plan = 'pro';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalRadioOption<String>(
          value: 'free',
          groupValue: _plan,
          label: 'Free',
          onChanged: (v) => setState(() => _plan = v ?? _plan),
        ),
        PortalRadioOption<String>(
          value: 'pro',
          groupValue: _plan,
          label: 'Pro',
          subtitle: 'Best for teams',
          onChanged: (v) => setState(() => _plan = v ?? _plan),
        ),
      ],
    );
  }
}

class _TogglePreview extends StatefulWidget {
  const _TogglePreview();

  @override
  State<_TogglePreview> createState() => _TogglePreviewState();
}

class _TogglePreviewState extends State<_TogglePreview> {
  bool _bold = false;

  @override
  Widget build(BuildContext context) {
    return PortalToggle(
      pressed: _bold,
      onPressed: () => setState(() => _bold = !_bold),
      child: const Icon(Icons.format_bold),
    );
  }
}

class _FormPreview extends StatefulWidget {
  const _FormPreview();

  @override
  State<_FormPreview> createState() => _FormPreviewState();
}

class _FormPreviewState extends State<_FormPreview> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    return PortalForm(
      formKey: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortalValidatedField<String>(
            label: 'Email',
            description: 'We never share your email.',
            validator: (v) =>
                v != null && v.contains('@') ? null : 'Enter a valid email',
            fieldBuilder: (state) => TextField(
              onChanged: state.didChange,
              decoration: portalInputDecoration(context, hint: 'you@example.com'),
            ),
          ),
          SizedBox(height: t.spacing.lg),
          PortalButton(
            label: 'Validate',
            onPressed: () => _formKey.currentState?.validate(),
          ),
        ],
      ),
    );
  }
}

class _ComboboxPreview extends StatefulWidget {
  const _ComboboxPreview();

  @override
  State<_ComboboxPreview> createState() => _ComboboxPreviewState();
}

class _ComboboxPreviewState extends State<_ComboboxPreview> {
  String? _framework;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalCombobox<String>(
          label: 'Framework',
          hint: 'Search frameworks…',
          initialValue: _framework,
          items: const [
            PortalComboboxItem(value: 'flutter', label: 'Flutter'),
            PortalComboboxItem(value: 'react', label: 'React'),
            PortalComboboxItem(value: 'vue', label: 'Vue'),
          ],
          onSelected: (v) => setState(() => _framework = v),
        ),
        if (_framework != null) ...[
          SizedBox(height: t.spacing.sm),
          Text('Selected: $_framework', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _SidebarPreview extends StatefulWidget {
  const _SidebarPreview();

  @override
  State<_SidebarPreview> createState() => _SidebarPreviewState();
}

class _SidebarPreviewState extends State<_SidebarPreview> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PortalSidebar(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        width: 200,
        items: const [
          PortalSidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
          PortalSidebarItem(label: 'Projects', icon: Icons.folder_outlined, badge: '3'),
          PortalSidebarItem(label: 'Settings', icon: Icons.settings_outlined),
        ],
      ),
    );
  }
}

class _CalendarPreview extends StatefulWidget {
  const _CalendarPreview();

  @override
  State<_CalendarPreview> createState() => _CalendarPreviewState();
}

class _CalendarPreviewState extends State<_CalendarPreview> {
  DateTime _day = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  Widget build(BuildContext context) {
    return PortalCalendar(
      selected: _day,
      onSelected: (d) => setState(() => _day = DateTime(d.year, d.month, d.day)),
    );
  }
}

class _SlidablePreview extends StatelessWidget {
  const _SlidablePreview();

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    return Column(
      children: [
        PortalSlidable(
          endActions: [
            PortalSlidableAction(
              label: 'Archive',
              icon: Icons.archive_outlined,
              onPressed: () {},
            ),
            PortalSlidableAction(
              label: 'Delete',
              icon: Icons.delete_outline,
              isDestructive: true,
              onPressed: () {},
            ),
          ],
          child: const ListTile(
            title: Text('Quarterly report'),
            subtitle: Text('Swipe left for actions'),
          ),
        ),
        SizedBox(height: t.spacing.sm),
        PortalSlidable(
          startActions: [
            PortalSlidableAction(
              label: 'Pin',
              icon: Icons.push_pin_outlined,
              onPressed: () {},
            ),
          ],
          child: const ListTile(
            title: Text('Pinned note'),
            subtitle: Text('Swipe right to pin'),
          ),
        ),
      ],
    );
  }
}
