import 'package:flutter/material.dart';

import '../core/cart.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), CategoriesScreen(), SearchScreen(), CartScreen()],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          final count = Cart.instance.count;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (v) => setState(() => _index = v),
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
              const NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'الأقسام'),
              const NavigationDestination(
                  icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'البحث'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag),
                ),
                label: 'السلة',
              ),
            ],
          );
        },
      ),
    );
  }
}
