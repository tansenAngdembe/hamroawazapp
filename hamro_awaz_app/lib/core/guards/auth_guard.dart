import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../screens/auth/login_screen.dart';
import '../utils/debug_helper.dart';

class AuthGuard extends StatefulWidget {
  final Widget Function(User user) builder;

  const AuthGuard({
    super.key,
    required this.builder,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  User? _user;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      DebugHelper.log('AuthGuard: Checking authentication');
      
      // First check if we have stored tokens
      final accessToken = await authService.getAccessToken();
      if (accessToken == null) {
        DebugHelper.log('AuthGuard: No access token found');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
          _errorMessage = 'No authentication token found';
        });
        return;
      }

      // Check authentication with backend
      final authResult = await authService.checkAuth();
      DebugHelper.log('AuthGuard: Auth check result', authResult);

      if (authResult['success'] == true && authResult['authenticated'] == true) {
        // Try to get user from storage first
        User? user = await authService.getStoredUser();
        
        // If no stored user, try to fetch from backend
        if (user == null) {
          DebugHelper.log('AuthGuard: No stored user, fetching profile');
          final profileResult = await authService.getProfile();
          if (profileResult['success'] == true && profileResult['user'] != null) {
            user = profileResult['user'] as User;
          }
        }

        if (user != null) {
          DebugHelper.log('AuthGuard: Authentication successful', user.toJson());
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isAuthenticated = true;
            _user = user;
          });
        } else {
          // If backend confirms authentication, allow entry with a minimal user
          // model so the app does not force re-login on app launch.
          user = User(
            id: '0',
            name: 'Citizen',
            email: '',
            role: UserRole.citizen,
          );
          DebugHelper.log('AuthGuard: Authenticated with fallback user', user.toJson());
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isAuthenticated = true;
            _user = user;
            _errorMessage = null;
          });
        }
      } else {
        DebugHelper.log('AuthGuard: Authentication failed', authResult);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
          _errorMessage = authResult['message'] ?? 'Authentication failed';
        });
      }
    } catch (e) {
      DebugHelper.logError('AuthGuard: Error during authentication check', e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAuthenticated = false;
        _errorMessage = 'Authentication error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authentication...'),
            ],
          ),
        ),
      );
    }

    if (!_isAuthenticated || _user == null) {
      DebugHelper.log('AuthGuard: Redirecting to login', {
        'isAuthenticated': _isAuthenticated,
        'hasUser': _user != null,
        'errorMessage': _errorMessage,
      });
      
      // Show error message if available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_errorMessage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
      
      return const LoginScreen();
    }

    DebugHelper.log('AuthGuard: User authenticated, showing protected content');
    return widget.builder(_user!);
  }
}