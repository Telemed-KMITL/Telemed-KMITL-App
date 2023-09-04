import "package:firebase_auth/firebase_auth.dart" as firebase;
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:kmitl_telemedicine/kmitl_telemedicine.dart";

import "package:kmitl_telemedicine_staff/access_denied_page.dart";
import "package:kmitl_telemedicine_staff/email_verification_page.dart";
import "package:kmitl_telemedicine_staff/providers.dart";
import "package:kmitl_telemedicine_staff/room_list_page.dart";
import "package:kmitl_telemedicine_staff/signin_page.dart";

class RouteRefreshNotifier extends ChangeNotifier {
  void listener(_, __) => notifyListeners();
}

GlobalKey<NavigatorState> _navRootKey = GlobalKey();
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouteRefreshNotifier();
  ref.listen(firebaseAuthStateProvider, refreshNotifier.listener);
  ref.listen(currentUserProvider, refreshNotifier.listener);

  return GoRouter(
    navigatorKey: _navRootKey,
    initialLocation: "/",
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final firebaseUser = ref.read(firebaseAuthStateProvider).valueOrNull;
      final userSnapshot =
          ref.read(currentUserProvider).unwrapPrevious().valueOrNull;

      final isFirebaseUserLoggedIn = switch (firebaseUser) {
        null => false,
        firebase.User(emailVerified: false, email: final String _) => false,
        _ => true,
      };

      final atRootPage = state.matchedLocation == "/";
      final atAccessDeniedPage = state.matchedLocation == "/access-denied";
      final onAuthRoute = state.matchedLocation.startsWith("/auth");

      if (!isFirebaseUserLoggedIn) {
        return onAuthRoute ? null : "/auth";
      }

      if (userSnapshot != null) {
        final data = userSnapshot.data();

        if (data == null ||
            ![UserRole.admin, UserRole.doctor, UserRole.nurse]
                .contains(data.role)) {
          return "/access-denied";
        }

        if (atRootPage || atAccessDeniedPage || onAuthRoute) {
          return "/roomList";
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => Container(),
      ),
      GoRoute(
        path: "/access-denied",
        builder: (context, state) => const AccessDeniedPage(),
      ),
      GoRoute(
        path: "/auth",
        redirect: (context, state) {
          final firebaseUser = ref.read(firebaseAuthStateProvider).valueOrNull;
          return switch (firebaseUser) {
            firebase.User(emailVerified: false, email: final String _) =>
              "/auth/verify-email",
            _ => "/auth/signin",
          };
        },
        routes: [
          GoRoute(
            path: "signin",
            builder: (context, state) => const SigninPage(),
          ),
          GoRoute(
            path: "verify-email",
            builder: (context, state) => const EmailVerificationPage(),
          ),
        ],
      ),
      GoRoute(
        path: "/roomList",
        builder: (context, state) => const RoomListPage(),
      ),
    ],
  );
});
