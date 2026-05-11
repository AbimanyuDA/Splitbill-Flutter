import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/split_bill_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const SplitBillApp());
}

class SplitBillApp extends StatelessWidget {
  const SplitBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SplitBillProvider(),
      child: MaterialApp(
        title: 'Splitbill',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF4361EE),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
