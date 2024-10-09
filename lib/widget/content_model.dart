class MedicinesContent {
  String image;
  String title;
  String description;

  MedicinesContent({
    required this.description,
    required this.image,
    required this.title,
  });
}

class NursesContent {
  String image;
  String title;
  String description;

  NursesContent({
    required this.description,
    required this.image,
    required this.title,
  });
}

class LabTestsContent {
  String image;
  String title;
  String description;

  LabTestsContent({
    required this.description,
    required this.image,
    required this.title,
  });
}
class PatientContent {
  String image;
  String title;
  String description;

  PatientContent({
    required this.description,
    required this.image,
    required this.title,
  });
}

// Patient entries
List<PatientContent> patientContents = [
  PatientContent(
    description: 'Order medicines with the option to choose\n   between normal and priority delivery.',
    image: "images/patientOnboardImage1.jpg", // Update to your actual image path
    title: 'Normal and Priority\n   Medicine Orders',
  ),
  PatientContent(
    description: 'Book lab tests and receive your results\n   via email or WhatsApp quickly.',
    image: "images/patientOnboardImage2.jpg", // Update to your actual image path
    title: 'Lab Test Booking\n   and Reports',
  ),
  PatientContent(
    description: 'Book professional nurses for home visits\n   and receive quality medical care at home.',
    image: "images/patientOnboardImage3.jpg", // Update to your actual image path
    title: 'Book Nurses for\n   Home Service',
  ),
];


// Medicines entries
List<MedicinesContent> medicinesContents = [
  MedicinesContent(
    description: 'Order medicines easily and get them delivered\n right at your doorstep.',
    image: "images/mediceOnboardImage1.jpg", // Update to your actual image path
    title: 'Order Medicines\n   with Ease',
  ),
  MedicinesContent(
    description: 'Upload prescriptions for accurate medicine orders\n   and enjoy priority delivery options.',
    image: "images/mediceOnboardImage2.jpg", // Update to your actual image path
    title: 'Easy Prescription Upload',
  ),
  MedicinesContent(
    description: 'Compare delivery bids from multiple\n   medical stores for the best price.',
    image: "images/mediceOnboardImage3.jpg", // Update to your actual image path
    title: 'Choose the Best Delivery Option',
  ),
];

// Nurses entries
List<NursesContent> nursesContents = [
  NursesContent(
    description: 'Book medical nurses\n   for home visits conveniently.',
    image: "images/nurseOnboardImage1.jpg", // Update to your actual image path
    title: 'Professional Care\n  at Home',
  ),
  NursesContent(
    description: 'View bids from qualified nurses and\n   select the best fit for your needs.',
    image: "images/nurseOnboardImage2.jpg", // Update to your actual image path
    title: 'Select Your Caregiver',
  ),
  NursesContent(
    description: 'Get timely notifications and updates\n   about your appointments.',
    image: "images/nurseOnboardImage3.jpg", // Update to your actual image path
    title: 'Stay Updated on Appointments',
  ),
];

// Lab Tests entries
List<LabTestsContent> labTestsContents = [
  LabTestsContent(
    description: 'Book lab tests online and receive your\n   reports directly via email or WhatsApp.',
    image: "images/labOnboardImage1.jpg", // Update to your actual image path
    title: 'Convenient Lab\n   Test Booking',
  ),
  LabTestsContent(
    description: 'Check availability and book slots\n   for various tests effortlessly.',
    image: "images/labOnboardImage2.jpg", // Update to your actual image path
    title: 'Easy Test Scheduling',
  ),
  LabTestsContent(
    description: 'Receive quick updates on your test results\n   right from the app.',
    image: "images/labOnboardImage3.jpg", // Update to your actual image path
    title: 'Instant Results Notifications',
  ),
];
