import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/admin_shell.dart';
import '../features/dashboard/dashboard_view.dart';
import '../features/products/products_view.dart';
import '../features/categories/categories_view.dart';
import '../features/orders/orders_view.dart';
import '../features/discounts/discounts_view.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, __) => '/dashboard',
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardView(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsView(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesView(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersView(),
        ),
        GoRoute(
          path: '/discounts',
          builder: (context, state) => const DiscountsView(),
        ),
      ],
    ),
  ],
);
