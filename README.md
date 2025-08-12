# NepHeal - Doctor Appointment Booking System

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" alt="Laravel" />
  <img src="https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL" />
  <img src="https://img.shields.io/badge/Filament-FFAA00?style=for-the-badge&logo=laravel&logoColor=white" alt="Filament" />
</div>

## 📱 About NepHeal

NepHeal is a comprehensive digital healthcare platform designed to revolutionize doctor appointment booking in Nepal. The system connects patients with licensed healthcare professionals, making healthcare more accessible and organized through a modern, user-friendly interface.

### 🎯 Key Features

- **🔍 Smart Doctor Search** - Find doctors by specialty, location, and availability
- **📅 Validated Appointment Booking** - Book appointments with calendar integration and validation  
- **👤 User Profile Management** - Comprehensive profiles for patients and doctors
- **⭐ Review System** - Patient feedback and doctor ratings
- **📊 Admin Dashboard** - Complete system management with Filament admin panel
- **🔒 Secure Authentication** - Multi-role authentication system
- **📱 Mobile-First Design** - Responsive Flutter application

## 🏗️ Project Structure

```
nepheal/
├── web/                         # Laravel Backend & Admin Panel
└── docapp/                      # Flutter Mobile Application  
```

## 🚀 Technology Stack

### Backend
- **Framework:** Laravel (PHP)
- **Admin Panel:** Filament
- **Database:** MySQL
- **Authentication:** Laravel Sanctum

### Mobile App
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider

### Features Integration
- **Dynamic Notifications**
- **Secure API Communication**
- **Image Upload & Management**
- **Payment Gateway**

## 🛠️ Installation & Setup

### Prerequisites
- PHP >= 8.0
- Composer
- MySQL
- Flutter SDK
- Android Studio/VS Code

### Backend Setup (Laravel + Filament)

1. **Clone the repository**
   ```bash
   git clone https://github.com/hexa01/nepheal.git
   cd nepheal
   ```

2. **Setup Laravel Backend**
   ```bash
   cd web
   composer install
   cp .env.example .env
   php artisan key:generate
   ```

3. **Configure Database**
   ```bash
   # Edit .env file with your database credentials
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=nepheal
   DB_USERNAME=your_username
   DB_PASSWORD=your_password
   ```

4. **Run Migrations & Seeders**
   ```bash
   php artisan migrate:fresh --seed  #migrate individually following relationships to avoid errors
   php artisan storage:link
   ```

5. **Start Laravel Server**
   ```bash
   php artisan serve
   ```

6. **Access Admin Panel**
   - URL: `http://localhost:8000/admin`
   - Create admin user: `php artisan make:filament-user`

### Mobile App Setup (Flutter)

1. **Navigate to Flutter directory**
   ```bash
   cd ../docapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   ```dart
   // lib/config/app_config.dart
   static const String baseUrl = 'http://localhost:8000/api/v1/';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📊 Database Schema

### Key Entities
- **Users** - Patients, Doctors, Admins
- **Appointments** - Booking management
- **Specializations** - Medical departments/specialties
- **Schedules** - Doctor availability
- **Reviews** - Patient feedback

## 🔌 API Endpoints

### Authentication
- `POST /api/v1/register` - User registration
- `POST /api/v1/login` - User login
- `POST /api/v1/logout` - User logout

### Appointments
- `GET /api/v1/appointments` - List appointments
- `POST /api/v1/appointments` - Book appointment
- `PUT /api/v1/appointments/{id}` - Update appointment
- `DELETE /api/v1/appointments/{id}` - Cancel appointment

### Doctors
- `GET /api/v1/doctors` - List doctors
- `GET /api/v1/doctors/{id}` - Doctor details
- `GET /api/v1/specializations` - Medical specialties

## 👥 User Roles

### 🩺 Doctors
- Manage profile and specializations
- Set availability schedules
- View and manage appointments
- Message patients with prescriptions and consults
- Track appointment history

### 🙋‍♀️ Patients
- Search and filter doctors
- Book appointments
- Manage personal profile
- Leave reviews and feedback

### 👨‍💼 Administrators
- Complete system oversight
- User management
- Appointment monitoring
- System analytics
- Content management

## 🎨 Key Features Implemented

### ✅ Core Functionality
- [x] User registration and authentication
- [x] Doctor search and filtering
- [x] Real-time appointment booking
- [x] Profile management
- [x] Review and rating system
- [x] Admin dashboard with Filament
- [x] Mobile-responsive design

### 🔄 Future Enhancements
- [ ] Video consultation integration
- [ ] E-prescription system
- [ ] Multiple payment gateways
- [ ] Multi-language support
- [ ] Advanced analytics dashboard

## 🤝 Contributing

We welcome contributions to NepHeal! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter and Laravel best practices
- Write clear commit messages
- Add tests for new features
- Update documentation as needed

## 👨‍💻 Development Team

- **Sushan Poudel**
- **Prashant Adhikari**
- **Akriti Dhakal**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

*Project developed as part of BCA 8th Semester at LA Grandee International College, Pokhara University*

---

<div align="center">
  <p>Made with ❤️ for better healthcare access in Nepal</p>
  <p>⭐ Star this repository if you found it helpful!</p>
</div>
