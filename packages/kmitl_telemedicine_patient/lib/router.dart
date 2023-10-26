import "package:firebase_auth/firebase_auth.dart" as firebase;
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:kmitl_telemedicine_patient/pages/email_verification_page.dart";
import "package:kmitl_telemedicine_patient/pages/home_page.dart";
import "package:kmitl_telemedicine_patient/pages/registration_page.dart";
import "package:kmitl_telemedicine_patient/pages/signin_page.dart";
import "package:kmitl_telemedicine_patient/pages/visit_page.dart";
import "package:kmitl_telemedicine_patient/providers.dart";

class RouteRefreshNotifier extends ChangeNotifier {
  void listener(_, __) => notifyListeners();
}

GlobalKey<NavigatorState> _navRootKey = GlobalKey();
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouteRefreshNotifier();
  ref.listen(firebaseUserProvider, refreshNotifier.listener);
  ref.listen(currentUserProvider, refreshNotifier.listener);

  return GoRouter(
    navigatorKey: _navRootKey,
    initialLocation: "/",
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final firebaseUser = ref.read(firebaseUserProvider);
      final user = ref.read(currentUserProvider);

      if (firebaseUser.isLoading) {
        return null;
      }

      final isFirebaseUserLoggedIn = switch (firebaseUser.valueOrNull) {
        null => false,
        firebase.User(emailVerified: false, email: final String _) => false,
        _ => true,
      };

      final atRootPage = state.matchedLocation == "/";
      final onAuthRoute = state.matchedLocation.startsWith("/auth");

      if (!isFirebaseUserLoggedIn) {
        return onAuthRoute ? null : "/auth";
      }

      if (!user.hasValue || user.requireValue == null) {
        return null;
      }

      if (!user.requireValue!.exists) {
        return state.matchedLocation == RegistrationPage.path
            ? null
            : RegistrationPage.path;
      }

      if (atRootPage || onAuthRoute) {
        return HomePage.path;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => Container(),
      ),
      GoRoute(
        path: "/auth",
        redirect: (context, state) {
          final firebaseUser = ref.read(firebaseUserProvider).valueOrNull;
          return switch (firebaseUser) {
            firebase.User(emailVerified: false, email: final String _) =>
              EmailVerificationPage.path,
            _ => SigninPage.path,
          };
        },
      ),
      GoRoute(
        path: SigninPage.path,
        builder: (context, state) => const SigninPage(),
      ),
      GoRoute(
        path: EmailVerificationPage.path,
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: RegistrationPage.path,
        builder: (context, state) => const RegistrationPage(),
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
