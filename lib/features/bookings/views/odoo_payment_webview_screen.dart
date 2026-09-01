import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OdooPaymentWebviewScreen extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback onPaymentSuccess;

  const OdooPaymentWebviewScreen({
    super.key,
    required this.url,
    this.title = 'Payment Portal',
    required this.onPaymentSuccess,
  });

  @override
  State<OdooPaymentWebviewScreen> createState() =>
      _OdooPaymentWebviewScreenState();
}

class _OdooPaymentWebviewScreenState extends State<OdooPaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _hasTriggeredSuccess = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF7F5F0))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            debugPrint('🌐 [WebView] Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
            _checkUrlForSuccess(url);
          },
          onPageFinished: (String url) {
            debugPrint('🌐 [WebView] Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _checkUrlForSuccess(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🌐 [WebView] Navigation request to: ${request.url}');
            if (_checkUrlForSuccess(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('🔴 [WebView] Resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _checkUrlForSuccess(String url) {
    if (_hasTriggeredSuccess) return true;

    final lowerUrl = url.toLowerCase();
    final bool isSuccess = lowerUrl.contains('message=pay_ok') ||
        lowerUrl.contains('message=sign_ok') ||
        lowerUrl.contains('payment/status') ||
        lowerUrl.contains('payment_success') ||
        lowerUrl.contains('status=paid') ||
        lowerUrl.contains('payment_status=paid') ||
        lowerUrl.contains('state=paid') ||
        lowerUrl.contains('/payment/confirmation') ||
        lowerUrl.contains('success=true');

    if (isSuccess) {
      _hasTriggeredSuccess = true;
      debugPrint('🟢 [WebView] Payment success detected in URL: $url');
      _completePaymentAndReturn();
      return true;
    }
    return false;
  }

  void _completePaymentAndReturn() {
    widget.onPaymentSuccess();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1813),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFC4913F)),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh Page',
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: const Color(0xFF2A231C),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFC4913F),
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && _loadingProgress < 30)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC4913F),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1D1813),
            border: Border(
              top: BorderSide(color: Color(0xFF332A1F), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Secure Odoo Payment Portal',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFFC5B7A1),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _completePaymentAndReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4913F),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Done with Payment',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
