import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/config/custom_theme.dart';
import 'package:document_companion/utils/ux_helpers.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  static const String route = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = CustomTheme();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            UXHelpers.selectionFeedback();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance Section
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsTile(
                leading: Icon(
                  theme.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: CustomColors.primary,
                ),
                title: 'Theme',
                subtitle: theme.isDarkMode ? 'Dark Mode' : 'Light Mode',
                trailing: Switch(
                  value: theme.isDarkMode,
                  onChanged: (value) {
                    UXHelpers.selectionFeedback();
                    theme.toggleTheme();
                    setState(() {});
                    UXHelpers.successFeedback();
                  },
                  activeColor: CustomColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // General Section
          _SettingsSection(
            title: 'General',
            children: [
              _SettingsTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: CustomColors.primary,
                ),
                title: 'About',
                subtitle: 'App version and information',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: CustomColors.textTertiary,
                ),
                onTap: () {
                  UXHelpers.selectionFeedback();
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Data Section
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsTile(
                leading: Icon(
                  Icons.storage_rounded,
                  color: CustomColors.primary,
                ),
                title: 'Storage',
                subtitle: 'Manage app storage',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: CustomColors.textTertiary,
                ),
                onTap: () {
                  UXHelpers.selectionFeedback();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Storage management coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CustomColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: CustomColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Document Companion'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A powerful document management app for organizing and managing your documents.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: CustomColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              UXHelpers.selectionFeedback();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CustomColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

