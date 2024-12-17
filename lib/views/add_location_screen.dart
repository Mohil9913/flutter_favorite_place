import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

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

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service is enabled
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
        desiredAccuracy: LocationAccuracy.high);

    Get.snackbar("Current Location Saved",
        "Latitude: ${currentPosition?.latitude}, Longitude: ${currentPosition?.longitude}");
  }

  Future<void> savePlace() async{
    print("\n\nHello\n\n");
    // if (image == null) {
    //   Get.snackbar("No Image", "Please provide an image");
    //   return;
    // }
    // if (titleController.text.isEmpty) {
    //   Get.snackbar("Empty Title", "Please provide a title");
    //   return;
    // }

    setState(() {
      isLoading = true;
    });

    await getCurrentLocation();

    if (currentPosition == null) {
      Get.snackbar("Location Error", "Unable to get your location.");
      return;
    }

    // Add logic to save location here

    setState(() {
      isLoading = false;
    });

    print("Title: ${titleController.text}");
    print("Description: ${descriptionController.text}");
    print("Image Path: ${image?.path}");
    print("Latitude: ${currentPosition?.latitude}");
    print("Longitude: ${currentPosition?.longitude}");

    Get.snackbar("Success", "Place added to list!");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isLoading ? Center(child: CupertinoActivityIndicator(),) : Column(
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
