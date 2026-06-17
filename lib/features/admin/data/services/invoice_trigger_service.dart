import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Outline for the Invoice Trigger Service.
/// This would typically be executed in a Firebase Cloud Function hooked to the 
/// `orders` onCreate trigger. If doing it directly from client (not recommended for security), 
/// this service bridges to an Email API like SendGrid.
class InvoiceTriggerService {
  final String _sendGridApiKey = 'YOUR_SENDGRID_API_KEY';
  final String _sendGridUrl = 'https://api.sendgrid.com/v3/mail/send';

  Future<void> sendInvoiceEmail({
    required String userEmail,
    required String orderId,
    required double totalAmount,
  }) async {
    final body = {
      "personalizations": [
        {
          "to": [
            {
              "email": userEmail
            }
          ],
          "subject": "Your Invoice for Order #$orderId"
        }
      ],
      "from": {
        "email": "no-reply@shoesx.com",
        "name": "Shoes X"
      },
      "content": [
        {
          "type": "text/html",
          "value": """
          <html>
            <body>
              <h2>Thank you for your purchase!</h2>
              <p>Your order <strong>#$orderId</strong> has been placed successfully.</p>
              <p>Total Paid: <strong>\$${totalAmount.toStringAsFixed(2)}</strong></p>
              <br>
              <p>We will notify you once it ships.</p>
            </body>
          </html>
          """
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(_sendGridUrl),
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 400) {
        // Logging error silently since it's an auxiliary service
        debugPrint('Failed to send invoice: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception while sending invoice: $e');
    }
  }
}
