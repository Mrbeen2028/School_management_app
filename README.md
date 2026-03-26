# 🎓 EduEmpire Pro - School Management System

A modern, enterprise-grade School Management System built with a robust Flutter frontend and a scalable Node.js/MongoDB backend. This platform provides a centralized hub for managing students, teachers, attendance, fees, exams, and announcements with a highly professional and responsive user interface.

## ✨ Key Features

- **Pofessional Split-Screen Authentication**: A beautiful, desktop-optimized login and forgot password experience.
- **Role-Based Access Control**: Tailored dashboards and features for Super Admins, Admins, Principals, Teachers, Students, and Parents.
- **Responsive Admin Panel**: Features a persistent navigation sidebar for desktops/tablets and a unified, clean drawer layout for mobile devices.
- **Student & Teacher Management**: Comprehensive lists, detailed profiles, and easy-to-use forms for managing users.
- **Daily Attendance Tracking**: Efficient attendance marking and statistical overviews.
- **Fee Management**: Track payments, view outstanding dues, and monitor revenue with dashboard statistics.
- **Examination System**: Schedule exams and manage results seamlessly.
- **Announcements System**: Broadcast school-wide notices and updates.

## 🛠️ Technology Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform: Web, Mobile, Desktop)
- **State Management**: BLoC Pattern (`flutter_bloc`)
- **UI Architecture**: Deeply customized professional aesthetic (`AppTheme.dart` with Indigo & Slate color palettes)
- **Typography & Icons**: Google Fonts (Inter) & Material Icons

### Backend
- **Framework**: [Node.js](https://nodejs.org/) & [Express.js](https://expressjs.com/)
- **Database**: [MongoDB](https://www.mongodb.com/) (Mongoose ODM)
- **Authentication**: JWT (JSON Web Tokens)
- **Environment**: `.env` configurations

## 🚀 Getting Started

Follow these steps to get your development environment set up:

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- [Node.js](https://nodejs.org/en/download/) (v16.x or newer)
- [MongoDB](https://www.mongodb.com/try/download/community) (running locally or a MongoDB Atlas URI)

### 1. Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
