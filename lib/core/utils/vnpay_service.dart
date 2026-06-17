import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class VNPayService {
  static const String tmnCode = 'EDFNSMG5';
  static const String hashSecret = 'E1BAO74NFR3Y85I0EI4ADA83QQJDVSUT';
  static const String paymentUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String apiUrl = 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction';
  static const String returnUrl = 'https://vnpay-return-url.com';

  /// Generates the VNPay payment URL
  static String generatePaymentUrl({
    required String txnRef,
    required double amountInUsd,
    required String orderInfo,
  }) {
    // Convert USD to VND (Tỷ giá: 1 USD = 25,000 VND)
    final double amountInVnd = amountInUsd * 25000;
    
    // VNPay vnp_Amount is in VND * 100
    final int amountToSend = (amountInVnd * 100).toInt();

    // vnp_CreateDate format: yyyyMMddHHmmss (Múi giờ Việt Nam GMT+7)
    final vietnamTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    final createDate = DateFormat('yyyyMMddHHmmss').format(vietnamTime);

    final Map<String, String> params = {
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': tmnCode,
      'vnp_Amount': amountToSend.toString(),
      'vnp_CreateDate': createDate,
      'vnp_CurrCode': 'VND',
      'vnp_IpAddr': '127.0.0.1',
      'vnp_Locale': 'vn',
      'vnp_OrderInfo': orderInfo.replaceAll(' ', '_'), // Dùng dấu gạch dưới thay cho khoảng trắng để tránh lỗi encode dấu cách
      'vnp_OrderType': 'other',
      'vnp_ReturnUrl': returnUrl,
      'vnp_TxnRef': txnRef,
    };

    // Sắp xếp các tham số theo thứ tự bảng chữ cái abc
    final sortedKeys = params.keys.toList()..sort();

    // Xây dựng chuỗi query thô để băm chữ ký
    final rawDataString = sortedKeys.map((key) {
      return '$key=${Uri.encodeQueryComponent(params[key]!)}';
    }).join('&');

    // Tạo chữ ký số HMAC-SHA512
    final keyBytes = utf8.encode(hashSecret);
    final hmacSha512 = Hmac(sha512, keyBytes);
    final digest = hmacSha512.convert(utf8.encode(rawDataString));
    final secureHash = digest.toString();

    // Trả về URL hoàn chỉnh
    return '$paymentUrl?$rawDataString&vnp_SecureHash=$secureHash';
  }

  /// Verifies signature of parameters received back from VNPay
  static bool verifyResponseSignature(Map<String, String> queryParams) {
    final receivedHash = queryParams['vnp_SecureHash'];
    if (receivedHash == null) return false;

    // Loại bỏ tham số chữ ký ra khỏi danh sách
    final cleanParams = Map<String, String>.from(queryParams)
      ..remove('vnp_SecureHash')
      ..remove('vnp_SecureHashType');

    // Sắp xếp theo bảng chữ cái abc
    final sortedKeys = cleanParams.keys.toList()..sort();

    // Tạo lại chuỗi query thô từ tham số phản hồi
    final rawDataString = sortedKeys.map((key) {
      final val = cleanParams[key]!;
      // Thay thế '+' thành '%20' để đồng bộ với định dạng mã hóa URL của VNPay
      return '$key=${Uri.encodeQueryComponent(val).replaceAll('+', '%20')}';
    }).join('&');

    final keyBytes = utf8.encode(hashSecret);
    final hmacSha512 = Hmac(sha512, keyBytes);
    final digest = hmacSha512.convert(utf8.encode(rawDataString));
    
    return digest.toString().toLowerCase() == receivedHash.toLowerCase();
  }
}
