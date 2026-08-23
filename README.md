Parkinson Care 🧠

A Flutter-based healthcare application designed to support people living with Parkinson's disease through symptom assessment, monitoring, medication support, and caregiver assistance.

📌 About the Project

Parkinson Care is a mobile application being developed to provide a convenient and accessible platform for Parkinson's disease management.

The application focuses on software-based assessments that can be performed without requiring specialized hardware. It also has the potential to integrate with wearable devices in the future for collecting movement-related data.

The goal is to bring multiple aspects of Parkinson's care into one easy-to-use application.

🎯 Objectives

- Provide software-based motor and speech assessments.
- Allow users to monitor Parkinson's-related symptoms.
- Support regular assessment and progress tracking.
- Provide medication reminder functionality.
- Support caregiver involvement.
- Provide a foundation for future wearable-device integration.
- Create an accessible and user-friendly healthcare experience.

✨ Current Features

Motor Assessment

The application includes software-based motor assessment activities such as:

- Spiral Trace
- Writing Test
- Line Tracing
- Finger Tapping

These assessments are intended to provide measurable information that can be used for monitoring motor-related symptoms.

Speech Assessment

A dedicated speech assessment module is included to provide a foundation for evaluating speech-related characteristics associated with Parkinson's disease.

User Interface

The application is being developed with Flutter using a structured and scalable architecture.

🏗️ Project Architecture

lib/
│
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
│
├── screens/
│   ├── motor_assessment_home_screen.dart
│   ├── motor_assessment_screen.dart
│   └── speech_assessment_screen.dart
│
└── main.dart

The project follows a modular structure so that additional features can be added without making the application difficult to maintain.

🛠️ Technology Stack

- Flutter — Mobile application development
- Dart — Programming language
- Firebase — Backend and authentication integration
- Git & GitHub — Version control and project management
- Android Studio / VS Code — Development environment

🔮 Planned Features

The project is under active development. Planned functionality includes:

- User authentication
- Symptom tracking
- Medication reminders
- Progress reports
- Caregiver assistance
- Physiotherapy support
- Additional speech analysis
- Wearable-device integration
- Accelerometer and gyroscope data collection
- Bluetooth Low Energy (BLE) communication
- Machine-learning-based analysis

📱 Hardware Integration

The software is being designed so that core assessment functionality can work without external hardware.

Future versions may integrate a wearable device using components such as:

- ESP32
- MPU6050 accelerometer and gyroscope
- MAX30102 heart-rate and SpO₂ sensor
- Bluetooth Low Energy

The wearable integration is intended to provide additional movement and physiological data to the application.

🚀 Getting Started

Prerequisites

Make sure the following are installed:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android device or emulator

Installation

Clone the repository:

git clone https://github.com/jeevithasaravanan0509-jpg/parkinsons_project.git

Navigate to the project:

cd parkinsons_project

Install dependencies:

flutter pub get

Run the application:

flutter run

🧪 Development Status

The project is currently under development.

Completed

- Flutter project setup
- Core project architecture
- Application theme and constants
- Motor assessment module
- Motor assessment screens
- Speech assessment screen
- GitHub version control

In Progress

- Firebase integration
- Authentication
- Symptom tracking
- Assessment data storage
- Additional assessment functionality

Future

- Wearable integration
- BLE communication
- Advanced data analysis
- Machine learning integration
- Caregiver features

⚠️ Disclaimer

Parkinson Care is a student/development project and is not intended to replace professional medical diagnosis, treatment, or medical advice.

Assessment results should not be interpreted as a clinical diagnosis.

👩‍💻 Developer

Jeevitha S

Computer Science and Engineering

GitHub: "Jeevitha Saravanan" (https://github.com/jeevithasaravanan0509-jpg)

📄 License

This project is currently intended for educational and development purposes.