import 'package:timeless_detailing_customer_app/core/config/app_config.dart';
import 'package:timeless_detailing_customer_app/main.dart';

void main() async {
  AppConfig.init(
    environment: Environment.uat,
    appName: 'Timeless Detailing UAT',
    baseUrl:
        'https://micahharipersad-timeless-detailing-staging-38183938.dev.odoo.com',
    db: 'micahharipersad-timeless-detailing-staging-38183938',
  );
  await bootstrap();
}
