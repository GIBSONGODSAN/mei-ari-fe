import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:meiarife/screens/fingerprint/home_page.dart';

class AuthPath extends StatefulWidget {
  const AuthPath({super.key});

  @override
  _AuthPathState createState() => _AuthPathState();
}

class _AuthPathState extends State<AuthPath> {
  bool? _hasBioSensor;

  LocalAuthentication authentication = LocalAuthentication();

  Future<void> _checkBio() async {
    try {
      _hasBioSensor = await authentication.canCheckBiometrics;

      print(_hasBioSensor);

      if (_hasBioSensor!) {
        _getAuth();
      }
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> _getAuth() async {
    bool isAuth = false;

    try {
      isAuth = await authentication.authenticate(
        localizedReason: 'Scan your fingerprint to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true, // Allow only biometric authentication
          stickyAuth: true, // Keep auth active across app restarts
          sensitiveTransaction: false, // Set to true for high-security actions
        ),
      );

      if (isAuth) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (builder) => HomePage()),
        );
      } else {
        print("Authentication failed or canceled.");
      }
    } on PlatformException catch (e) {
      print("Authentication error: $e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // call method immediately when app launch
    _checkBio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Flutter Local Fingerprint Auth',
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.only(left: 10, right: 10),
            height: 70,
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: () {
                _checkBio();
              },
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: Colors.green,
              ),
              child: const Text('Check Auth'),
            ),
          ),
        ],
      ),
    );
  }
}
