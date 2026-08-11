import 'package:audioplayers/audioplayers.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Inline play/pause control for a voice message, given either a remote
/// [url] or a local [filePath] (used for the outgoing preview before the
/// message finishes uploading).
class AudioMessagePlayer extends StatefulWidget {
  const AudioMessagePlayer({super.key, this.url, this.filePath})
    : assert(url != null || filePath != null);

  final String? url;
  final String? filePath;

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (widget.filePath != null) {
      await _player.play(DeviceFileSource(widget.filePath!));
    } else {
      await _player.play(UrlSource(widget.url!));
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    final total = _duration > Duration.zero ? _duration : _position;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _toggle,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_format(_position)} / ${_format(total)}',
          style: AppTextStyles.font12RegularHint.copyWith(
            color: context.glass.onGlassMuted,
          ),
        ),
      ],
    );
  }
}
