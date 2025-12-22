import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/device_bloc.dart';
import '../bloc/device_event.dart';
import '../bloc/device_state.dart';
import '../../domain/entities/smart_device.dart';

class DeviceConnectionPage extends StatefulWidget {
  const DeviceConnectionPage({super.key});

  @override
  State<DeviceConnectionPage> createState() => _DeviceConnectionPageState();
}

class _DeviceConnectionPageState extends State<DeviceConnectionPage> {
  @override
  void initState() {
    super.initState();
    context.read<DeviceBloc>().add(StartScanDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Glasses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DeviceBloc>().add(StartScanDevices());
            },
          ),
        ],
      ),
      body: BlocConsumer<DeviceBloc, DeviceState>(
        listener: (context, state) {
          if (state is DeviceConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connected to ${state.device.name}'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is DeviceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DeviceScanning) {
            return Column(
              children: [
                const LinearProgressIndicator(),
                Expanded(
                  child: state.devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Scanning for devices...',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.devices.length,
                          itemBuilder: (context, index) {
                            final device = state.devices[index];
                            return _DeviceCard(device: device);
                          },
                        ),
                ),
              ],
            );
          } else if (state is DeviceConnecting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting...'),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                const Text('Tap to scan for devices'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<DeviceBloc>().add(StartScanDevices());
                  },
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Start Scanning'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    context.read<DeviceBloc>().add(StopScanDevices());
    super.dispose();
  }
}

class _DeviceCard extends StatelessWidget {
  final SmartDevice device;

  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.visibility_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          device.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text('Signal: ${device.rssi} dBm'),
        trailing: ElevatedButton(
          onPressed: () {
            context.read<DeviceBloc>().add(ConnectToDevice(device.id));
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }
}

