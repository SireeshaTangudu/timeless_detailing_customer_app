import 'package:timeless_detailing_customer_app/core/config/app_config.dart';
import 'package:timeless_detailing_customer_app/main.dart';

void main() async {
  AppConfig.init(
    environment: Environment.prod,
    appName: 'Timeless Detail',
    baseUrl: 'https://micahharipersad-timeless-detailing.odoo.com',
    db: 'micahharipersad-timeless-detailing-main-38183883',
  );
  await bootstrap();
}
