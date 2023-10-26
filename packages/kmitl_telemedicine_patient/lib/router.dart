import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:kmitl_telemedicine_patient/pages/auth/welcome_page.dart';

import 'package:kmitl_telemedicine_patient/pages/auth/email_verification_page.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/registration_page.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/signin_page.dart';
import 'package:kmitl_telemedicine_patient/pages/auth/signup_page.dart';
import "package:kmitl_telemedicine_patient/pages/home_page.dart";
import "package:kmitl_telemedicine_patient/pages/visit_page.dart";
import "package:kmitl_telemedicine_patient/providers.dart";

import "transition_pages/fade_transition_page.dart";
import "transition_pages/slide_transition_page.dart";

class RouteRefreshNotifier extends ChangeNotifier {
  void listener(_, __) => notifyListeners();
}

GlobalKey<NavigatorState> _navRootKey = GlobalKey();
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouteRefreshNotifier();
  ref.listen(firebaseUserProvider, refreshNotifier.listener);
  ref.listen(currentUserProvider, refreshNotifier.listener);

  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    navigatorKey: _navRootKey,
    initialLocation: "/",
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final firebaseUser = ref.read(firebaseUserProvider);
      final user = ref.read(currentUserProvider).valueOrNull;
      final onAuthRoute = state.matchedLocation.startsWith("/auth");

      if (onAuthRoute) {
        return null;
      }

      if (firebaseUser.isLoading ||
          firebaseUser.hasError ||
          !firebaseUser.hasValue) {
        return null;
      }

      if (firebaseUser.requireValue == null) {
        return onAuthRoute ? null : "/auth";
      }

      if (user == null) {
        return null;
      }

      if (!user.exists) {
        return state.matchedLocation == RegistrationPage.path
            ? null
            : RegistrationPage.path;
      }

      if (onAuthRoute ||
          state.matchedLocation == "/" ||
          state.matchedLocation == EmailVerificationPage.path ||
          state.matchedLocation == RegistrationPage.path) {
        return HomePage.path;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: "/",
        pageBuilder: (context, state) => FadeTransitionPage(
          key: state.pageKey,
          child: const SizedBox(),
        ),
      ),
      GoRoute(
        path: "/auth",
        redirect: (context, state) async {
          if (state.fullPath == "/auth") {
            if (state.uri.queryParameters.entries.any(
                (e) => e.key == "signout" && e.value.toLowerCase() == "true")) {
              await FirebaseAuth.instance.signOut();
            }
          }
          return null;
        },
        builder: (context, state) => WelcomePage(),
        routes: [
          GoRoute(
            path: SigninPage.route,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const SigninPage(),
            ),
          ),
          GoRoute(
            path: SignupPage.route,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const SignupPage(),
            ),
          ),
          GoRoute(
            path: EmailVerificationPage.route,
            redirect: (context, state) async {
              final user = await ref.read(firebaseUserProvider.future);
              return user == null ? "/auth" : null;
            },
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: EmailVerificationPage(
                hasPreviousPage: (state.extra is bool) && (state.extra as bool),
              ),
            ),
          ),
          GoRoute(
            path: RegistrationPage.route,
            redirect: (context, state) async {
              final user = await ref.read(firebaseUserProvider.future);
              return user == null ? "/auth" : null;
            },
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: RegistrationPage(
                hasPreviousPage: (state.extra is bool) && (state.extra as bool),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: HomePage.path,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: VisitPage.path,
        builder: (context, state) {
          return VisitPage(state.pathParameters["visitId"]!);
        },
      ),
    ],
  );
});
