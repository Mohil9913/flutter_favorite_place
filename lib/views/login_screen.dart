import 'package:favorite_place/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:favorite_place/controller/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());

    return Scaffold(
      body: Center(
        child: Obx(() {
          if (controller.user.value != null) {
            return HomeScreen();
          } else {
            return Card(
              margin: EdgeInsets.all(16),
              color: Colors.deepPurple.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Please Login to Continue",
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: controller.signInWithGoogle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 12, 0, 12),
                            height: 30,
                            child: Image(
                              image: AssetImage("assets/images/google.png"),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text('Sign in with Google'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
