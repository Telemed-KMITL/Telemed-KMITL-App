import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart" as firebase;
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:kmitl_telemedicine/kmitl_telemedicine.dart";

import "package:kmitl_telemedicine_staff/pages/access_denied_page.dart";
import "package:kmitl_telemedicine_staff/pages/email_verification_page.dart";
import "package:kmitl_telemedicine_staff/pages/room_list_page.dart";
import "package:kmitl_telemedicine_staff/pages/signin_page.dart";
import "package:kmitl_telemedicine_staff/pages/video_call_page.dart";
import "package:kmitl_telemedicine_staff/pages/waiting_room_page.dart";
import "package:kmitl_telemedicine_staff/providers.dart";
import "package:pointer_interceptor/pointer_interceptor.dart";

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
      final firebaseUser = ref.read(firebaseAuthStateProvider);
      final userSnapshot =
          ref.read(currentUserProvider).unwrapPrevious().valueOrNull;

      if (firebaseUser.isLoading) {
        return null;
      }

      final isFirebaseUserLoggedIn = switch (firebaseUser.valueOrNull) {
        null => false,
        firebase.User(emailVerified: false, email: final String _) => false,
        _ => true,
      };

      final atRootPage = state.matchedLocation == "/";
      final atAccessDeniedPage = state.matchedLocation == AccessDeniedPage.path;
      final onAuthRoute = state.matchedLocation.startsWith("/auth");

      if (!isFirebaseUserLoggedIn) {
        return onAuthRoute ? null : "/auth";
      }

      if (userSnapshot != null) {
        final data = userSnapshot.data();

        if (data == null ||
            ![UserRole.admin, UserRole.doctor, UserRole.nurse]
                .contains(data.role)) {
          return AccessDeniedPage.path;
        }

        if (atRootPage || atAccessDeniedPage || onAuthRoute) {
          return RoomListPage.path;
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
        path: AccessDeniedPage.path,
        builder: (context, state) => const AccessDeniedPage(),
      ),
      GoRoute(
        path: "/auth",
        redirect: (context, state) {
          final firebaseUser = ref.read(firebaseAuthStateProvider).valueOrNull;
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
        path: RoomListPage.path,
        redirect: (context, state) => switch (state.extra) {
          final String id => "${RoomListPage.path}/$id",
          final DocumentReference<WaitingRoom> roomRef =>
            "${RoomListPage.path}/${roomRef.id}",
          _ => null,
        },
        builder: (context, state) => const RoomListPage(),
        routes: [
          GoRoute(
            path: ":roomId",
            builder: (context, state) => WaitingRoomPage(
              roomRef: KmitlTelemedicineDb.getWaitingRoomRef(
                state.pathParameters["roomId"]!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: VideoCallPage.path,
        redirect: (context, state) =>
            state.extra is DocumentReference<WaitingUser> ? null : "/",
        builder: (context, state) {
          return VideoCallPage(state.extra as DocumentReference<WaitingUser>);
        },
        onExit: (context) async => (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Stack(
              alignment: Alignment.center,
              children: [
                PointerInterceptor(child: SizedBox.expand(child: Container())),
                AlertDialog(
                  title: const Text("Are you leaving this page?"),
                  actions: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: const Text("Yes"),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ))!,
      )
    ],
  );
});
