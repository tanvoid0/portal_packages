import 'package:flutter/material.dart';

import '../showcase/component_previews.dart';

enum ComponentCategory {
  actions,
  formInput,
  feedback,
  layout,
  overlay,
  navigation,
  display,
}

extension ComponentCategoryLabel on ComponentCategory {
  String get catalogLabel => switch (this) {
        ComponentCategory.actions => 'Actions',
        ComponentCategory.formInput => 'Form & input',
        ComponentCategory.feedback => 'Feedback',
        ComponentCategory.layout => 'Layout',
        ComponentCategory.overlay => 'Overlay',
        ComponentCategory.navigation => 'Navigation',
        ComponentCategory.display => 'Display',
      };
}

class ComponentEntry {
  const ComponentEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.brickName,
    required this.sourceFileName,
    required this.description,
    required this.usageSnippet,
    required this.preview,
  });

  final String id;
  final String title;
  final ComponentCategory category;
  final String brickName;
  final String sourceFileName;
  final String description;
  final String usageSnippet;
  final WidgetBuilder preview;

  String get installCommand => 'mason make $brickName -o lib/ui';
}

/// All bricks from [mason.yaml], ordered for the sidebar.
final List<ComponentEntry> kComponentCatalog = () {
  final entries = <ComponentEntry>[
    ComponentEntry(
      id: 'portal_button',
      title: 'Button',
      category: ComponentCategory.actions,
      brickName: 'portal_button',
      sourceFileName: 'portal_button.dart',
      description: 'Primary actions and variants: secondary, outline, destructive, ghost, and sizes.',
      usageSnippet: '''PortalButton(
  label: 'Save',
  onPressed: () {},
)''',
      preview: _p('portal_button'),
    ),
    ComponentEntry(
      id: 'portal_toggle',
      title: 'Toggle',
      category: ComponentCategory.actions,
      brickName: 'portal_toggle',
      sourceFileName: 'portal_toggle.dart',
      description: 'Pressable control with pressed styling for icon or text toggles.',
      usageSnippet: '''PortalToggle(
  pressed: bold,
  onPressed: () => setState(() => bold = !bold),
  child: Icon(Icons.format_bold),
)''',
      preview: _p('portal_toggle'),
    ),
    ComponentEntry(
      id: 'portal_text_field',
      title: 'Text field',
      category: ComponentCategory.formInput,
      brickName: 'portal_text_field',
      sourceFileName: 'portal_text_field.dart',
      description: 'Single-line input with label, hint, and PortalUiTheme borders.',
      usageSnippet: '''const PortalTextField(
  label: 'Email',
  hint: 'you@example.com',
)''',
      preview: _p('portal_text_field'),
    ),
    ComponentEntry(
      id: 'portal_text_area',
      title: 'Text area',
      category: ComponentCategory.formInput,
      brickName: 'portal_text_area',
      sourceFileName: 'portal_text_area.dart',
      description: 'Multiline text field styled like shadcn Textarea.',
      usageSnippet: '''const PortalTextArea(
  label: 'Notes',
  hint: 'Optional',
  minLines: 3,
  maxLines: 8,
)''',
      preview: _p('portal_text_area'),
    ),
    ComponentEntry(
      id: 'portal_label',
      title: 'Label',
      category: ComponentCategory.formInput,
      brickName: 'portal_label',
      sourceFileName: 'portal_label.dart',
      description: 'Form label with optional required asterisk.',
      usageSnippet: '''const PortalLabel(
  text: 'Password',
  requiredIndicator: true,
)''',
      preview: _p('portal_label'),
    ),
    ComponentEntry(
      id: 'portal_checkbox',
      title: 'Checkbox',
      category: ComponentCategory.formInput,
      brickName: 'portal_checkbox',
      sourceFileName: 'portal_checkbox.dart',
      description: 'Checkbox row with label and optional subtitle.',
      usageSnippet: '''PortalCheckbox(
  label: 'Remember me',
  value: checked,
  onChanged: (v) => setState(() => checked = v ?? false),
)''',
      preview: _p('portal_checkbox'),
    ),
    ComponentEntry(
      id: 'portal_switch',
      title: 'Switch',
      category: ComponentCategory.formInput,
      brickName: 'portal_switch',
      sourceFileName: 'portal_switch.dart',
      description: 'Switch row with label for boolean settings.',
      usageSnippet: '''PortalSwitch(
  label: 'Notifications',
  value: on,
  onChanged: (v) => setState(() => on = v),
)''',
      preview: _p('portal_switch'),
    ),
    ComponentEntry(
      id: 'portal_slider',
      title: 'Slider',
      category: ComponentCategory.formInput,
      brickName: 'portal_slider',
      sourceFileName: 'portal_slider.dart',
      description: 'Themed continuous or discrete slider.',
      usageSnippet: '''PortalSlider(
  value: volume,
  onChanged: (v) => setState(() => volume = v),
  label: volume.toStringAsFixed(2),
)''',
      preview: _p('portal_slider'),
    ),
    ComponentEntry(
      id: 'portal_radio_group',
      title: 'Radio group',
      category: ComponentCategory.formInput,
      brickName: 'portal_radio_group',
      sourceFileName: 'portal_radio_group.dart',
      description: 'Radio option rows sharing groupValue and onChanged.',
      usageSnippet: '''PortalRadioOption<String>(
  value: 'a',
  groupValue: plan,
  label: 'Option A',
  onChanged: (v) => setState(() => plan = v ?? plan),
)''',
      preview: _p('portal_radio_group'),
    ),
    ComponentEntry(
      id: 'portal_form',
      title: 'Form',
      category: ComponentCategory.formInput,
      brickName: 'portal_form',
      sourceFileName: 'portal_form.dart',
      description: 'Form wrapper and validated fields with PortalFormField UI.',
      usageSnippet: '''PortalForm(
  formKey: _formKey,
  child: PortalValidatedField<String>(
    label: 'Email',
    validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
    fieldBuilder: (state) => TextField(
      onChanged: state.didChange,
      decoration: portalInputDecoration(context),
    ),
  ),
)''',
      preview: _p('portal_form'),
    ),
    ComponentEntry(
      id: 'portal_combobox',
      title: 'Combobox',
      category: ComponentCategory.formInput,
      brickName: 'portal_combobox',
      sourceFileName: 'portal_combobox.dart',
      description: 'Searchable select with filter-as-you-type.',
      usageSnippet: '''PortalCombobox<String>(
  label: 'Framework',
  items: const [
    PortalComboboxItem(value: 'flutter', label: 'Flutter'),
  ],
  onSelected: (v) => setState(() => framework = v),
)''',
      preview: _p('portal_combobox'),
    ),
    ComponentEntry(
      id: 'portal_input_otp',
      title: 'Input OTP',
      category: ComponentCategory.formInput,
      brickName: 'portal_input_otp',
      sourceFileName: 'portal_input_otp.dart',
      description: 'One-time passcode entry with segmented digit boxes.',
      usageSnippet: '''PortalInputOtp(
  length: 6,
  onCompleted: (code) => verify(code),
)''',
      preview: _p('portal_input_otp'),
    ),
    ComponentEntry(
      id: 'portal_select',
      title: 'Select',
      category: ComponentCategory.formInput,
      brickName: 'portal_select',
      sourceFileName: 'portal_select.dart',
      description: 'Dropdown select with Portal-styled decorator.',
      usageSnippet: '''PortalSelect<String>(
  label: 'Role',
  value: role,
  items: const [
    PortalSelectItem(value: 'admin', label: 'Admin'),
  ],
  onChanged: (v) => setState(() => role = v),
)''',
      preview: _p('portal_select'),
    ),
    ComponentEntry(
      id: 'portal_alert',
      title: 'Alert',
      category: ComponentCategory.feedback,
      brickName: 'portal_alert',
      sourceFileName: 'portal_alert.dart',
      description: 'Inline callout for status, warnings, and optional actions.',
      usageSnippet: '''PortalAlert(
  title: 'Unable to process',
  description: 'Check your connection.',
  variant: PortalAlertVariant.destructive,
)''',
      preview: _p('portal_alert'),
    ),
    ComponentEntry(
      id: 'portal_snackbar',
      title: 'Toast',
      category: ComponentCategory.feedback,
      brickName: 'portal_snackbar',
      sourceFileName: 'portal_snackbar.dart',
      description: 'Opaque themed toast (ColorScheme fills). Neutral, success, and destructive.',
      usageSnippet: '''showPortalToast(
  context,
  'Published',
  description: 'Your changes are live.',
  variant: PortalToastVariant.success,
  actionLabel: 'Undo',
  onAction: () {},
);''',
      preview: _p('portal_snackbar'),
    ),
    ComponentEntry(
      id: 'portal_progress',
      title: 'Progress',
      category: ComponentCategory.feedback,
      brickName: 'portal_progress',
      sourceFileName: 'portal_progress.dart',
      description: 'Determinate or indeterminate linear progress.',
      usageSnippet: '''const PortalProgress(value: 0.6)
// or
const PortalProgress()''',
      preview: _p('portal_progress'),
    ),
    ComponentEntry(
      id: 'portal_skeleton',
      title: 'Skeleton',
      category: ComponentCategory.feedback,
      brickName: 'portal_skeleton',
      sourceFileName: 'portal_skeleton.dart',
      description: 'Shimmer placeholder for loading layouts.',
      usageSnippet: '''const PortalSkeleton(width: 200, height: 14)''',
      preview: _p('portal_skeleton'),
    ),
    ComponentEntry(
      id: 'portal_spinner',
      title: 'Spinner',
      category: ComponentCategory.feedback,
      brickName: 'portal_spinner',
      sourceFileName: 'portal_spinner.dart',
      description: 'Animated loading indicator (flutter_spinkit).',
      usageSnippet: '''const PortalSpinner()
const PortalSpinner(
  style: PortalSpinnerStyle.fadingCircle,
  size: 32,
)''',
      preview: _p('portal_spinner'),
    ),
    ComponentEntry(
      id: 'portal_slidable',
      title: 'Slidable',
      category: ComponentCategory.display,
      brickName: 'portal_slidable',
      sourceFileName: 'portal_slidable.dart',
      description: 'Swipe actions on list rows (flutter_slidable).',
      usageSnippet: '''PortalSlidable(
  endActions: [
    PortalSlidableAction(
      label: 'Delete',
      icon: Icons.delete,
      isDestructive: true,
      onPressed: () {},
    ),
  ],
  child: ListTile(title: Text('Swipe me')),
)''',
      preview: _p('portal_slidable'),
    ),
    ComponentEntry(
      id: 'portal_card',
      title: 'Card',
      category: ComponentCategory.layout,
      brickName: 'portal_card',
      sourceFileName: 'portal_card.dart',
      description: 'Surface card with border; optional tap handler.',
      usageSnippet: '''PortalCard(
  child: Text('Content'),
)''',
      preview: _p('portal_card'),
    ),
    ComponentEntry(
      id: 'portal_divider',
      title: 'Divider',
      category: ComponentCategory.layout,
      brickName: 'portal_divider',
      sourceFileName: 'portal_divider.dart',
      description: 'Horizontal rule using outline color from the theme.',
      usageSnippet: '''const PortalDivider()''',
      preview: _p('portal_divider'),
    ),
    ComponentEntry(
      id: 'portal_separator',
      title: 'Separator',
      category: ComponentCategory.layout,
      brickName: 'portal_separator',
      sourceFileName: 'portal_separator.dart',
      description: 'Thin horizontal or vertical rule (shadcn Separator).',
      usageSnippet: '''const PortalSeparator()
const PortalSeparator(
  orientation: PortalSeparatorOrientation.vertical,
  length: 32,
)''',
      preview: _p('portal_separator'),
    ),
    ComponentEntry(
      id: 'portal_aspect_ratio',
      title: 'Aspect ratio',
      category: ComponentCategory.layout,
      brickName: 'portal_aspect_ratio',
      sourceFileName: 'portal_aspect_ratio.dart',
      description: 'Constrains child to a fixed width:height ratio.',
      usageSnippet: '''PortalAspectRatio(
  aspectRatio: 16 / 9,
  child: YourMedia(),
)''',
      preview: _p('portal_aspect_ratio'),
    ),
    ComponentEntry(
      id: 'portal_scroll_area',
      title: 'Scroll area',
      category: ComponentCategory.layout,
      brickName: 'portal_scroll_area',
      sourceFileName: 'portal_scroll_area.dart',
      description: 'Scrollable region with optional visible scrollbar.',
      usageSnippet: '''PortalScrollArea(
  showScrollbar: true,
  controller: _scroll,
  child: Column(children: [...]),
)''',
      preview: _p('portal_scroll_area'),
    ),
    ComponentEntry(
      id: 'portal_collapsible',
      title: 'Collapsible',
      category: ComponentCategory.layout,
      brickName: 'portal_collapsible',
      sourceFileName: 'portal_collapsible.dart',
      description: 'Single disclosure with animated show/hide body.',
      usageSnippet: '''PortalCollapsible(
  title: 'Details',
  child: Text('More info'),
)''',
      preview: _p('portal_collapsible'),
    ),
    ComponentEntry(
      id: 'portal_accordion',
      title: 'Accordion',
      category: ComponentCategory.layout,
      brickName: 'portal_accordion',
      sourceFileName: 'portal_accordion.dart',
      description: 'Stack of expansion sections with shared surface styling.',
      usageSnippet: '''PortalAccordion(
  sections: [
    PortalAccordionSection(title: 'One', child: Text('A')),
    PortalAccordionSection(title: 'Two', child: Text('B')),
  ],
)''',
      preview: _p('portal_accordion'),
    ),
    ComponentEntry(
      id: 'portal_dialog',
      title: 'Alert dialog',
      category: ComponentCategory.overlay,
      brickName: 'portal_dialog',
      sourceFileName: 'portal_dialog.dart',
      description: 'Themed AlertDialog helper returning confirm/cancel result.',
      usageSnippet: '''final ok = await showPortalAlertDialog(
  context: context,
  title: 'Delete item?',
  message: 'This cannot be undone.',
  cancelLabel: 'Cancel',
  confirmLabel: 'Delete',
  destructive: true,
);''',
      preview: _p('portal_dialog'),
    ),
    ComponentEntry(
      id: 'portal_sheet',
      title: 'Sheet',
      category: ComponentCategory.overlay,
      brickName: 'portal_sheet',
      sourceFileName: 'portal_sheet.dart',
      description: 'Modal bottom sheet with drag handle and themed surface.',
      usageSnippet: '''await showPortalSheet<void>(
  context: context,
  builder: (ctx) => ListTile(title: Text('Hello')),
);''',
      preview: _p('portal_sheet'),
    ),
    ComponentEntry(
      id: 'portal_tooltip',
      title: 'Tooltip',
      category: ComponentCategory.overlay,
      brickName: 'portal_tooltip',
      sourceFileName: 'portal_tooltip.dart',
      description: 'Material tooltip styled with on-surface contrast.',
      usageSnippet: '''PortalTooltip(
  message: 'Copied!',
  child: IconButton(icon: Icon(Icons.copy), onPressed: () {}),
)''',
      preview: _p('portal_tooltip'),
    ),
    ComponentEntry(
      id: 'portal_popover',
      title: 'Popover',
      category: ComponentCategory.overlay,
      brickName: 'portal_popover',
      sourceFileName: 'portal_popover.dart',
      description: 'Click-triggered anchored panel for compact content.',
      usageSnippet: '''PortalPopover(
  trigger: PortalButton(label: 'Open', onPressed: () {}),
  content: Text('Popover content'),
)''',
      preview: _p('portal_popover'),
    ),
    ComponentEntry(
      id: 'portal_command',
      title: 'Command palette',
      category: ComponentCategory.overlay,
      brickName: 'portal_command',
      sourceFileName: 'portal_command.dart',
      description: 'Searchable dialog list for quick actions (shadcn Command).',
      usageSnippet: '''final id = await showPortalCommand<String>(
  context: context,
  items: [
    PortalCommandItem(title: 'Settings', value: 'settings', icon: Icons.settings),
  ],
);''',
      preview: _p('portal_command'),
    ),
    ComponentEntry(
      id: 'portal_dropdown_menu',
      title: 'Dropdown menu',
      category: ComponentCategory.overlay,
      brickName: 'portal_dropdown_menu',
      sourceFileName: 'portal_dropdown_menu.dart',
      description: 'Anchored menu with themed surface (shadcn Dropdown Menu).',
      usageSnippet: '''PortalDropdownMenu(
  trigger: Row(children: [Text('Actions'), Icon(Icons.expand_more)]),
  actions: [
    PortalMenuAction(label: 'Edit', onPressed: () {}),
  ],
)''',
      preview: _p('portal_dropdown_menu'),
    ),
    ComponentEntry(
      id: 'portal_calendar',
      title: 'Calendar',
      category: ComponentCategory.formInput,
      brickName: 'portal_calendar',
      sourceFileName: 'portal_calendar.dart',
      description: 'Month grid with prev/next and day selection (shadcn Calendar subset).',
      usageSnippet: '''PortalCalendar(
  selected: day,
  onSelected: (d) => setState(() => day = d),
)''',
      preview: _p('portal_calendar'),
    ),
    ComponentEntry(
      id: 'portal_sidebar',
      title: 'Sidebar',
      category: ComponentCategory.navigation,
      brickName: 'portal_sidebar',
      sourceFileName: 'portal_sidebar.dart',
      description: 'Vertical navigation rail with optional header and footer.',
      usageSnippet: '''PortalSidebar(
  selectedIndex: index,
  onSelected: (i) => setState(() => index = i),
  items: const [
    PortalSidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    PortalSidebarItem(label: 'Settings', icon: Icons.settings_outlined),
  ],
)''',
      preview: _p('portal_sidebar'),
    ),
    ComponentEntry(
      id: 'portal_tabs',
      title: 'Tabs',
      category: ComponentCategory.navigation,
      brickName: 'portal_tabs',
      sourceFileName: 'portal_tabs.dart',
      description: 'Tab bar and fixed-height tab view with theme borders.',
      usageSnippet: '''PortalTabs(
  tabs: const ['A', 'B'],
  tabViewHeight: 200,
  children: [Text('Tab A'), Text('Tab B')],
)''',
      preview: _p('portal_tabs'),
    ),
    ComponentEntry(
      id: 'portal_breadcrumb',
      title: 'Breadcrumb',
      category: ComponentCategory.navigation,
      brickName: 'portal_breadcrumb',
      sourceFileName: 'portal_breadcrumb.dart',
      description: 'Horizontal trail with chevrons between items.',
      usageSnippet: '''PortalBreadcrumb(
  items: [
    PortalBreadcrumbItem(label: 'Home', onTap: () {}),
    const PortalBreadcrumbItem(label: 'Here'),
  ],
)''',
      preview: _p('portal_breadcrumb'),
    ),
    ComponentEntry(
      id: 'portal_pagination',
      title: 'Pagination',
      category: ComponentCategory.navigation,
      brickName: 'portal_pagination',
      sourceFileName: 'portal_pagination.dart',
      description: 'Previous/next controls with current page label.',
      usageSnippet: '''PortalPagination(
  currentPage: page,
  totalPages: 10,
  onPageChanged: (p) => setState(() => page = p),
)''',
      preview: _p('portal_pagination'),
    ),
    ComponentEntry(
      id: 'portal_badge',
      title: 'Badge',
      category: ComponentCategory.display,
      brickName: 'portal_badge',
      sourceFileName: 'portal_badge.dart',
      description: 'Pill status label: neutral, primary, or destructive.',
      usageSnippet: '''const PortalBadge(
  label: 'Beta',
  variant: PortalBadgeVariant.primary,
)''',
      preview: _p('portal_badge'),
    ),
    ComponentEntry(
      id: 'portal_avatar',
      title: 'Avatar',
      category: ComponentCategory.display,
      brickName: 'portal_avatar',
      sourceFileName: 'portal_avatar.dart',
      description: 'Circle avatar from image or initials fallback.',
      usageSnippet: '''PortalAvatar(initials: 'AB', size: PortalAvatarSize.md)''',
      preview: _p('portal_avatar'),
    ),
    ComponentEntry(
      id: 'portal_table',
      title: 'Table',
      category: ComponentCategory.display,
      brickName: 'portal_table',
      sourceFileName: 'portal_table.dart',
      description: 'Lightweight bordered data table from string rows.',
      usageSnippet: '''PortalTable(
  columns: const ['Name', 'Role'],
  rows: const [
    ['Ada', 'Engineer'],
  ],
)''',
      preview: _p('portal_table'),
    ),
  ];

  entries.sort((a, b) {
    final c = a.category.index.compareTo(b.category.index);
    if (c != 0) return c;
    return a.title.compareTo(b.title);
  });
  return List<ComponentEntry>.unmodifiable(entries);
}();

WidgetBuilder _p(String id) {
  final b = kPreviewBuilders[id];
  if (b == null) {
    throw StateError('Missing preview for $id');
  }
  return b;
}
