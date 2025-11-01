import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:quickbite/model/category_model.dart';
import 'package:quickbite/model/product_model.dart';
import 'package:quickbite/services/auth_provider.dart';
import 'package:quickbite/theme/app_colors.dart';
import 'package:quickbite/services/supabase_service.dart';
import 'package:quickbite/util/error_handler.dart';
import 'package:quickbite/util/offline_guard.dart';
import 'package:quickbite/widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Future<List<CategoryModel>> _categoriesFuture;
  List<ProductModel> _products = [];

  // ignore: unused_field
  bool _isLoading = true;
  late AnimationController _productController;

  Future<void> _loadProducts() async {
    if (!OfflineGuard.ensureOnline(
      context,
      message: 'Connect to the internet to load products',
    )) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final products = await SupabaseService.instance.fetchProducts();

      if (mounted) {
        setState(() {
          _products = products
              .map((data) => ProductModel.fromJson(data))
              .toList();
          _isLoading = false;
        });
        _productController.reset();
        _productController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showError(
          context,
          e,
          title: 'Products Error',
          onRetry: _loadProducts,
        );
      }
    }
  }

  Future<void> _refreshData() async {
    // This will re-trigger the futures for both products and categories.
    setState(() {
      _categoriesFuture = SupabaseService.instance.fetchCategories();
    });
    await _loadProducts();
  }

  @override
  void initState() {
    super.initState();
    _categoriesFuture = SupabaseService.instance.fetchCategories();
    _loadProducts();
    _productController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // You can now safely use authProvider here
          // ignore: unused_local_variable
          final user = authProvider.currentUser;
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () {
                              // Handle location button press
                            },
                          ),
                          Text(
                            'San Francisco, CA',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),

                          GestureDetector(
                            onTap: () {
                              // Handle notification button press
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.tertiary.withAlpha(120),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.primaryBlue,
                                size: 23,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.go('/search'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search restaurants, dishes...',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Filter Button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // Handle filter button press
                                print('Filter button tapped');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 140,
                        child: PageView.builder(
                          itemCount: 3,
                          controller: PageController(viewportFraction: 1),
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Featured ${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            "Category",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            child: Text(
                              "See All",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
                        child: FutureBuilder<List<CategoryModel>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Center(
                                child: Text('Could not load categories.'),
                              );
                            }

                            final categories = snapshot.data!;

                            if (categories.isEmpty) {
                              return const Center(
                                child: Text('No categories found.'),
                              );
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 80,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 55,
                                              height: 55,
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.tertiary,
                                                shape: BoxShape.circle,
                                              ),

                                              child: const Icon(
                                                // This is a placeholder. You'd map iconName to actual icons.
                                                Icons.fastfood,
                                                color: AppColors.primaryBlue,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              category.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.inversePrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Just For You",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),

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
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
