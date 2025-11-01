import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickbite/model/category_model.dart';
import 'package:quickbite/model/product_model.dart';
import 'package:quickbite/services/auth_provider.dart';
import 'package:quickbite/services/supabase_service.dart';
import 'package:quickbite/widgets/custom_text_field.dart';
import 'package:quickbite/widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<ProductModel> _products = [];
  late Future<List<CategoryModel>> _categoriesFuture;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = SupabaseService.instance.fetchCategories();
    _searchProducts(); // Initial load (empty)

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchProducts();
      });
    });
  }

  Future<void> _searchProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await SupabaseService.instance.fetchProducts(
        searchQuery: _searchController.text,
        categoryId: _selectedCategoryId,
      );
      if (mounted) {
        setState(() {
          _products = result
              .map((data) => ProductModel.fromJson(data))
              .toList();
        });
      }
    } catch (e) {
      // Handle error appropriately
      debugPrint('Error searching products: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/'),
        ),
        title: CustomTextField(
          controller: _searchController,
          autofocus: true,
          hintText: 'Search for restaurants or dishes',
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () => _searchController.clear(),
          ),

          onSubmitted: (value) {
            // Implement search logic here// Handle search submission
            print('Searching for: $value');
          },
        ),
      ),
      body: Column(
        children: [
          // Category Filters
          SizedBox(
            height: 50,
            child: FutureBuilder<List<CategoryModel>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final categories = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1, // +1 for "All"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "All" filter
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            'All',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          checkmarkColor: Colors.white,
                          selected: _selectedCategoryId == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = null;
                            });
                            _searchProducts();
                          },
                        ),
                      );
                    }
                    final category = categories[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),

                      child: ChoiceChip(
                        checkmarkColor: Colors.white,
                        label: Text(
                          category.name,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        selected: _selectedCategoryId == category.id,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? category.id : null;
                          });
                          _searchProducts();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          // Product Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? Center(
                    child: Text(
                      'No products found.',
                      style: GoogleFonts.poppins(),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ProductCard(
                        product: product,
                        currentUserId: currentUser?.id ?? '',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
