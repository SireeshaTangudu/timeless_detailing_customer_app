import 'package:url_launcher/url_launcher.dart';
import '../../features/bookings/models/garage_location_model.dart';

class MapLauncherUtil {
  /// Launches Google Maps to show directions and Start navigation to garage location
  static Future<void> openGoogleMapsDirections(GarageLocation garage) async {
    // Determine target location label (e.g. "Timeless Detailing, 7 Crystal Crescent, Boksburg")
    final String locationLabel = garage.address.isNotEmpty
        ? '${garage.name}, ${garage.address}'
        : garage.name;

    // 1. Google Maps Directions API URL (opens directions mode from current location with Start button)
    final String directionsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(locationLabel)}';

    // 2. Android Navigation Intent (opens Turn-by-Turn Navigation mode directly)
    final Uri navIntentUri = Uri.parse(
      'google.navigation:q=${Uri.encodeComponent(locationLabel)}',
    );

    // 3. Fallback Search URL with location name label & coordinates
    final String searchUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationLabel)}';

    final Uri directionsUri = Uri.parse(directionsUrl);
    final Uri searchUri = Uri.parse(searchUrl);

    try {
      if (await canLaunchUrl(navIntentUri)) {
        // Launches native Android Google Maps navigation directly with Start button
        await launchUrl(navIntentUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(directionsUri)) {
        // Launches Google Maps directions web/app mode
        await launchUrl(directionsUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(searchUri)) {
        await launchUrl(searchUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(directionsUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      await launchUrl(directionsUri, mode: LaunchMode.externalApplication);
    }
  }
}
