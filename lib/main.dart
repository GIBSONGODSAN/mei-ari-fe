import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:meiarife/screens/ui_screens/homescreen.dart';
import 'package:meiarife/screens/app_screen/department_list_screen.dart';
import 'package:meiarife/screens/fingerprint/auth_part.dart';
import 'package:meiarife/screens/app_screen/meiari_home.dart';
import 'package:meiarife/screens/app_screen/login_page.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return BlocProvider(
    //   create: (context) => GetLocationCubit()..initLocation(),
    //   child: MaterialApp(
    //     title: 'Flutter Demo',
    //     theme: ThemeData(primarySwatch: Colors.blue),
    //     home: const MyHomePage(),
    //   ),
    //   // home: CameraScreen(),
    // );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/home': (context) => HomeScreen(),
        '/department': (context) => DepartmentListScreen(),
        '/fingerauth': (context) => AuthPath(),
        '/': (context) => const MeiAriHomeScreen(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
