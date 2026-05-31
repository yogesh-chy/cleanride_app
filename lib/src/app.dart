import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'config/app_theme.dart';
import 'models/app_user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/staff_dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/payment_service.dart';
import 'services/token_storage.dart';

class CleanRideApp extends StatefulWidget {
  const CleanRideApp({super.key});

  @override
  State<CleanRideApp> createState() => _CleanRideAppState();
}

class _CleanRideAppState extends State<CleanRideApp> {
  late final AuthService _authService;
  late final BookingService _bookingService;
  late final PaymentService _paymentService;
  
  final authNotifier = ValueNotifier<AppUser?>(null);
  bool _checkingSession = true;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    const secureStorage = FlutterSecureStorage();
    final tokenStorage = TokenStorage(secureStorage);
    final apiClient = ApiClient(tokenStorage);
    _authService = AuthService(apiClient, tokenStorage);
    _bookingService = BookingService(apiClient);
    _paymentService = PaymentService(apiClient);

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: authNotifier,
      redirect: (context, state) {
        if (_checkingSession) return null;
        
        final user = authNotifier.value;
        final location = state.matchedLocation;
        final isLoggingIn = location == '/login' || location == '/register';
        final isHome = location == '/';

        if (user == null) {
          if (!isHome && !isLoggingIn) {
            return '/login';
          }
          return null;
        }

        // User is logged in
        if (isLoggingIn || isHome) {
          return user.role == 'staff' ? '/staff' : '/dashboard';
        }

        if (location.startsWith('/dashboard') && user.role == 'staff') {
          return '/staff';
        }
        if (location.startsWith('/staff') && user.role != 'staff') {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(isLoggedIn: authNotifier.value != null),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            authService: _authService,
            onLoggedIn: (user) {
              authNotifier.value = user;
              context.go(user.role == 'staff' ? '/staff' : '/dashboard');
            },
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen(authService: _authService),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => DashboardScreen(
            user: authNotifier.value!,
            bookingService: _bookingService,
            onLogout: _handleLogout,
          ),
        ),
        GoRoute(
          path: '/dashboard/checkout/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CheckoutScreen(
              bookingId: id,
              bookingService: _bookingService,
              paymentService: _paymentService,
            );
          },
        ),
        GoRoute(
          path: '/staff',
          builder: (context, state) => StaffDashboardScreen(
            user: authNotifier.value!,
            bookingService: _bookingService,
            onLogout: _handleLogout,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(
            user: authNotifier.value!,
            authService: _authService,
            onProfileUpdated: (user) {
              authNotifier.value = user;
            },
          ),
        ),
      ],
    );

    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final user = await _authService.me();
      if (mounted) {
        authNotifier.value = user;
      }
    } catch (_) {
      // Ignore session loading failures (e.g. no saved credentials)
    } finally {
      if (mounted) {
        setState(() => _checkingSession = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      authNotifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'CleanRide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
