import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisitPage extends ConsumerStatefulWidget {
  const VisitPage({super.key});

  static const String path = "/visit";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _VisitPageState();
}

class _VisitPageState extends ConsumerState<VisitPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: Container(),
    );
  }
}
