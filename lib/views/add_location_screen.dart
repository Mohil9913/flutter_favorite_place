import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart' as dio;
import 'package:favorite_place/views/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://jadbdjrldcfcrkeboxge.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphZGJkanJsZGNmY3JrZWJveGdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ0MTU4MDYsImV4cCI6MjA0OTk5MTgwNn0.ywPQHYKzzWjEK-8ZFeqETMH3CKqypK2EMX_g5G6u2Xk';

class AddLocationScreen extends StatefulWidget {
  @override
  _AddLocationScreenState createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  XFile? image;
  Position? currentPosition;
  var isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeSupabase();
  }

  Future<void> initializeSupabase() async {
    await Supabase.initialize(
      url: 'https://jadbdjrldcfcrkeboxge.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphZGJkanJsZGNmY3JrZWJveGdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ0MTU4MDYsImV4cCI6MjA0OTk5MTgwNn0.ywPQHYKzzWjEK-8ZFeqETMH3CKqypK2EMX_g5G6u2Xk',
    );
  }

  Future<void> pickImage(bool isCapture) async {
    final picker = ImagePicker();
    XFile? pickedImage;

    if (isCapture) {
      pickedImage = await picker.pickImage(source: ImageSource.camera);
    } else {
      pickedImage = await picker.pickImage(source: ImageSource.gallery);
    }

    if (pickedImage != null) {
      setState(() {
        image = pickedImage;
      });
    }
  }

  Future<String?> uploadImageToSupabase(XFile imageFile) async {
    try {
      final d = dio.Dio();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final filePath = imageFile.path;

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(filePath, filename: fileName),
      });

      final storageBucket = 'images_favorite_place';
      final uploadPath = 'uploads/$fileName';

      final url = '$supabaseUrl/storage/v1/object/$storageBucket/$uploadPath';

      final response = await d.post(
        url,
        data: formData,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $supabaseAnonKey',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = Supabase.instance.client.storage
            .from(storageBucket)
            .getPublicUrl(uploadPath);
        return publicUrl;
      } else {
        Get.snackbar('Upload Failed', 'Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error: $e');
      Get.snackbar('Error', 'Image upload failed: $e');
      return null;
    }
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Location Error", "Location services are disabled.");
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Location Error", "Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Location Error",
          "Location permissions are permanently denied. Please enable them in settings.");
      return;
    }

    // Get current position
    currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> uploadToFirebase(
    String title,
    String description,
    String imageUrl,
    double latitude,
    double longitude,
  ) async {
    firebase_auth.User? currentUser =
        firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Get.snackbar('No User', 'You aren\'t logged in!');
      Get.offAll(LoginScreen());
      return;
    }

    try {
      final newPlace = FirebaseFirestore.instance.collection('places');

      DocumentReference placeDoc = await newPlace.add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      String placeId = placeDoc.id;

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      await userDoc.update({
        'places': FieldValue.arrayUnion([placeId])
      });

      Get.snackbar('Success', 'Place added successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload place: $e');
    }
  }

  Future<void> savePlace() async {
    if (image == null) {
      Get.snackbar("No Image", "Please provide an image");
      return;
    }
    if (titleController.text.isEmpty) {
      Get.snackbar("Empty Title", "Please provide a title");
      return;
    }

    setState(() {
      isLoading = true;
    });

    await getCurrentLocation();
    if (currentPosition == null) {
      Get.snackbar("Location Error", "Unable to get your location.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final imageUrl = await uploadImageToSupabase(image!);

    if (imageUrl == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    uploadToFirebase(
      titleController.text,
      descriptionController.text,
      imageUrl,
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    setState(() {
      isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isLoading
          ? Center(
              child: CupertinoActivityIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 15),
                  child: Center(
                    child: Text(
                      "Add New Place",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: const Text("Choose Image"),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context);
                                pickImage(true); // Capture Image
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.camera),
                                  SizedBox(width: 8),
                                  Text("Camera"),
                                ],
                              ),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context);
                                pickImage(false); // Select from Gallery
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.image),
                                  SizedBox(width: 8),
                                  Text("Gallery"),
                                ],
                              ),
                            ),
                            if (image != null)
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context);
                                  image = null;
                                  setState(() {});
                                },
                                child: Row(
                                  children: const [
                                    Icon(Icons.close),
                                    SizedBox(width: 8),
                                    Text("Remove Image"),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Colors.deepPurpleAccent.withAlpha(80),
                      image: image != null
                          ? DecorationImage(
                              image: FileImage(File(image!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: image == null
                        ? const Center(
                            child: Icon(
                              Icons.file_upload_sharp,
                              size: 50,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: savePlace,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Place"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }
}
