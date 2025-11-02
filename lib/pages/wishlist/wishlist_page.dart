import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickbite/model/product_model.dart';
import 'package:quickbite/services/auth_provider.dart';
import 'package:quickbite/services/supabase_service.dart';
import 'package:quickbite/widgets/shimmer_widget.dart';
import 'package:quickbite/widgets/product_card.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late Future<List<ProductModel>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      // If user is not logged in, there are no favorites.
      setState(() {
        _favoritesFuture = Future.value([]);
      });
      return;
    }

    setState(() {
      _favoritesFuture = SupabaseService.instance
          .fetchFavoriteProducts(userId)
          .then(
            (productsData) => productsData
                .map((data) => ProductModel.fromJson(data))
                .toList(),
          );
    });
  }

  Future<void> _refreshFavorites() async {
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 15,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                        '/',
                      ); // Fallback to home if there's nothing to pop
                    }
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
                    child: Icon(Icons.arrow_back),
                  ),
                ),
                const SizedBox(width: 85),
                Text(
                  'Wishlist',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 70, left: 15, right: 15),
              child: RefreshIndicator(
                onRefresh: _refreshFavorites,
                child: FutureBuilder<List<ProductModel>>(
                  future: _favoritesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                            ),
                        itemCount: 4,
                        itemBuilder: (context, index) =>
                            const ShimmerProductCard(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }

                    final favoriteProducts = snapshot.data ?? [];

                    if (favoriteProducts.isEmpty) {
                      return Center(
                        child: Text(
                          'Your wishlist is empty.',
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: favoriteProducts.length,
                      itemBuilder: (context, index) {
                        final product = favoriteProducts[index];
                        return ProductCard(
                          product: product,
                          currentUserId: currentUser?.id ?? '',
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
