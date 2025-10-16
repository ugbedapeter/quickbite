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
    final response = await client
        .from('orders')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Dashboard helpers
  Future<int> countOrders() async {
    final response = await client.from('orders').select('id');
    return (response as List).length;
  }

  Future<int> countPendingOrders() async {
    final response = await client
        .from('orders')
        .select('id')
        .eq('status', 'pending');
    return (response as List).length;
  }

  Future<List<Map<String, dynamic>>> fetchRecentOrders({int limit = 5}) async {
    final response = await client
        .from('orders')
        .select('id, user_id, total_amount, status')
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchDailySalesRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await client.rpc(
      'daily_sales_range',
      params: {
        'start_ts': start.toIso8601String(),
        'end_ts': end.toIso8601String(),
      },
    );
    final list = (response as List).cast<Map<String, dynamic>>();
    list.sort(
      (a, b) =>
          (a['day'] ?? '').toString().compareTo((b['day'] ?? '').toString()),
    );
    return list
        .map(
          (m) => {
            'day': m['day']?.toString(),
            'total': (m['total'] is num) ? (m['total'] as num).toDouble() : 0.0,
          },
        )
        .toList();
  }

  Future<double> sumTotalSales({int days = 30}) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days));
    final response = await client
        .from('orders')
        .select('total_amount, created_at')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', now.toIso8601String());
    final list = (response as List).cast<Map<String, dynamic>>();
    double sum = 0;
    for (final row in list) {
      final v = row['total_amount'];
      if (v is num) sum += v.toDouble();
    }
    return sum;
  }

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

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required num price,
    required dynamic categoryId,
    String? description,
    String? imageUrl,
  }) async {
    final response = await client
        .from('products')
        .insert({
          'name': name,
          'price': price,
          'category_id': categoryId,
          'description': description,
          'image_url': imageUrl,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateProduct({
    required dynamic id,
    required String name,
    required num price,
    required dynamic categoryId,
    String? description,
    String? imageUrl,
  }) async {
    final response = await client
        .from('products')
        .update({
          'name': name,
          'price': price,
          'category_id': categoryId,
          'description': description,
          'image_url': imageUrl,
        })
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> deleteProduct({required dynamic id}) async {
    await client.from('products').delete().eq('id', id);
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

  String getProductImageUrl(String fileName) {
    return client.storage.from('product-images').getPublicUrl(fileName);
  }

  // fetch categories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await client
        .from('categories')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createCategory({required String name}) async {
    final response = await client
        .from('categories')
        .insert({'name': name})
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateCategory({
    required dynamic id,
    required String name,
  }) async {
    final response = await client
        .from('categories')
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> deleteCategory({required dynamic id}) async {
    await client.from('categories').delete().eq('id', id);
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

  Future<Map<String, dynamic>> getOrderStats() async {
    final totalOrders = await countOrders();
    final pendingOrders = await countPendingOrders();
    final totalRevenue = await sumTotalSales();

    // Get orders by status
    final ordersByStatus = await client.from('orders').select('status').then((
      response,
    ) {
      final Map<String, int> statusCount = {};
      for (var order in response) {
        final status = order['status'] as String? ?? 'unknown';
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }
      return statusCount;
    });

    return {
      'total_orders': totalOrders,
      'pending_orders': pendingOrders,
      'total_revenue': totalRevenue,
      'orders_by_status': ordersByStatus,
    };
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }
}
