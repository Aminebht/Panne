import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({Key? key}) : super(key: key);

  @override
  _AdBannerState createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId:
          'ca-app-pub-1710240061961493/9424285915', // Replace with your actual ad unit ID
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
          print('Ad failed to load: ${error.code} - ${error.message}');
          print('Response Info: ${error.responseInfo}');
        },
      ),
      request: AdRequest(),
    );
    _bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded) {
      return Container(
        height: _bannerAd.size.height.toDouble(),
        width: _bannerAd.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd),
      );
    } else {
      return SizedBox
          .shrink(); // Return an empty widget if the ad is not loaded
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}
