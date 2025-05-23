import 'package:get/get.dart';
import '../repository/authentication_repository/authentication_repository.dart';
import '../repository/user_repository/user_repository.dart';
import '../screens/features/authentication/controllers/login_controller.dart';
import '../screens/features/authentication/controllers/on_boarding_controller.dart';
import '../screens/features/authentication/controllers/signup_controller.dart';
import '../screens/features/core/screens/Nurse/NurseBookings/Nurse_Booking_Controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthenticationRepository(), fenix: true);
    Get.lazyPut(() => UserRepository(), fenix: true);
    Get.lazyPut(() => OnBoardingController(), fenix: true);
    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => SignUpController(), fenix: true);
    Get.lazyPut(() => BookingControllerNurse(), fenix: true);
  }
}
