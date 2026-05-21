import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/dio_client.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'repositories/complaint_repository.dart';
import 'repositories/document_repository.dart';
import 'repositories/user_profile_repository.dart';
import 'services/auth_service.dart';
import 'services/complaint_service.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runAppGuarded(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ProxyProvider<AuthService, DioClient>(
          update: (_, auth, __) => DioClient(authService: auth),
        ),
        ProxyProvider2<AuthService, DioClient, UserProfileRepository>(
          update: (_, auth, dio, __) => UserProfileRepository(
            dioClient: dio,
            authService: auth,
          ),
        ),
        ProxyProvider2<AuthService, DioClient, DocumentRepository>(
          update: (_, auth, dio, __) => DocumentRepository(
            dioClient: dio,
            authService: auth,
          ),
        ),
        ProxyProvider2<AuthService, DioClient, ComplaintRepository>(
          update: (_, auth, dio, __) => ComplaintRepository(
            dioClient: dio,
            authService: auth,
          ),
        ),
        ProxyProvider<AuthService, ComplaintService>(
          update: (context, auth, previous) =>
              ComplaintService(authService: auth),
        ),
        Provider(create: (_) => LocationService()),
      ],
      child: MaterialApp.router(
        title: 'HamroAwaz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
