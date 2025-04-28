/* -- App Text Strings -- */

// test_services_constants.dart
const List<String> testServices = [
  'Blood Test',
  'Urine Test',
  'Liver Function Test',
  'Thyroid Test',
  'Lipid Profile',
  'Cholesterol Test',
  'Uric Acid Test',
  'Hepatitis B Test',
  'Hepatitis C Test',
  'Beta hCG Test',
  'Complete Blood Count (CBC)',
  'Semen Analysis',
  '24 Hours Urine Test',
  'Body Fluids Analysis',
  'Pleural Fluid Routine Exam',
  'Synovial Fluid for RE',
  '24 Hours Urine Magnesium',
  '24 Hours Urine Micro Albumin',
  '24 Hours Urine Protein',
  '24 Hours Urine Uric Acid',
  '24 Hours Urine for Urea',
  '24 Hours Urine Creatinine',
  '24 Hours Urine Calcium',
  '24 Hours Urine Electrolyte',
  'Blood Culture Bottle Charges',
  'Gabapentin',
  'Ascitic Fluid R/E',
  'C.S.F Routine Examination',
  'Fluid RE',
  'Pleural Fluid Routine Exam',
  'Synovial Fluid for RE',
];

//MongoDB Texts
// ignore: constant_identifier_names
const MONGO_URL =
    "mongodb+srv://25362:talha8k83t@curalinkcluster.0xafs.mongodb.net/dbCuraLink?retryWrites=true&w=majority&appName=CuraLinkCluster";
// ignore: constant_identifier_names
const String USERS = "users";
const String USER_PATIENT_COLLECTION_NAME = "userPatient";
const String USER_NURSE_COLLECTION_NAME = "userNurse";
const String USER_LAB_COLLECTION_NAME = "userLab";
const String USER_MEDICAL_STORE_COLLECTION_NAME = "userMedicalStore";
const String LAB_SERVICES = "labServices";
const String USER_VERIFICATION = "userVerification";
const String LAB_BOOKINGS = "labBookings";
const String PATIENT_LAB_BOOKINGS = "patientLabBookings";
const String MESSAGES_COLLECTION_NAME = "messages";
const String LAB_RATING_COLLECTION = "labRating";

const String ipAddress = "http://192.168.1.45:4000";
// -- GLOBAL Texts
const String tNo = "No";
const String tYes = "Yes";
const String tNext = "Next";
const String tLogin = "Login";
const String tEmail = "E-Mail";
const String tSignup = "Signup";
const String tLogout = "Logout";
const String tSuccess = "Success";
const String tPhoneNo = "Phone No";
const String tContinue = "Continue";
const String tPassword = "Password";
const String tFullName = "Full Name";
const String tGetStarted = "Get Started";
const String tForgetPassword = "Forget Password?";
const String tSignInWithGoogle = "Sign-In with Google";

// -- Validation --
const String tEmailCannotEmpty = "Email cannot be empty";
const String tInvalidEmailFormat = "Invalid email format";
const String tNoRecordFound = "No record found";

// -- SnackBar --
const String tAlert = "Alert";
const String tOhSnap = "Oh Snap";
const String tEmailSent = "Hurray!!! Email is on its way.";
const String tCongratulations = "Congratulations";
const String tEmailLinkToResetPassword = "Email Link To Reset Password";
const String tAccountCreateVerifyEmail = "Account Create Verify Email";

// -- Splash Screen Text
const String tAppName = "Cura-Link";
const String tAppTagLine =
    "Make your health better. \n Take services in your home";

// -- On Boarding Text
const String tOnBoardingTitle1 = "Quick delivery Service";
const String tOnBoardingTitle2 = "Lab booking ";
const String tOnBoardingTitle3 = "Get services from Nurses nearby";
const String tOnBoardingSubTitle1 =
    "'Order medicines with the option to choose\n   between normal and priority delivery.";
const String tOnBoardingSubTitle2 =
    "Book lab tests and receive your results\n   via email or WhatsApp quickly.";
const String tOnBoardingSubTitle3 =
    "Book professional nurses for home visits\n   and receive quality medical care at home.";
const String tOnBoardingCounter1 = "1/3";
const String tOnBoardingCounter2 = "2/3";
const String tOnBoardingCounter3 = "3/3";

// -- Welcome Screen Text
const String tWelcomeTitle = "Welcome!";
const String tWelcomeSubTitle =
    "Who are you? \n Please select and and get stared with Cura-Link";

// -- Login Screen Text
const String tLoginTitle = "Welcome Back,";
const String tLoginSubTitle = "Make it work, make it right, make it fast.";
const String tRememberMe = "Remember Me?";
const String tDontHaveAnAccount = "Don't have an Account";
const String tEnterYour = "Enter your";
const String tResetPassword = "Reset Password";
const String tOR = "OR";
const String tConnectWith = "Connect With";
const String tFacebook = "Facebook";
const String tGoogle = "Google";
const String tPhone = "Phone";

// -- Sign Up Screen Text
const String tSignUpTitle = "Create Account";
const String tSignUpSubTitle =
    "Create your profile to get started with Cura-Link.";
const String tAlreadyHaveAnAccount = "Already have an Account";

// -- Forget Password Text
const String tForgetPasswordTitle = "Make Selection!";
const String tForgetPasswordSubTitle =
    "Select one of the options given below to reset your password.";
const String tResetViaEMail = "Reset via Mail Verification";
const String tResetViaPhone = "Reset via Phone Verification";

// -- Forget Password Via Phone - Text
const String tForgetPhoneSubTitle =
    "Enter your registered Phone No to receive OTP";

// -- Forget Password Via E-Mail - Text
const String tForgetMailSubTitle =
    "Enter your registered E-Mail to receive OTP";

// -- OTP Screen - Text
const String tOtpTitle = "CO\nDE";
const String tOtpSubTitle = "Verification";
const String tOtpMessage = "Enter the verification code sent at ";

// -- Email Verification
const String tEmailVerificationTitle = "Verify your email address";
const String tEmailVerificationSubTitle =
    "We have just send email verification link on your email. Please check email and click on that link to verify your Email address. \n\n If not auto redirected after verification, click on the Continue button.";
const String tResendEmailLink = "Resend E-Mail Link";
const String tBackToLogin = "Back to login";

// -- Dashboard Screen - Text
const String tDashboardTitle = "Hey, Coding with T";
const String tDashboardHeading = "Explore Courses";
const String tDashboardSearch = "Search...";
const String tDashboardBannerTitle2 = "JAVA";
const String tDashboardButton = "View All";
const String tDashboardTopCourses = "Top Courses";
const String tDashboardBannerSubTitle = "10 Lessons";
const String tDashboardBannerTitle1 = "Android for Beginners";

// -- Profile Screen - Text
const String tProfile = "Profile";
const String tEditProfile = "Edit Profile";
const String tLogoutDialogHeading = "Logout";

// -- Menu
const String tMenu5 = tLogout;
const String tMenu1 = "Settings";
const String tMenu4 = "Information";
const String tMenu2 = "Billing Details";
const String tMenu3 = "User Management";

// -- Update Profile Screen - Text
const String tDelete = "Delete";
const String tJoined = "Joined";
const String tJoinedAt = " 31 October 2024";
