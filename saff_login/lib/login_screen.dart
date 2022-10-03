import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:saff_login/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = "";
  String password = "";
  bool usingBiometrics = false;

  @override
  void initState() {
    super.initState();
    getSecureStorage();
  }

  void getSecureStorage() async {
    //await storage.deleteAll();

    print("get secure storage");
    final isUsingBiometrics = await storage.read(key: "usingBiometrics");
    print("isUsingBiometrics:$isUsingBiometrics");
    setState(() {
      usingBiometrics = isUsingBiometrics == 'true';
      print("usingBiometrics:$usingBiometrics");
    });
  }

  void authenticate() async {
    print("authenticate");
    final canCheck = await auth.canCheckBiometrics;
    print("canCheck:$canCheck");

    if (canCheck) {
      List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();

      if (Platform.isIOS) {
        print("iOS");
        if (availableBiometrics.isEmpty) {
          print("no biometrics");
          return;
        }
        if (availableBiometrics.contains(BiometricType.face)) {
          print("FaceID");
          final authenticated = await auth.authenticate(
              localizedReason: "Enable Face ID to sign in more easily");
          if (authenticated) {
            final storedUsername = await storage.read(key: "username");
            final storedPassword = await storage.read(key: "password");

            setState(() {
              username = storedUsername ?? "";
              password = storedPassword ?? "";
            });

            _signIn();
          }
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          print("TouchID");
        }
      } else {
        print("android");
        print(availableBiometrics.toString());
        if (availableBiometrics.isNotEmpty) {
          print("FaceID");
          final authenticated = await auth.authenticate(
              localizedReason: "Enable Touch ID to sign in more easily");
          if (authenticated) {
            final storedUsername = await storage.read(key: "username");
            final storedPassword = await storage.read(key: "password");

            setState(() {
              username = storedUsername ?? "";
              password = storedPassword ?? "";
            });

            _signIn();
          }
        }
      }
    }
  }

  void _signIn() {
    print("sign in with user and pass");
    if (username == "saff" && password == "saff") {
      print("success");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return HomeScreen(
          username: username,
          password: password,
          usingBiometrics: usingBiometrics,
        );
      }));
    } else {
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text("incorrect credentials."),
              actions: [
                CupertinoDialogAction(
                  child: Text("Try Again"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("resources/Logo.png"),
              const SizedBox(height: 113),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                    onChanged: ((value) => username = value),
                    decoration: const InputDecoration(labelText: "Username")),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                    onChanged: (value) => password = value,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                    )),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 16, 99, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      fixedSize: const Size.fromHeight(60),
                    ),
                    child: const Text(
                      "Credentials Login",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    onPressed: usingBiometrics ? authenticate : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 16, 99, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      fixedSize: const Size.fromHeight(60),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(children: [
                            Image.asset("resources/FaceID.png"),
                            const SizedBox(
                              width: 8,
                            ),
                            Image.asset("resources/TouchID.png")
                          ]),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Biometrics",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              usingBiometrics
                  ? const Text("")
                  : const Text("Biometrics can be enabled after login."),
            ],
          ),
        ));
  }
}
