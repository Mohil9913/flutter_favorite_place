import 'package:favorite_place/views/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends GetxController {
  var user = Rx<User?>(null);
  var favoritePlaces = RxList<String>([]);

  @override
  void onInit() {
    super.onInit();
    user.value = FirebaseAuth.instance.currentUser;
    if (user.value != null) {
      _checkIfUserExists();
    }
  }

  Future<void> _checkIfUserExists() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.value?.uid) // Unique user document
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.value?.uid)
            .set({
          'user_id': user.value?.uid,
          'createdAt': Timestamp.now(),
          'places': [],
        });

        favoritePlaces.value = [];
      } else {
        _fetchFavoritePlaces();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to check or create user document");
      print(e);
    }
  }


  Future<void> _fetchFavoritePlaces() async {
    try {
      // Fetch the user's document
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.value?.uid)
          .get();

      if (userDoc.exists) {
        List<dynamic> placeIds = userDoc['places'] ?? [];
        favoritePlaces.value = [];

        for (String placeId in placeIds) {
          var placeDoc = await FirebaseFirestore.instance
              .collection('places')
              .doc(placeId)
              .get();

          if (placeDoc.exists) {
            var placeData = placeDoc.data();
            favoritePlaces.add(placeData?['title'] ?? 'Unknown Place'); // Store place titles
          }
        }

      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch favorite places");
      print(e);
    }
  }


  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      user.value = userCredential.user;

      // Check if the user exists in Firestore and fetch favorite places
      _checkIfUserExists();

      Get.snackbar("Success", "Logged in via your Google account");
      Get.offAll(HomeScreen());
    } catch (e) {
      Get.snackbar("Login Error", "$e");
      print(e);
    }
  }

  Future<void> addNewPlace({
    required String title,
    required String description,
    required String imageUrl,
    required double latitude,
    required double longitude,
  }) async {
    try {
      String placeId = FirebaseFirestore.instance.collection('places').doc().id;

      await FirebaseFirestore.instance.collection('places').doc(placeId).set({
        'place_id': placeId,
        'user_id': user.value?.uid,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.value?.uid).update({
        'places': FieldValue.arrayUnion([placeId]),
      }).then((_) {
        favoritePlaces.add(placeId);
        Get.snackbar("Success", "Place added successfully!");
      });

    } catch (e) {
      Get.snackbar("Error", "Failed to add new place");
      print(e);
    }
  }

}
