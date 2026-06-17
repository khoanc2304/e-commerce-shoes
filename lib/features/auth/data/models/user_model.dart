import 'package:cloud_firestore/cloud_firestore.dart';

class ShippingAddress {
  final String id;
  final String receiverName;
  final String phoneNumber;
  final String addressLine;
  final String city;

  ShippingAddress({
    required this.id,
    required this.receiverName,
    required this.phoneNumber,
    required this.addressLine,
    required this.city,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiverName': receiverName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'city': city,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: map['id'] ?? '',
      receiverName: map['receiverName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      addressLine: map['addressLine'] ?? '',
      city: map['city'] ?? '',
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String role; // "customer" | "admin"
  final List<ShippingAddress> shippingAddresses;
  final Timestamp? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.role,
    required this.shippingAddresses,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'role': role,
      'shippingAddresses': shippingAddresses.map((x) => x.toMap()).toList(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      role: map['role'] ?? 'customer',
      shippingAddresses: map['shippingAddresses'] != null
          ? List<ShippingAddress>.from((map['shippingAddresses'] as List).map(
              (x) => ShippingAddress.fromMap(x as Map<String, dynamic>),
            ))
          : [],
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    List<ShippingAddress>? shippingAddresses,
    Timestamp? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
