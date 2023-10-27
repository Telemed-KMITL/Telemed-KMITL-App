import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:kmitl_telemedicine_patient/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const String path = "/home";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _pageIdx = 0;
  final PageController _pageController = PageController(initialPage: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [_buildVisitPage(), _buildUserPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) => _isLoading
            ? null
            : setState(() {
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

  Widget _buildVisitPage() {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed:
                    user == null || _isLoading ? null : () => _onVisit(user.id),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
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
    final theme = Theme.of(context);
    final firebaseUser = ref.watch(firebaseUserProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull?.data();

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 232, 133, 33),
            borderRadius: BorderRadiusDirectional.only(
              bottomStart: Radius.circular(16),
              bottomEnd: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  user?.getDisplayName() ?? "",
                  style: theme.primaryTextTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
            child: ListView(
          padding: const EdgeInsets.all(30),
          children: [
            _buildUneditableField(
              headerText: "Role",
              label: Text(
                user?.role.name ?? "",
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 14),
            _buildUneditableField(
              headerText: "Status",
              label: Text(
                user?.status.name ?? "",
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 14),
            _buildUneditableField(
              headerText: "HN",
              label: Text(
                user?.hn ?? "",
                style: theme.textTheme.labelLarge,
              ),
            ),
            const Divider(height: 40),
            _buildUneditableField(
              headerText: "User ID",
              label: Text(
                firebaseUser?.uid ?? "",
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 14),
            _buildUneditableField(
              headerText: "Email",
              label: Text(
                firebaseUser == null
                    ? ""
                    : "${firebaseUser.email}" +
                        (firebaseUser.emailVerified ? " (Verified)" : ""),
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 30),
            TextButton.icon(
              onPressed: () {
                FirebaseAuth.instance.signOut().ignore();
                context.go("/auth");
              },
              icon: const Icon(Icons.logout),
              label: const Text("Sign Out"),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildUneditableField({required String headerText, Widget? label}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headerText, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          alignment: Alignment.centerLeft,
          child: label,
        ),
      ],
    );
  }

  Future<void> _onVisit(String uid) async {
    setState(() => _isLoading = true);

    final server = await ref.read(kmitlTelemedServerProvider.future);

    late String visitId;
    try {
      final response = await server.getVisitsApi().visitsPost();

      if (response.statusCode != 200) {
        showErrorMessage("HTTP Error: ${response.statusMessage}");
        return;
      }

      visitId = response.data!.visitId;

      if (context.mounted) {
        context.push("/visit/$visitId");
      }
    } on DioException catch (e) {
      showErrorMessage("Internal Error: ${e.message}");
      return;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showErrorMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepOrange,
      ));
    }
  }
}
