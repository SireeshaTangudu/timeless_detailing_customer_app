import 'package:timeless_detailing_customer_app/core/config/app_config.dart';
import 'package:timeless_detailing_customer_app/main.dart';

void main() async {
  AppConfig.init(
    environment: Environment.prod,
    appName: 'Timeless Detail',
    baseUrl:
        'https://keerthan-lfi-lfi-timeless-detailing1-uat-38115700.dev.odoo.com',
    db: 'keerthan-lfi-lfi-timeless-detailing1-uat-38115700',
  );
  await bootstrap();
}
