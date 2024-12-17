import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:favorite_place/views/add_location_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot> fetchUserPlaces() {
    return _firestore
        .collection('places')
        .where('createdBy', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Places"),
      ),
      body: Center(
        child: StreamBuilder(
            stream: fetchUserPlaces(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CupertinoActivityIndicator();
              }

              if (snapshot.hasError) {
                log('${snapshot.error}');
                return Text('Something went wrong!');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text("No Places Added Yet!");
              }

              final places = snapshot.data!.docs;

              return ListView.builder(
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 40,
                          child: ClipOval(
                            child: Image.network(
                              place['imageUrl'],
                              fit: BoxFit.cover,
                              height: 60,
                              width: 55,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProcess,
                              ) {
                                if (loadingProcess == null) {
                                  return child;
                                }
                                return Center(
                                  child: CupertinoActivityIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.broken_image_outlined);
                              },
                            ),
                          ),
                        ),
                        title: Text(
                          place['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              try {
                                WriteBatch batch = _firestore.batch();

                                DocumentReference placeRef = _firestore
                                    .collection('places')
                                    .doc(place.id);

                                DocumentReference userRef = _firestore
                                    .collection('users')
                                    .doc(currentUserId);

                                batch.delete(placeRef);

                                batch.update(userRef, {
                                  'places': FieldValue.arrayRemove([place.id]),
                                });

                                await batch.commit();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Place deleted successfully')),
                                );
                              } catch (e) {
                                log('Error deleting place: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed to delete: $e')),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(Icons.more_vert_outlined),
                        ),
                      ),
                    );
                  });
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: AddLocationScreen(),
              );
            },
          );
          setState(() {});
        },
        child: const Icon(CupertinoIcons.plus),
      ),
    );
  }
}
