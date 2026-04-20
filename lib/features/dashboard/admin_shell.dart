import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../shared/services/auth_service.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                right: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.black.withValues(alpha: 0.04)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'SH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Source Hub Africa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _NavButton(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isActive: location == '/dashboard' || location == '/',
                  onTap: () => context.go('/dashboard'),
                ),
                _NavButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  isActive: location == '/products',
                  onTap: () => context.go('/products'),
                ),
                _NavButton(
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  isActive: location == '/categories',
                  onTap: () => context.go('/categories'),
                ),
                _NavButton(
                  icon: Icons.list_alt_outlined,
                  label: 'Orders',
                  isActive: location == '/orders',
                  onTap: () => context.go('/orders'),
                ),
                _NavButton(
                  icon: Icons.confirmation_num_outlined,
                  label: 'Discounts',
                  isActive: location == '/discounts',
                  onTap: () => context.go('/discounts'),
                ),
                const Spacer(),
                const Divider(height: 1),
                _NavButton(
                  icon: Icons.logout_outlined,
                  label: 'Logout',
                  isActive: false,
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Consumer(
                  builder: (context, ref, _) {
                    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
                    return _NavButton(
                      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      label: isDark ? 'Light Mode' : 'Dark Mode',
                      isActive: false,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF7B7F86);
    final activeColor = const Color(0xFF1A73E8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : mutedColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : mutedColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
