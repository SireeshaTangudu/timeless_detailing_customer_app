import 'package:timeless_detailing_customer_app/core/config/app_config.dart';
import 'package:timeless_detailing_customer_app/main.dart';

void main() async {
  AppConfig.init(
    environment: Environment.prod,
    appName: 'Timeless Detail',
    baseUrl: 'https://timelessdetail.odoo.com',
    db: 'timelessdetail_prod',
  );
  await bootstrap();
}
