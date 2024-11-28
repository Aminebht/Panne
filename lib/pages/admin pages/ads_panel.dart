import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AdvertisingPanelPage extends StatefulWidget {
  @override
  _AdvertisingPanelPageState createState() => _AdvertisingPanelPageState();
}

class _AdvertisingPanelPageState extends State<AdvertisingPanelPage> {
  final List<Map<String, dynamic>> _mediaItems = List.generate(
    5,
    (_) => {'url': null, 'type': null, 'controller': null},
  );
  final List<TextEditingController> _linkControllers =
      List.generate(5, (_) => TextEditingController());
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  // Target aspect ratio (9:16)
  final double targetAspectRatio = 16 / 9;
  final double aspectRatioTolerance = 0.1; // 10% tolerance

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<bool> _validateImageAspectRatio(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return false;

    final double aspectRatio = image.width / image.height;
    final double difference = (aspectRatio - targetAspectRatio).abs();

    return difference <= aspectRatioTolerance;
  }

  Future<bool> _validateVideoAspectRatio(File videoFile) async {
    final VideoPlayerController controller = VideoPlayerController.file(videoFile);
    await controller.initialize();

    final double aspectRatio = controller.value.size.width / controller.value.size.height;
    final double difference = (aspectRatio - targetAspectRatio).abs();

    await controller.dispose();
    return difference <= aspectRatioTolerance;
  }

  Future<void> _showInvalidFormatDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Format'),
          content: Text('Please upload media with a 16:9 aspect ratio (portrait format).'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

Future<void> _loadData() async {
  try {
    setState(() {
      _isLoading = true;
    });

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('adsPanel')
        .doc('advertisements')
        .get();

    if (doc.exists) {
      // Debug print to see the raw data
      print("Raw document data: ${doc.data()}");
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> ads = data['ads'] as List<dynamic>;
      
      // Debug print for ads data
      print("Ads data: $ads");
      print("Number of ads: ${ads.length}");

      // Reset existing media items
      for (int i = 0; i < _mediaItems.length; i++) {
        if (_mediaItems[i]['controller'] != null) {
          await _mediaItems[i]['controller']?.dispose();
        }
        _mediaItems[i] = {'url': null, 'type': null, 'controller': null};
        _linkControllers[i].clear();
      }

      // Load ads from the list
      for (int i = 0; i < ads.length && i < _mediaItems.length; i++) {
        Map<String, dynamic> adData = ads[i] as Map<String, dynamic>;
        
        // Debug print for each ad
        print("Loading ad $i: $adData");

        setState(() {
          _mediaItems[i] = {
            'url': adData['mediaUrl'],
            'type': adData['mediaType'],
            'controller': null
          };
          _linkControllers[i].text = adData['link'] ?? '';
        });

        // Initialize video controller if it's a video
        if (adData['mediaType'] == 'video' && adData['mediaUrl'] != null) {
          await _initializeVideoController(i, adData['mediaUrl']);
        }
      }
    }
  } catch (e, stackTrace) {
    // Enhanced error logging
    print("Error loading data: $e");
    print("Stack trace: $stackTrace");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error loading media items: $e")),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// Update the save method to match the list structure
Future<void> _saveData() async {
  try {
    List<Map<String, dynamic>> adsList = [];

    for (int i = 0; i < _mediaItems.length; i++) {
      if (_mediaItems[i]['url'] != null) {
        adsList.add({
          'mediaUrl': _mediaItems[i]['url'],
          'mediaType': _mediaItems[i]['type'],
          'link': _linkControllers[i].text.isNotEmpty ? _linkControllers[i].text : null,
        });
      }
    }

    await FirebaseFirestore.instance
        .collection('adsPanel')
        .doc('advertisements')
        .set({'ads': adsList});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data saved successfully!")),
    );
  } catch (e) {
    print("Error saving data: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error saving data: $e")),
    );
  }
}

  Future<void> _initializeVideoController(int index, String videoUrl) async {
    // ignore: deprecated_member_use
    final controller = VideoPlayerController.network(videoUrl);
    await controller.initialize();
    setState(() {
      _mediaItems[index]['controller'] = controller;
    });
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);

      // Validate aspect ratio
      final isValidRatio = await _validateImageAspectRatio(file);
      if (!isValidRatio) {
        await _showInvalidFormatDialog();
        return;
      }

      // Compress and upload image
      final compressedImage = await _compressImage(file);
      await _uploadMedia(index, compressedImage, 'image');
    }
  }

  Future<void> _pickVideo(int index) async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);

      // Validate aspect ratio
      final isValidRatio = await _validateVideoAspectRatio(file);
      if (!isValidRatio) {
        await _showInvalidFormatDialog();
        return;
      }

      // Compress and upload video
      final compressedVideo = await _compressVideo(file);
      await _uploadMedia(index, compressedVideo, 'video');
    }
  }

  Future<File> _compressImage(File file) async {
  // Compress the image
  final result = await FlutterImageCompress.compressWithFile(
    file.absolute.path,
    minWidth: 800, // Adjust width to reduce size
    minHeight: 600, // Adjust height to reduce size
    quality: 85, // Adjust quality to reduce file size
  );

  // If compression is successful, return the compressed file, otherwise return the original file
  if (result != null) {
    return File(file.path)..writeAsBytesSync(result);
  } else {
    return file; // Return the original file if compression fails
  }
}

  Future<File> _compressVideo(File file) async {
    // Placeholder: Implement a suitable video compression function
    // e.g., use FFmpeg or a Dart-compatible solution for video compression
    return file; // Returning original file if no compression solution available
  }

  Future<void> _uploadMedia(int index, File file, String type) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('ads/${DateTime.now().toString()}_${file.path.split('/').last}');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _mediaItems[index]['url'] = downloadUrl;
        _mediaItems[index]['type'] = type;

        if (type == 'video') {
          _initializeVideoController(index, downloadUrl);
        }
      });
    } catch (e) {
      print("Error uploading media: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading media")),
      );
    }
  }

  void _deleteMedia(int index) async {
    if (_mediaItems[index]['controller'] != null) {
      await _mediaItems[index]['controller'].dispose();
    }

    setState(() {
      _mediaItems[index] = {'url': null, 'type': null, 'controller': null};
      _linkControllers[index].clear();
    });
  }


  Widget _buildMediaPreview(int index) {
    if (_mediaItems[index]['url'] == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              '16:9 format',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_mediaItems[index]['type'] == 'video') {
      if (_mediaItems[index]['controller'] != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            AspectRatio(
              aspectRatio: targetAspectRatio,
              child: VideoPlayer(_mediaItems[index]['controller']),
            ),
            Center(
              child: IconButton(
                icon: Icon(
                  _mediaItems[index]['controller'].value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _mediaItems[index]['controller'].value.isPlaying
                        ? _mediaItems[index]['controller'].pause()
                        : _mediaItems[index]['controller'].play();
                  });
                },
              ),
            ),
          ],
        );
      }
      return Center(child: CircularProgressIndicator());
    }

    return Image.network(
      _mediaItems[index]['url']!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Future<void> _pickMedia(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose media type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Advertising Panel"),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: _isLoading
        ? Center(child: SpinningImage(),)
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Import 5 images or videos (16:9 format)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _mediaItems[index]['url'] == null
                                  ? () => _pickMedia(index)
                                  : null,
                              child: Container(
                                height: 100, // Increased height for better 9:16 preview
                                margin: EdgeInsets.only(top: 10, right: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: _buildMediaPreview(index),
                                    ),
                                    if (_mediaItems[index]['url'] != null)
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.delete, color: Colors.white),
                                              onPressed: () => _deleteMedia(index),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _linkControllers[index],
                              decoration: const InputDecoration(
                                hintText: "Add your link here",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 150,
                    child:ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF235A81), // Button color
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                   alignment: Alignment.center,
                ),
                    child: Text("Save",style: TextStyle(color: Colors.white,fontSize: 22),),
                  ),
                  ),
                ),
              ],
            ),
          ),
  );
}

  @override
  void dispose() {
    for (var mediaItem in _mediaItems) {
      mediaItem['controller']?.dispose();
    }
    super.dispose();
  }
}

  