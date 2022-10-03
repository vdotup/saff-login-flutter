import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:saff_login/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String password;
  final bool usingBiometrics;

  const HomeScreen(
      {super.key,
      required this.username,
      required this.password,
      required this.usingBiometrics});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  Position? _position;
  bool usingBiometrics = false;
  final Position _saffPosition = Position(
      latitude: 24.830718089079713,
      longitude: 46.63728652666813,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0);
  double? _distance;
  bool _punchedIn = false;
  bool _punchedOut = false;
  DateTime? _punchInTime;
  DateTime? _punchOutTime;

  @override
  void initState() {
    super.initState();
    usingBiometrics = widget.usingBiometrics;
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position? position = await _determinePosition();
    if (position == null) {
      print("no perm");
      return;
    }
    setState(() {
      _position = position;
    });
  }

  Future<Position?> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      print("granted");
      return await Geolocator.getCurrentPosition();
    } else {
      print("denied check permissions");

      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        print("allowed");
        return await Geolocator.getCurrentPosition();
      } else if (permission == LocationPermission.denied) {
        return Future.error("Location Permissions are denied");
      } else if (permission == LocationPermission.deniedForever) {
        print("deniedForever");
        showCupertinoDialog(
            context: context,
            builder: ((context) {
              return CupertinoAlertDialog(
                title: const Text("Location permission needed."),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("Enable in Settings"),
                    onPressed: () {
                      Geolocator.openLocationSettings();
                    },
                  ),
                  CupertinoDialogAction(
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            }));
      } else {
        return Future.error("Location Permissions are denied");
      }
    }
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
        if (availableBiometrics.contains(BiometricType.face)) {
          print("FaceID");
          final authenticated = await auth.authenticate(
              localizedReason: "Enable Face ID to sign in more easily");
          if (authenticated) {
            storage.write(key: "username", value: widget.username);
            storage.write(key: "password", value: widget.password);
            storage.write(key: "usingBiometrics", value: "true");
            setState(() {
              usingBiometrics = true;
            });
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
            storage.write(key: "username", value: widget.username);
            storage.write(key: "password", value: widget.password);
            storage.write(key: "usingBiometrics", value: "true");
            setState(() {
              usingBiometrics = true;
            });
          }
        }
      }
    }
  }

  void _calcDistance() {
    if (_position == null) {
      return;
    }
    Position position = _position!;
    double distance = Geolocator.distanceBetween(_saffPosition.latitude,
        _saffPosition.longitude, position.latitude, position.longitude);
    setState(() {
      _distance = distance;
    });
  }

  void punchIn() async {
    Position? position = await _determinePosition();
    if (position == null) {
      print("no perm");
      return;
    }
    setState(() {
      _position = position;
    });
    double distance = Geolocator.distanceBetween(_saffPosition.latitude,
        _saffPosition.longitude, position.latitude, position.longitude);
    setState(() {
      _distance = distance;
    });
    if (distance > 10) {
      print("not in work");
      showCupertinoDialog(
          context: context,
          builder: ((context) {
            return CupertinoAlertDialog(
              title: const Text("You can only punch in at work location."),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Continue"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          }));
    } else {
      print(DateTime.now());
      setState(() {
        _punchedIn = true;
        _punchInTime = DateTime.now();
      });
    }
  }

  void punchOut() async {
    Position? position = await _determinePosition();
    if (position == null) {
      print("no perm");
      return;
    }
    setState(() {
      _position = position;
    });
    double distance = Geolocator.distanceBetween(_saffPosition.latitude,
        _saffPosition.longitude, position.latitude, position.longitude);
    setState(() {
      _distance = distance;
    });
    if (distance > 10) {
      print("not in work");
      showCupertinoDialog(
          context: context,
          builder: ((context) {
            return CupertinoAlertDialog(
              title: const Text("You can only punch out at work location."),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Continue"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          }));
    } else {
      setState(() {
        _punchedOut = true;
        _punchOutTime = DateTime.now();
      });
    }
  }

  void logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return const LoginScreen();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SAFF"),
        backgroundColor: const Color.fromARGB(255, 16, 99, 55),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Padding(
          padding:
              const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("resources/Logo.png"),
              const SizedBox(
                height: 60,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    onPressed: logout,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      fixedSize: const Size.fromHeight(60),
                    ),
                    child: const Text(
                      "Logout",
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
                    onPressed: usingBiometrics ? null : authenticate,
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
                        Text(
                          usingBiometrics
                              ? "Biometrics Enabled"
                              : "Enable Biometrics",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                  "SAFF location: ${_saffPosition.longitude.toStringAsFixed(2)}, ${_saffPosition.latitude.toStringAsFixed(2)}"),
              Text(
                  "user location: ${_position?.longitude.toStringAsFixed(2)}, ${_position?.latitude.toStringAsFixed(2)}"),
              Text("distance: $_distance"),
              SizedBox(height: 50),
              Text(_punchedIn
                  ? "Punch In: at: ${_punchInTime.toString()}"
                  : "Punch In: not yet."),
              Text(_punchedOut
                  ? "Punch Out: at: ${_punchOutTime.toString()}"
                  : "Punch Out: not yet."),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    onPressed: punchIn,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 16, 99, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      fixedSize: const Size.fromHeight(60),
                    ),
                    child: const Text(
                      "Punch In",
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
                    onPressed: punchOut,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 16, 99, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      fixedSize: const Size.fromHeight(60),
                    ),
                    child: const Text(
                      "Punch Out",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
