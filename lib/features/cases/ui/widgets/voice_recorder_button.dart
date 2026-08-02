import 'dart:async';

import 'package:dental_lab_app/core/permissions/audio_permission.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Mic button that records a voice note in place (tap to start, tap again to
/// stop) and hands the recorded file path back through [onRecorded]. Shows
/// the running duration while recording.
class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton({super.key, required this.onRecorded});

  final ValueChanged<String> onRecorded;

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _recorder = AudioRecorder();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _isRecording = false;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final granted = await ensureMicrophonePermission();
    if (!granted) {
      ShowToast(
        message: 'الرجاء السماح باستخدام الميكروفون',
        state: toastState.error,
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);

    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null) widget.onRecorded(path);
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return IconButton(
        onPressed: _start,
        icon: const Icon(Icons.mic_outlined, color: AppColorsManger.primary),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_format(_elapsed), style: AppTextStyles.font12RegularHint),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _stop,
          icon: const Icon(Icons.stop_circle, color: AppColorsManger.error),
        ),
      ],
    );
  }
}
