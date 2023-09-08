import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmitl_telemedicine_patient/pages/visit_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const String path = "/home";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _pageIdx;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageIdx = 0;
    _pageController = PageController(initialPage: _pageIdx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [_buildHomePage(), _buildVisitPage(), _buildUserPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) => setState(() {
          _pageIdx = i;
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }),
        currentIndex: _pageIdx,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent_outlined),
            activeIcon: Icon(Icons.support_agent),
            label: "Visit",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: "User",
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Container();
  }

  Widget _buildVisitPage() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text("Waiting Time (Estimated):"),
                  const Text("10 min."),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  context.push(VisitPage.path);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Visit Now"),
                    SizedBox(width: 10),
                    Icon(Icons.call),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserPage() {
    return TextButton(
      onPressed: () {
        FirebaseAuth.instance.signOut();
      },
      child: const Text("Logout"),
    );
  }
}
