import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/config/custom_theme.dart';
import 'package:document_companion/modules/home/services/ad_service.dart';
import 'package:document_companion/utils/ux_helpers.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  static const String route = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _checkAdStatus();
    // Check ad status periodically
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAdReady = adService.isRewardedAdReady;
        });
      }
    });
  }

  void _checkAdStatus() {
    setState(() {
      _isAdReady = adService.isRewardedAdReady;
    });
  }

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
          
          // Premium Section
          _SettingsSection(
            title: 'Premium',
            children: [
              _SettingsTile(
                leading: Icon(
                  Icons.ads_click_rounded,
                  color: CustomColors.primary,
                ),
                title: 'Remove Ads',
                subtitle: 'Watch an ad to remove ads for 24 hours',
                trailing: Icon(
                  Icons.play_circle_outline_rounded,
                  color: CustomColors.primary,
                ),
                onTap: () {
                  UXHelpers.selectionFeedback();
                  _showRemoveAdsDialog(context);
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

  void _showRemoveAdsDialog(BuildContext context) {
    _checkAdStatus();
    final isAdReady = _isAdReady;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.ads_click_rounded, color: CustomColors.primary),
            SizedBox(width: 12),
            Text('Remove Ads'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Watch a short ad to remove all ads from the app for 24 hours.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 20, color: CustomColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('No banner ads', style: TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 20, color: CustomColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('No interstitial ads', style: TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 20, color: CustomColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Ad-free experience', style: TextStyle(fontSize: 13))),
              ],
            ),
            if (!isAdReady) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ad is loading. Please wait a moment.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              UXHelpers.selectionFeedback();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isAdReady
                ? () {
                    UXHelpers.selectionFeedback();
                    Navigator.of(context).pop();
                    
                    // Show rewarded ad
                    final shown = adService.showRewardedAd(
                      onRewarded: () {
                        // TODO: Implement logic to disable ads for 24 hours
                        // You can use SharedPreferences to store the timestamp
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ads removed for 24 hours! 🎉'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          UXHelpers.successFeedback();
                        }
                      },
                      onAdDismissed: () {
                        // Ad was dismissed (user may or may not have earned reward)
                        if (context.mounted) {
                          _checkAdStatus();
                        }
                      },
                      onAdFailedToShow: (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to show ad: $error'),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          _checkAdStatus();
                        }
                      },
                    );
                    
                    if (!shown && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ad is loading. Please try again in a moment.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isAdReady) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Text('Watch Ad'),
              ],
            ),
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

