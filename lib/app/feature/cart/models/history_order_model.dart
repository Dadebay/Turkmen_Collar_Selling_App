// ignore_for_file: unnecessary_null_comparison

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
    return HistoryOrderModel(
      id: json['id'],
      orderCode: json['order_code'],
      status: json['status'],
      customerName: json['customer_name'],
      phone: json['phone'],
      address: json['address'],
      province: json['province'],
      note: json['note'],
      totalCost: json['total_cost'],
      quantity: json['total_quantity'],
      deliveryPrice: json['delivery_price'],
      createdAt: json['created_at'],
      products: (json['products'] as List).map((json) => ProductsModelMini.fromJson(json)).toList(),
    );
  }
}

class ProductsModelMini {
  int? price;
  int? id;
  int? quantity;
  String? image;
  String? name;

  ProductsModelMini({this.name, this.price, this.id, this.quantity, this.image});

  factory ProductsModelMini.fromJson(Map<dynamic, dynamic> json) {
    return ProductsModelMini(
      price: json['price'] ?? '',
      name: json['name'] ?? '',
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      image: json['images'][0] ?? '',
    );
  }
}
