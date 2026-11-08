class HistoryOrderModel {
  final int? id;
  final String? orderCode;
  final String? status;
  final String? customerName;
  final String? phone;
  final String? address;
  final String? province;
  final String? note;
  final int? totalCost;
  final int? quantity;
  final int? deliveryPrice;
  final String? createdAt;
  final List<ProductsModelMini>? products;

  HistoryOrderModel({
    this.id,
    this.orderCode,
    this.address,
    this.createdAt,
    this.customerName,
    this.deliveryPrice,
    this.note,
    this.phone,
    this.products,
    this.province,
    this.quantity,
    this.status,
    this.totalCost,
  });

  factory HistoryOrderModel.fromJson(Map<dynamic, dynamic> json) {
    final rawProducts = json['products'];
    final products = rawProducts is List
        ? rawProducts
              .whereType<Map>()
              .map((p) => ProductsModelMini.fromJson(p))
              .toList()
        : <ProductsModelMini>[];
    return HistoryOrderModel(
      id: json['id'] is int ? json['id'] as int : 0,
      orderCode: json['order_code']?.toString(),
      status: json['status']?.toString(),
      customerName: json['customer_name']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      province: json['province']?.toString(),
      note: json['note']?.toString(),
      totalCost: json['total_cost'] is int ? json['total_cost'] as int : 0,
      quantity: json['total_quantity'] is int
          ? json['total_quantity'] as int
          : 0,
      deliveryPrice: json['delivery_price'] is int
          ? json['delivery_price'] as int
          : 0,
      createdAt: json['created_at']?.toString(),
      products: products,
    );
  }
}

class ProductsModelMini {
  final int? price;
  final int? id;
  final int? quantity;
  final String? image;
  final String? name;

  ProductsModelMini({
    this.name,
    this.price,
    this.id,
    this.quantity,
    this.image,
  });

  factory ProductsModelMini.fromJson(Map<dynamic, dynamic> json) {
    final rawImages = json['images'];
    final image = rawImages is List && rawImages.isNotEmpty
        ? rawImages.first?.toString() ?? ''
        : '';
    return ProductsModelMini(
      price: json['price'] is int ? json['price'] as int : 0,
      name: json['name']?.toString() ?? '',
      id: json['id'] is int ? json['id'] as int : 0,
      quantity: json['quantity'] is int ? json['quantity'] as int : 0,
      image: image,
    );
  }
}
