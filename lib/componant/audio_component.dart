import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;

  AudioPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
    _audioPlayer.playerStateStream.listen((playerState) {
      setState(() {
        _isPlaying = playerState.playing;
      });
    });
    _audioPlayer.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _init() async {
    try {
      await _audioPlayer.setUrl(widget.url);
    } catch (e) {
      print("An error occurred: $e");
      // Show an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.seek(Duration.zero); // Reset position to start
                  _audioPlayer.play();
                }
              },
            ),
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: _audioPlayer.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    final sliderValue =
                        position.inMilliseconds > duration.inMilliseconds
                            ? duration.inMilliseconds.toDouble()
                            : position.inMilliseconds.toDouble();
                    return Container(
                      width: 150,
                      // Specify your desired width here
                      child: Slider(
                        activeColor: Colors.white,
                        value: sliderValue,
                        min: 0.0,
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _audioPlayer
                              .seek(Duration(milliseconds: value.round()));
                        },
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<Duration?>(
                stream: _audioPlayer.durationStream,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Text(
                      '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
