import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VNPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const VNPayWebViewScreen({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  State<VNPayWebViewScreen> createState() => _VNPayWebViewScreenState();
}

class _VNPayWebViewScreenState extends State<VNPayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo WebViewController theo phiên bản mới nhất của webview_flutter (v4+)
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Có thể dùng để vẽ Loading bar
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) {
            // Kiểm tra xem URL chuyển hướng có phải là Return URL đã cấu hình không
            if (request.url.startsWith('https://vnpay-return-url.com')) {
              final uri = Uri.parse(request.url);
              // Đóng màn hình webview và trả toàn bộ query parameters về cho CheckoutScreen xử lý
              Navigator.pop(context, uri.queryParameters);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showCancelConfirmation();
        return false; // Chặn phím Back cứng để yêu cầu người dùng xác nhận
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh Toán VNPay'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelConfirmation,
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy Thanh Toán'),
        content: const Text('Bạn có chắc chắn muốn thoát và hủy thanh toán đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tiếp Tục'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng Dialog
              Navigator.pop(context, null); // Đóng WebView và trả về null (thất bại)
            },
            child: const Text('Đồng Ý Hủy', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
