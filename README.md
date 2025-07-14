Taskly - To-Do List Application
Overview
Taskly is a Flutter-based mobile application designed to help users manage their tasks efficiently. It provides a user-friendly interface for signing up, signing in, and managing tasks. Users can create, view, mark as complete, and delete tasks, with a feature to highlight the most urgent task based on due date and time. The app is built with a consistent purple-themed design and supports responsive layouts for various devices.
Features

User Authentication:
Sign-up with full name, email, and password, including form validation.
Sign-in with email and password, with validation for correct input.
Password visibility toggle for enhanced user experience.


Task Management:
Add tasks with a title, due date, and time via a bottom sheet form.
View tasks in three tabs: All, Pending, and Completed.
Mark tasks as complete or incomplete, with visual feedback (e.g., strikethrough for completed tasks).
Delete tasks with snackbar confirmation.
Highlight the most urgent task (earliest due date and time) in a dedicated section.


Responsive Design:
Utilizes DevicePreview to ensure compatibility across different screen sizes.
Implements SafeArea and SingleChildScrollView to handle varying screen dimensions.


Modern UI:
Consistent purple theme (#673AB7) across buttons, icons, and borders.
Rounded corners for buttons and input fields for a polished look.
Custom image assets for welcome, sign-in, and sign-up screens.



Technologies Used

Flutter & Dart: Cross-platform framework and programming language for building the app.
Packages:
flutter/material.dart: For Material Design components.
flutter/cupertino.dart: For iOS-style navigation elements.
device_preview: For testing UI on various device sizes.
intl: For formatting dates and times in task management.


Assets: Custom images (signin.png, signup.png, wc.png) for visual enhancement.

Installation

Clone the Repository:git clone https://github.com/yourusername/taskly.git


Navigate to the Project Directory:cd taskly


Install Dependencies:flutter pub get


Run the App:flutter run



Usage

Launch the app to view the welcome screen with options to sign up or sign in.
Sign up by providing a full name, valid email, and password (minimum 6 characters).
Sign in using your email and password.
On the home screen, use the floating action button to add a new task with a title, due date, and time.
View tasks in the "All," "Pending," or "Completed" tabs using the tab bar.
Mark tasks as complete/incomplete or delete them as needed.
The most urgent task (earliest due date and time) is highlighted at the top of the "All" tab.

Project Structure

main.dart: Entry point, sets up the app with DevicePreview and MaterialApp.
Welcome.dart: Displays the welcome screen with navigation to sign-up/sign-in.
signin_page.dart: Handles user sign-in with form validation and navigation.
signup_page.dart: Manages user registration with form validation.
home_pge.dart: Core task management screen with tabbed views and task operations.

Future Improvements

Persistent Storage: Implement shared_preferences or sqflite to save tasks across app restarts.
Backend Integration: Use Firebase for real-time user authentication and task synchronization.
Push Notifications: Add reminders for upcoming tasks.
Dark Mode: Support a dark theme for better accessibility.
Task Categories: Allow users to categorize tasks (e.g., work, personal).

Contributing
Contributions are welcome! To contribute:

Fork the repository.
Create a new branch (git checkout -b feature/your-feature).
Make your changes and commit (git commit -m 'Add your feature').
Push to the branch (git push origin feature/your-feature).
Submit a pull request.

License
This project is licensed under the MIT License.

