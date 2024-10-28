import 'dart:convert';
import 'package:flutter/material.dart'; // Import the Material package for BuildContext
import 'package:http/http.dart' as http;
import 'package:panne_auto/konnect/webview_screen.dart';

class KonnectApiService {
  final String _baseUrl = "https://api.preprod.konnect.network/api/v2/payments/init-payment";
  final String apiKey = "671e11b505b326a400542267:m8Z8N2E75vFJPCFFSM028GccI"; // Replace with actual x-api-key 

  Future<void> sendPaymentRequest({
    required BuildContext context, // Accept BuildContext as a parameter
    required int amount,
    required String dropdownValue,
    String receiverWalletId = "671e11b505b326a400542273",
    List<String> acceptedPaymentMethods = const ['wallet', 'bank_card', 'e-DINAR', 'flouci'],
    int lifespan = 10,
  }) async {
    final url = Uri.parse(_baseUrl);

    // Build the JSON payload
    final Map<String, dynamic> payload = {
      "receiverWalletId": receiverWalletId,
      "amount": amount,
      "acceptedPaymentMethods": acceptedPaymentMethods,
      "lifespan": lifespan,
    };

    print("Sending payment request to: $url");
    print("Payload: $payload");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final link = responseData['payUrl']; // Adjust based on actual response structure
        final paymentId =responseData['paymentRef'];
        // Navigate to the WebView screen with the link
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(url: link,paymentId:paymentId,amount:amount,dropdownValue:dropdownValue),
          ),
        );
      } else {
        // Log the error details before throwing an exception
        print("Error: ${response.statusCode} - ${response.body}");
        throw ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      print("Caught an exception: $e");
      throw Exception("Error: $e");
    }
  }
  Future<String> getPaymentStatus(String paymentId) async {
  final url = Uri.parse("https://api.preprod.konnect.network/api/v2/payments/$paymentId");
  
  try {
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['payment']['status']; // Adjust based on the actual response structure
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  } catch (e) {
    print("Error fetching payment status: $e");
    throw Exception("Error: $e");
  }
}

}

// Custom exception class to hold response code and message
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
