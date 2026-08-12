import 'package:url_launcher/url_launcher.dart';
import '../../features/bookings/models/garage_location_model.dart';

class MapLauncherUtil {
  /// Launches Google Maps to show directions and place pin for a given garage branch
  static Future<void> openGoogleMapsDirections(GarageLocation garage) async {
    // Construct Google Maps Place Search URL
    // If googlePlaceId exists, include query_place_id for exact profile page
    String webUrl;
    if (garage.googlePlaceId != null && garage.googlePlaceId!.isNotEmpty) {
      webUrl =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(garage.name)}&query_place_id=${garage.googlePlaceId}';
    } else {
      webUrl =
          'https://www.google.com/maps/search/?api=1&query=${garage.latitude},${garage.longitude}';
    }

    final Uri googleMapsUri = Uri.parse(webUrl);

    // Native intent URI for Android & iOS maps app fallback
    final Uri nativeGeoUri = Uri.parse(
      'geo:${garage.latitude},${garage.longitude}?q=${garage.latitude},${garage.longitude}(${Uri.encodeComponent(garage.name)})',
    );

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(nativeGeoUri)) {
        await launchUrl(nativeGeoUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web browser URL
        await launchUrl(googleMapsUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Fallback
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    }
  }
}
