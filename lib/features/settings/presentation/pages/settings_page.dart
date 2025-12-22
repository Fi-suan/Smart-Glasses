import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../../core/router/app_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Device',
            children: [
              _SettingsTile(
                icon: Icons.bluetooth_outlined,
                title: 'Bluetooth Connection',
                subtitle: 'Manage device connection',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.deviceConnection);
                },
              ),
              _SettingsTile(
                icon: Icons.battery_charging_full_outlined,
                title: 'Battery Optimization',
                subtitle: 'Optimize battery usage',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Voice',
            children: [
              _SettingsTile(
                icon: Icons.mic_outlined,
                title: 'Voice Recognition',
                subtitle: 'Configure voice settings',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.volume_up_outlined,
                title: 'Audio Feedback',
                subtitle: 'Adjust voice responses',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Navigation',
            children: [
              _SettingsTile(
                icon: Icons.navigation_outlined,
                title: 'Navigation Preferences',
                subtitle: 'Set default navigation options',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.map_outlined,
                title: 'Map Style',
                subtitle: 'Choose map appearance',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Account',
            children: [
              _SettingsTile(
                icon: Icons.person_outlined,
                title: 'Profile',
                subtitle: 'Manage your account',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.security_outlined,
                title: 'Privacy & Security',
                subtitle: 'Control your data',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.logout_outlined,
                title: 'Sign Out',
                subtitle: 'Logout from your account',
                onTap: () {
                  _showLogoutDialog(context);
                },
                textColor: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Smart Glasses v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushReplacementNamed(AppRouter.login);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
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
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

