import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quickbite/model/user_model.dart';
import 'package:quickbite/model/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Create profile row
  Future<void> createProfile({
    required String id,
    required String fullName,
    required String email,
  }) async {
    try {
      // Use upsert to avoid unique conflicts if profile already exists
      await client.from('profiles').insert({
        'id': id,
        'full_name': fullName,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // rethrow so callers can handle or log
      rethrow;
    }
  }

  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  User? get currentUser => client.auth.currentUser;
  SupabaseService._();

  SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception(
        'Supabase client not initialized. Make sure Supabase.initialize() was called in main()',
      );
    }
  }

  bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }

  // sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': username},
      );
    } catch (e) {
      // If profile creation fails, we should clean up the auth user
      rethrow;
    }
  }

  // sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // fetch orders
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final response = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return empty list if table doesn't exist or other errors
      return [];
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      // Return null if table doesn't exist or other errors
      return null;
    }
  }

  // fetch categories
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await client
          .from('categories')
          .select('id, name')
          .order('name', ascending: true);

      final categories = (response as List)
          .map((category) => CategoryModel.fromJson(category))
          .toList();
      return categories;
    } catch (e) {
      return [];
    }
  }

  // Dashboard helpers

  // fetch products
  Future<List<Map<String, dynamic>>> fetchProducts({
    String? searchQuery,
    String? categoryId,
  }) async {
    try {
      var query = client.from('products').select('''
            id,
            name,
            description,
            price,
            categoryId,
            created_at,
            image_url
          ''');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('categoryId', categoryId);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return []; // Return an empty list on error to prevent crashes
    }
  }

  // Storage methodss
  Future<String> uploadProductImage(String filePath) async {
    if (!isInitialized) {
      throw Exception('Supabase not initialized. Please restart the app.');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await client.storage
          .from('product-images')
          .upload(fileName, file);
      return response;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Order management methods
  Future<List<Map<String, dynamic>>> fetchOrdersWithFilters({
    int? limit,
    String? status,
    String? searchQuery,
  }) async {
    // Get all orders first, then filter in Dart
    final response = await client
        .from('orders')
        .select('''
      id, 
      user_id, 
      total_amount, 
      status, 
      created_at,
      updated_at
    ''')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
      response,
    );

    // Apply status filter
    if (status != null && status.isNotEmpty) {
      orders = orders.where((order) => order['status'] == status).toList();
    }

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      orders = orders.where((order) {
        final orderId = order['id'].toString().toLowerCase();
        final userId = order['user_id'].toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return orderId.contains(query) || userId.contains(query);
      }).toList();
    }

    // Apply limit
    if (limit != null && limit > 0) {
      orders = orders.take(limit).toList();
    }

    return orders;
  }

  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async {
    try {
      final response = await client
          .from('orders')
          .select('''
            id, 
            user_id, 
            total_amount, 
            status, 
            created_at,
            updated_at,
            order_items:order_items(
              id,
              product_id,
              quantity,
              price,
              products:products(
                id,
                name,
                price,
                image_url
              )
            )
          ''')
          .eq('id', orderId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await client
        .from('orders')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  Future<void> deleteOrder(String orderId) async {
    // First delete order items
    await client.from('order_items').delete().eq('order_id', orderId);
    // Then delete the order
    await client.from('orders').delete().eq('id', orderId);
  }

  Future<void> addFavorite(String userId, String productId) async {
    await client.from('favorites').insert({
      'user_id': userId,
      'product_id': productId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(String userId, String productId) async {
    await client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<void> removeFavoriteForUser(String userId, String productId) async {
    await client.from('favorites').delete().match({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<bool> isFavorite(String userId, String productId) async {
    final response = await client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    return response != null;
  }

  Future<List<String>> getFavoritesForUser(String userId) async {
    final response = await client
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);
    return List<String>.from(response.map((item) => item['product_id']));
  }

  Future<List<Map<String, dynamic>>> fetchFavoriteProducts(
    String userId,
  ) async {
    try {
      // Use a PostgREST join to fetch the full product details for each favorite
      final response = await client
          .from('favorites')
          .select('products(*)')
          .eq('user_id', userId);

      // The response is a list of objects like: { "products": { ...product_data... } }
      // We need to extract the product data from each object.
      final products = response
          .map((fav) => fav['products'] as Map<String, dynamic>?)
          .where((p) => p != null) // Filter out nulls if a product was deleted
          .cast<Map<String, dynamic>>()
          .toList();
      return products;
    } catch (e) {
      debugPrint('Error fetching favorite products: $e');
      return [];
    }
  }
}
