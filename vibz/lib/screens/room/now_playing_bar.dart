// now_playing_bar.dart
import 'package:flutter/material.dart';

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Minimal placeholder — integrate just_audio later
    return Container(
      height: 72,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.music_note, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Now playing', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Artist • Title', style: TextStyle(fontSize: 12)),
            ],
          )),
          IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
        ],
      ),
    );
  }
}
