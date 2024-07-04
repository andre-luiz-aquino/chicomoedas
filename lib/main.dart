import 'package:chicomoedas/dataBase/usuario_db.dart';
import 'package:chicomoedas/dto/usuario_dto.dart';
import 'package:chicomoedas/views/conversor_page.dart';
import 'package:chicomoedas/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _checkIfLoggedIn();
  }

  Future<bool> _checkIfLoggedIn() async {
    final DatabaseUser dbHelper = DatabaseUser();
    final Usuario? usuarioLogado = await dbHelper.getLogado();
    return usuarioLogado != null;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'Chico Moedas',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.grey,
            textTheme: Typography.blackMountainView,
          ),
          home: FutureBuilder<bool>(
            future: _isLoggedIn,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const LoginPage();
              } else if (snapshot.data == true) {
                return const ConversorPage();
              } else {
                return const LoginPage();
              }
            },
          ),
        );
      },
    );
  }
}
