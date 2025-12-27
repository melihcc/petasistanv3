import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
// import 'firebase_options.dart'; // User needs to provide this or rely on auto-config if set up

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Uncomment if using flutterfire configure
  );

  runApp(const ProviderScope(child: PetAsistanApp()));
}
