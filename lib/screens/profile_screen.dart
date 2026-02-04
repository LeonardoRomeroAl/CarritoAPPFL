import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final username = user?.username ?? 'Comprador';
    final initials = username.isNotEmpty
        ? username.substring(0, 2).toUpperCase()
        : 'CO';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header oscuro con avatar y datos
            Container(
              height: 210,
              width: double.infinity,
              color: const Color(0xFF111927),
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Mi perfil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111927),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'comprador@email.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Panel claro con opciones
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF4F7FF),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _ProfileItem(
                      icon: Icons.person_outline,
                      label: 'Datos personales',
                      onTap: () {
                        Navigator.pushNamed(context, '/profile/personal');
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.location_on_outlined,
                      label: 'Direcciones',
                      onTap: () {
                        Navigator.pushNamed(context, '/profile/addresses');
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Facturación',
                      onTap: () {
                        Navigator.pushNamed(context, '/profile/billing');
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.local_shipping_outlined,
                      label: 'Seguimiento',
                      onTap: () {
                        Navigator.pushNamed(context, '/profile/tracking');
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Mis compras',
                      onTap: () {
                        Navigator.pushNamed(context, '/purchases');
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.settings_outlined,
                      label: 'Configuración',
                      onTap: () {
                        Navigator.pushNamed(context, '/profile/settings');
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.logout,
                      label: 'Cerrar sesión',
                      onTap: () {
                        auth.logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Navbar inferior similar al Home, con perfil seleccionado
      bottomNavigationBar: SizedBox(
        height: 78,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(25, 3, 43, 118),
                      offset: Offset(0, -5),
                      blurRadius: 9,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home_outlined),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // Futuro: favoritos desde perfil
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3887BE),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(80, 35, 80, 147),
                            blurRadius: 4,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/purchases');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    color: const Color(0xFF3887BE),
                    onPressed: () {
                      // Ya estamos en perfil
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xFF111927)),
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111927),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}