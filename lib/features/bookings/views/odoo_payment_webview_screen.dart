import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';

class OdooPaymentWebviewScreen extends StatefulWidget {
  final String url;
  final String? token;
  final String title;
  final VoidCallback onPaymentSuccess;

  const OdooPaymentWebviewScreen({
    super.key,
    required this.url,
    this.token,
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
  String? _resolvedToken;

  @override
  void initState() {
    super.initState();
    String t = (widget.token ?? '').trim();
    if (t == 'false' || t == 'null') t = '';
    if (t.isEmpty) {
      final uri = Uri.tryParse(widget.url);
      t = uri?.queryParameters['access_token'] ?? '';
      if (t == 'false' || t == 'null') t = '';
    }
    _resolvedToken = t;
    _initWebViewController();
  }

  Future<void> _injectTokenProtection(
    WebViewController controller, [
    String? currentUrl,
  ]) async {
    String token = _resolvedToken ?? '';
    if (token.isEmpty && currentUrl != null) {
      final uri = Uri.tryParse(currentUrl);
      final t = uri?.queryParameters['access_token'] ?? '';
      if (t.isNotEmpty && t != 'false' && t != 'null') {
        token = t;
        _resolvedToken = t;
      }
    }
    if (token.isEmpty) {
      debugPrint('ℹ️ [WebView] No access_token available for JS token injection.');
      return;
    }

    final js = '''
      (function() {
        try {
          var token = '$token';
          if (!token) return;

          // 1. If URL in address bar is missing access_token, replace state so query string is consistent
          try {
            if (window.location && window.location.search && window.location.search.indexOf('access_token=') === -1) {
              var sep = window.location.href.indexOf('?') === -1 ? '?' : '&';
              window.history.replaceState(null, '', window.location.href + sep + 'access_token=' + encodeURIComponent(token));
            }
          } catch(e) {}

          // 2. Monkey-patch window.fetch (Used by modern Odoo 16/17/18 for all JSON-RPC calls)
          if (!window.__tokenFetchPatched) {
            window.__tokenFetchPatched = true;
            var origFetch = window.fetch;
            window.fetch = async function(input, init) {
              try {
                if (init && init.body && typeof init.body === 'string' && init.body.indexOf('jsonrpc') !== -1) {
                  var data = JSON.parse(init.body);
                  if (data && data.params) {
                    if (!data.params.access_token || data.params.access_token === '' || data.params.access_token === 'false') {
                      data.params.access_token = token;
                      init.body = JSON.stringify(data);
                      console.log('[WebView JS] Injected access_token into fetch JSON-RPC params');
                    }
                  }
                }
              } catch(err) {
                console.warn('[WebView JS] Fetch intercept error:', err);
              }
              return origFetch.apply(this, arguments);
            };
          }

          // 3. Monkey-patch XMLHttpRequest.prototype.send (Used by older Odoo / jQuery calls)
          if (!window.__tokenXhrPatched) {
            window.__tokenXhrPatched = true;
            var origSend = XMLHttpRequest.prototype.send;
            XMLHttpRequest.prototype.send = function(body) {
              try {
                if (body && typeof body === 'string' && body.indexOf('jsonrpc') !== -1) {
                  var json = JSON.parse(body);
                  if (json && json.params && (!json.params.access_token || json.params.access_token === '' || json.params.access_token === 'false')) {
                    json.params.access_token = token;
                    body = JSON.stringify(json);
                    console.log('[WebView JS] Injected access_token into XHR JSON-RPC params');
                  }
                }
              } catch(err) {
                console.warn('[WebView JS] XHR intercept error:', err);
              }
              return origSend.apply(this, [body]);
            };
          }

          // 4. Stamp access_token onto DOM forms, payment containers, and dataset attributes
          function stampTokenOnDOM() {
            try {
              // Ensure all forms have a hidden input named access_token
              document.querySelectorAll('form').forEach(function(f) {
                var inp = f.querySelector('input[name="access_token"]');
                if (!inp) {
                  inp = document.createElement('input');
                  inp.type = 'hidden';
                  inp.name = 'access_token';
                  inp.value = token;
                  f.appendChild(inp);
                } else if (!inp.value || inp.value === 'false') {
                  inp.value = token;
                }
              });

              // Ensure payment containers and transaction route elements have data-access-token
              document.querySelectorAll('[data-access-token], #o_payment_form, .o_payment_form, [data-transaction-route]').forEach(function(el) {
                el.setAttribute('data-access-token', token);
                if (el.dataset) {
                  el.dataset.accessToken = token;
                }
              });

              // Hook PDF download links/buttons so clicks trigger navigation cleanly
              document.querySelectorAll('a[href*="report_type=pdf"], a[href*="download="], a.o_download_btn, [title*="Download"]').forEach(function(el) {
                if (el.getAttribute('data-download-hooked') !== 'true') {
                  el.setAttribute('data-download-hooked', 'true');
                  el.addEventListener('click', function(e) {
                    var href = el.getAttribute('href');
                    if (href) {
                      e.preventDefault();
                      e.stopPropagation();
                      if (href.indexOf('http') !== 0) {
                        href = window.location.origin + href;
                      }
                      if (token && href.indexOf('access_token=') === -1) {
                        href += (href.indexOf('?') === -1 ? '?' : '&') + 'access_token=' + encodeURIComponent(token);
                      }
                      window.location.href = href;
                    }
                  });
                }
              });
            } catch(e) {
              console.warn('[WebView JS] DOM token stamping error:', e);
            }
          }

          // Run immediately
          stampTokenOnDOM();

          // 5. Setup MutationObserver for dynamically mounted OWL payment components
          if (!window.__tokenObserver) {
            window.__tokenObserver = new MutationObserver(function(mutations) {
              stampTokenOnDOM();
            });
            window.__tokenObserver.observe(document.body || document.documentElement, {
              childList: true,
              subtree: true,
            });
          }
        } catch(e) {
          console.error('[WebView JS] Payment token injection error:', e);
        }
      })();
    ''';

    try {
      await controller.runJavaScript(js);
    } catch (jsErr) {
      debugPrint('⚠️ [WebView] JS token injection error: $jsErr');
    }
  }

  Future<void> _initWebViewController() async {
    late final WebViewController controller;
    controller = WebViewController()
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
            if (progress > 50) {
              _injectTokenProtection(controller);
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
            _injectTokenProtection(controller, url);
          },
          onPageFinished: (String url) async {
            debugPrint('🌐 [WebView] Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _checkUrlForSuccess(url);
            await _injectTokenProtection(controller, url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🌐 [WebView] Navigation request to: ${request.url}');
            _checkUrlForSuccess(request.url);

            final lower = request.url.toLowerCase();
            final isDownload = lower.contains('report_type=pdf') ||
                lower.contains('download=true') ||
                lower.endsWith('.pdf') ||
                lower.contains('.pdf?');

            if (isDownload) {
              debugPrint(
                '📥 [WebView] Intercepted PDF download navigation: ${request.url}',
              );
              _handleDownloadUrl(request.url);
              return NavigationDecision.prevent;
            }

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

  Future<void> _handleDownloadUrl(String rawUrl) async {
    try {
      Uri uri = Uri.parse(rawUrl);
      final currentToken = (_resolvedToken != null && _resolvedToken!.isNotEmpty)
          ? _resolvedToken
          : Uri.tryParse(widget.url)?.queryParameters['access_token'];
      final qParams = Map<String, String>.from(uri.queryParameters);
      qParams['report_type'] = 'pdf';
      qParams['download'] = 'true';
      if (currentToken != null &&
          currentToken.isNotEmpty &&
          !qParams.containsKey('access_token')) {
        qParams['access_token'] = currentToken;
      }
      uri = uri.replace(queryParameters: qParams);

      debugPrint('📥 [WebView] Launching invoice PDF download: $uri');
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening invoice PDF in browser to download...'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 [WebView] Error launching download: $e');
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
              icon: const Icon(Icons.download_rounded, color: Color(0xFFC4913F)),
              onPressed: () => _handleDownloadUrl(widget.url),
              tooltip: 'Download Invoice PDF',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
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
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _controller != null
                    ? WebViewWidget(controller: _controller!)
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC4913F),
                        ),
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
                      value: _loadingProgress > 0
                          ? _loadingProgress / 100.0
                          : null,
                      backgroundColor: const Color(0xFF2A231C),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFC4913F),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // bottomNavigationBar: SafeArea(
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        //     decoration: const BoxDecoration(
        //       color: Color(0xFF1D1813),
        //       border: Border(top: BorderSide(color: Color(0xFF332A1F), width: 1)),
        //     ),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Expanded(
        //           child: Text(
        //             'Secure Odoo Payment Portal',
        //             style: GoogleFonts.montserrat(
        //               fontSize: 12,
        //               color: const Color(0xFFC5B7A1),
        //             ),
        //           ),
        //         ),
        //         InkWell(
        //           onTap: _completePaymentAndReturn,
        //           borderRadius: BorderRadius.circular(8),
        //           child: Container(
        //             padding: const EdgeInsets.symmetric(
        //               horizontal: 14,
        //               vertical: 8,
        //             ),
        //             decoration: BoxDecoration(
        //               color: const Color(0xFFC4913F),
        //               borderRadius: BorderRadius.circular(8),
        //             ),
        //             child: Text(
        //               'Done with Payment',
        //               style: GoogleFonts.outfit(
        //                 fontSize: 12,
        //                 fontWeight: FontWeight.bold,
        //                 color: Colors.white,
        //               ),
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ),
    );
  }
}
