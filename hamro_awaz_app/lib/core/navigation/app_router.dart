import 'package:go_router/go_router.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/otp_verification_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/citizen/my_complaints_screen.dart';
import '../../screens/citizen/map_view_screen.dart';
import '../../screens/citizen/profile_screen.dart';
import '../../screens/citizen/settings_screen.dart';
import '../../screens/citizen/edit_profile_screen.dart';
import '../../screens/citizen/help_support_screen.dart';
import '../../screens/citizen/about_screen.dart';
import '../../screens/citizen/privacy_policy_screen.dart';
import '../../widgets/main_navigation.dart';
import '../guards/auth_guard.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'];
          final email = state.uri.queryParameters['email'];
          return OTPVerificationScreen(phone: phone, email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          return AuthGuard(
            builder: (user) => MainNavigation(user: user),
          );
        },
      ),
      GoRoute(
        path: '/my-complaints',
        builder: (context, state) {
          return AuthGuard(
            builder: (user) => const MyComplaintsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/map-view',
        builder: (context, state) {
          return AuthGuard(
            builder: (user) => const MapViewScreen(),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          return AuthGuard(
            builder: (user) => ProfileScreen(user: user),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          return AuthGuard(
            builder: (user) => const SettingsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          return AuthGuard(
            builder: (user) => EditProfileScreen(user: user),
          );
        },
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
}

