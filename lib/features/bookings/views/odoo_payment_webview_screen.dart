import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';

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
  WebViewController? _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _hasTriggeredSuccess = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  Future<void> _initWebViewController() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF7F5F0))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
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
            _checkUrlForSuccess(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('🔴 [WebView] Resource error: ${error.description}');
          },
        ),
      );

    final Map<String, String> requestHeaders = {};

    try {
      final odooService = Provider.of<BaseOdooService>(context, listen: false);
      final cookies = await odooService.getCookies();
      final uri = Uri.parse(widget.url);
      final cookieManager = WebViewCookieManager();
      final List<String> cookiePairs = [];

      for (final c in cookies) {
        cookiePairs.add('${c.name}=${c.value}');
        debugPrint(
          '🍪 [WebView] Injecting cookie: ${c.name}=${c.value} for domain ${uri.host}',
        );
        try {
          await cookieManager.setCookie(
            WebViewCookie(
              name: c.name,
              value: c.value,
              domain: uri.host,
              path: c.path ?? '/',
            ),
          );
        } catch (_) {}
      }

      if (cookiePairs.isNotEmpty) {
        requestHeaders['Cookie'] = cookiePairs.join('; ');
      }
    } catch (e) {
      debugPrint('Error preparing WebView cookies: $e');
    }

    debugPrint(
      '🌐 [WebView] Loading URL: ${widget.url} with headers: $requestHeaders',
    );
    await controller.loadRequest(
      Uri.parse(widget.url),
      headers: requestHeaders,
    );

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  bool _checkUrlForSuccess(String url) {
    if (_hasTriggeredSuccess) return true;

    final lowerUrl = url.toLowerCase();
    final bool isSuccess =
        lowerUrl.contains('message=pay_ok') ||
        lowerUrl.contains('message=sign_ok') ||
        lowerUrl.contains('payment/status') ||
        lowerUrl.contains('payment/done') ||
        lowerUrl.contains('payment_success') ||
        lowerUrl.contains('status=paid') ||
        lowerUrl.contains('payment_status=paid') ||
        lowerUrl.contains('state=paid') ||
        lowerUrl.contains('tx_status=done') ||
        lowerUrl.contains('tx_status=authorized') ||
        lowerUrl.contains('/payment/confirmation') ||
        lowerUrl.contains('success=true');

    if (isSuccess) {
      debugPrint('🟢 [WebView] Payment completion detected in URL: $url');
      _completePaymentAndReturn();
      return true;
    }
    return false;
  }

  Future<void> _completePaymentAndReturn() async {
    if (_hasTriggeredSuccess) return;
    _hasTriggeredSuccess = true;
    widget.onPaymentSuccess();

    // Delay 2.5 seconds to display Odoo's "Thank You! Your payment has been processed" page
    // and allow Odoo's Python server to complete dispatching the FCM push notification before routing.
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleGoBack() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
    } else {
      if (mounted) {
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleGoBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D1813),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleGoBack,
            tooltip: 'Go Back',
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
              onPressed: () => _controller?.reload(),
              tooltip: 'Refresh Page',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
              tooltip: 'Close',
            ),
          ],
        ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _controller != null
                ? WebViewWidget(controller: _controller!)
                : const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC4913F)),
                  ),
          ),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                  backgroundColor: const Color(0xFF2A231C),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFC4913F),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1D1813),
            border: Border(top: BorderSide(color: Color(0xFF332A1F), width: 1)),
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
              InkWell(
                onTap: _completePaymentAndReturn,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4913F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Done with Payment',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
