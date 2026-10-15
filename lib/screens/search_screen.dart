import 'package:flutter/material.dart';

import '../core/store_api.dart';
import '../widgets/common.dart';
import '../widgets/product_grid.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ابحث عن عطر أو ماركة…',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: _query.isEmpty
          ? const EmptyView(icon: Icons.search, message: 'اكتب اسم العطر أو الماركة')
          : ProductGrid(
              key: ValueKey(_query),
              loader: (p) => StoreApi.search(_query, page: p),
            ),
    );
  }
}
