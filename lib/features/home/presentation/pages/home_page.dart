import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../device/presentation/bloc/device_bloc.dart';
import '../../../device/presentation/bloc/device_state.dart';
import '../../../voice/presentation/bloc/voice_bloc.dart';
import '../../../voice/presentation/bloc/voice_event.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/feature_card.dart';
import '../widgets/voice_assistant_fab.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Glasses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.settings);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          state.user.displayName ?? state.user.email,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 32),
              BlocBuilder<DeviceBloc, DeviceState>(
                builder: (context, state) {
                  return _DeviceStatusCard(state: state);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Features',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FeatureCard(
                icon: Icons.navigation_outlined,
                title: 'Navigation',
                description: 'Turn-by-turn voice navigation',
                color: Colors.blue,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.navigation);
                },
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: Icons.bluetooth_outlined,
                title: 'Device Connection',
                description: 'Connect your smart glasses',
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.deviceConnection);
                },
              ),
              const SizedBox(height: 12),
              FeatureCard(
                icon: Icons.mic_outlined,
                title: 'Voice Assistant',
                description: 'Control with your voice',
                color: Colors.orange,
                onTap: () {
                  context.read<VoiceBloc>().add(StartListening());
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const VoiceAssistantFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  final DeviceState state;

  const _DeviceStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is DeviceConnected) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(state.device.name),
                    if (state.device.batteryLevel != null)
                      Text('Battery: ${state.device.batteryLevel}%'),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.visibility_off_outlined,
                color: Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Device Connected',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Tap to connect your glasses'),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

