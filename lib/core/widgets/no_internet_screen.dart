import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/services/network_connectivity_service.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetScreen({super.key, this.onRetry});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    final netService = Provider.of<NetworkConnectivityService>(context, listen: false);
    final isOnline = await netService.checkConnectionNow();

    if (isOnline) {
      if (widget.onRetry != null) {
        widget.onRetry!();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Still offline. Please check your Wi-Fi or cellular network.',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFB71C1C),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Signal Off Icon with Ring Decoration
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFC4913F).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC4913F).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 52,
                    color: Color(0xFFC4913F),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A2F1E),
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle Description
              Text(
                'Please check your network settings. We will automatically reconnect and fetch your live data as soon as you are back online.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  color: const Color(0xFF7A7063),
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Retry Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4913F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    _isRetrying ? 'Checking Network...' : 'Try Again',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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
