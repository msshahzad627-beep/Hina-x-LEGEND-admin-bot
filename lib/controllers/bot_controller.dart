import 'package:get/get.dart';
import '../api/api_service.dart';
import 'auth_controller.dart';

class BotController extends GetxController {
  var bots = <String>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBots();
  }

  void fetchBots() async {
    isLoading.value = true;
    final auth = Get.find<AuthController>();

    // اگر ایڈمن ہے تو سارے ایکٹو بوٹس لے آؤ
    if (auth.isAdmin.value) {
      bots.value = await ApiService.getActiveBots();
    } else {
      // اگر یوزر ہے تو صرف اس کے الاؤڈ بوٹس دکھاؤ
      bots.value = auth.allowedBots;
    }

    isLoading.value = false;
  }
}
