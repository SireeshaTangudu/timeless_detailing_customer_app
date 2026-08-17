import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/bookings/models/garage_location_model.dart';

class MapLauncherUtil {
  /// Launches Google Maps to show directions and Start navigation to garage location
  static Future<void> openGoogleMapsDirections(GarageLocation garage) async {
    final bool hasCoords = garage.latitude != 0.0 && garage.longitude != 0.0;

    final String destinationParam = hasCoords
        ? '${garage.latitude},${garage.longitude}'
        : Uri.encodeComponent(
            garage.address.isNotEmpty
                ? '${garage.name}, ${garage.address}'
                : garage.name,
          );

    final String directionsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationParam';

    final Uri directionsUri = Uri.parse(directionsUrl);

    final String geoString = hasCoords
        ? 'geo:${garage.latitude},${garage.longitude}?q=${garage.latitude},${garage.longitude}(${Uri.encodeComponent(garage.name)})'
        : 'geo:0,0?q=${Uri.encodeComponent(garage.address.isNotEmpty ? garage.address : garage.name)}';

    final Uri geoUri = Uri.parse(geoString);

    debugPrint(
      '🔵 [MapLauncherUtil] Launching Google Maps for garage: ${garage.name} (lat=${garage.latitude}, lng=${garage.longitude})',
    );

    try {
      // 1. Try launching Google Maps HTTPS URL directly in external application mode
      bool launched = await launchUrl(
        directionsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // 2. Try geo URI scheme for Android native maps app
        launched = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        // 3. Fallback to platform default browser/app
        await launchUrl(
          directionsUri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint('🔴 [MapLauncherUtil] Primary map launch error ($e). Attempting direct launch...');
      try {
        await launchUrl(directionsUri, mode: LaunchMode.externalApplication);
      } catch (err) {
        debugPrint('🔴 [MapLauncherUtil] Map launch failed: $err');
      }
    }
  }
}
