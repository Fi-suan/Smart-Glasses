import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../voice/presentation/bloc/voice_bloc.dart';
import '../../../voice/presentation/bloc/voice_event.dart';
import '../../../voice/presentation/bloc/voice_state.dart';

class VoiceAssistantFab extends StatelessWidget {
  const VoiceAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceBloc, VoiceState>(
      builder: (context, state) {
        final isListening = state is VoiceListening;
        final isSpeaking = state is VoiceSpeaking;
        
        return FloatingActionButton.extended(
          onPressed: () {
            if (isListening) {
              context.read<VoiceBloc>().add(StopListening());
            } else {
              context.read<VoiceBloc>().add(StartListening());
            }
          },
          backgroundColor: isListening
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          icon: Icon(
            isListening
                ? Icons.mic
                : isSpeaking
                    ? Icons.volume_up
                    : Icons.mic_none,
          ),
          label: Text(
            isListening
                ? 'Listening...'
                : isSpeaking
                    ? 'Speaking...'
                    : 'Voice Assistant',
          ),
        );
      },
    );
  }
}

