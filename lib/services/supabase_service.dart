import 'dart:io';
import 'package:quickbite/model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
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

  // Dashboard helpers

  // fetch products
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await client
        .from('products')
        .select(
          'id, name, price, category_id, description, image_url, created_at',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Storage methods
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
}
