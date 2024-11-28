import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class AdsCarousel extends StatefulWidget {
  @override
  _AdsCarouselState createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<AdsCarousel> {
  List<Map<String, String>> ads = [];
  int currentIndex = 0;
  VideoPlayerController? _videoController;
  bool isNextMediaLoaded = false;
  bool isMuted = true;
  Timer? imageTimer;

  @override
  void initState() {
    super.initState();
    fetchAds();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    imageTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAds() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('adsPanel')
        .doc('advertisements')
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data.containsKey('ads')) {
        setState(() {
          ads = (data['ads'] as List<dynamic>).map((item) {
            final adItem = item as Map<String, dynamic>;
            return {
              "link": adItem['link']?.toString() ?? '',
              "mediaType": adItem['mediaType']?.toString() ?? '',
              "mediaUrl": adItem['mediaUrl']?.toString() ?? '',
            };
          }).toList();
        });
        showCurrentMedia();
      }
    }
  }

  void showCurrentMedia() {
    if (ads.isEmpty) return;
    
    if (ads[currentIndex]['mediaType'] == 'video') {
      imageTimer?.cancel();
      
      _videoController?.dispose();
      _videoController = null;

      // ignore: deprecated_member_use
      _videoController = VideoPlayerController.network(ads[currentIndex]['mediaUrl']!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.setVolume(isMuted ? 0.0 : 1.0);
            _videoController!.play();
            _videoController!.addListener(_checkVideoCompletion);
          }
        });
    } else {
      imageTimer?.cancel();
      imageTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          switchToNextMedia();
        }
      });
    }
  }

  void _checkVideoCompletion() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    if (duration.inMilliseconds - position.inMilliseconds <= 200) {
      _videoController!.removeListener(_checkVideoCompletion);
      switchToNextMedia();
    }
  }

  void switchToNextMedia() {
    setState(() {
      currentIndex = (currentIndex + 1) % ads.length;
    });
    showCurrentMedia();
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
      _videoController?.setVolume(isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      return Center(child: SpinningImage());
    }

    final ad = ads[currentIndex];

    return GestureDetector(
      onTap: () {
        if (ad['link'] != '' && ad['link']!.isNotEmpty) {
          _launchURL(ad['link']!);
        }
      },
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.width * 9 / 16,
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ad['mediaType'] == 'image'
                  ? Image.network(
                      ad['mediaUrl']!,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return Center(child: SpinningImage());
                        }
                      },
                    )
                  : _videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayer(_videoController!),
                        )
                      : Center(child: SpinningImage()),
            ),
            if (ad['mediaType'] == 'video')
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: toggleMute,
                ),
              ),
          ],
        ),
      ),
    );
  }
}