import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickbite/model/product_model.dart';
import 'package:quickbite/services/supabase_service.dart';
import 'package:quickbite/theme/app_colors.dart';
import 'package:quickbite/widgets/loading_widget.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final String currentUserId;
  final VoidCallback? onTap;
  final void Function(bool isFavorite)? onFavoriteChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.currentUserId,
    this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    if (widget.currentUserId.isEmpty || widget.product.id == null) return;
    final isFav = await SupabaseService.instance.isFavorite(
      widget.currentUserId,
      widget.product.id!,
    );
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    if (widget.currentUserId.isEmpty || widget.product.id == null) return;
    setState(() => _loading = true);

    try {
      if (_isFavorite) {
        await SupabaseService.instance.removeFavorite(
          widget.currentUserId,
          widget.product.id!,
        );
      } else {
        await SupabaseService.instance.addFavorite(
          widget.currentUserId,
          widget.product.id!,
        );
      }

      // Verify the new state from the database
      final newFavState = await SupabaseService.instance.isFavorite(
        widget.currentUserId,
        widget.product.id!,
      );

      if (!mounted) return;
      setState(() {
        _isFavorite = newFavState;
      });

      widget.onFavoriteChanged?.call(_isFavorite);
    } catch (e) {
      // You might want to show a snackbar or log the error
      debugPrint('Error toggling favorite: $e');
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          // Navigator.of(context).push(
          //   PageRouteBuilder(
          //     pageBuilder: (context, animation, secondaryAnimation) =>
          //         ProductDetailScreen(productId: widget.product.id ?? ''),
          //     transitionsBuilder:
          //         (context, animation, secondaryAnimation, child) {
          //           return FadeTransition(opacity: animation, child: child);
          //         },
          //   ),
          // );
        }
      },
      child: Container(
        width: 200,
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child:
                      widget.product.imageUrl.isNotEmpty &&
                          widget.product.imageUrl.first.startsWith('http')
                      ? Hero(
                          tag: 'product-images-${widget.product.id}',
                          child: CachedNetworkImage(
                            imageUrl: widget.product.imageUrl.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.tertiary,
                              child: Center(
                                child: LoadingIndicator(
                                  message: 'Loading...',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surface,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppColors.textLight,
                            size: 48,
                          ),
                        ),
                ),
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.only(
                top: 4,
                right: 8,
                left: 8,
                bottom: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // Title
                  Text(
                    widget.product.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Category Badge
                  Container(
                    padding: EdgeInsets.all(6),
                    margin: EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.product.category,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Price and Favorite Button
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Price
                  Text(
                    '₦${widget.product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                  // Favorite Button
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,

                            color: _isFavorite
                                ? AppColors.primaryBlue
                                : Colors.grey[600],
                            size: 18,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Favorite Button
      ),
    );
  }
}
