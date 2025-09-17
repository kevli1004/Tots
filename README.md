# Tots AI - Baby Tracking App

A beautiful, modern iOS baby tracking app built with SwiftUI that helps parents monitor their little one's daily activities, milestones, and growth.

## ✨ Features

### 🏠 Home Dashboard
- **Daily Activity Overview**: Circular progress indicators showing feedings, diaper changes, sleep, and tummy time
- **Streak Counter**: Track consistent logging days with a beautiful flame badge
- **Smart Insights**: AI-powered insights about sleep patterns, mood tracking, and milestone celebrations
- **Recent Activities Timeline**: Detailed activity history with mood tracking and notes
- **Quick Actions**: Fast access to log activities, add milestones, take photos, and view stats

### 📊 Progress & Analytics
- **Weekly Charts**: Visual representation of feeding, diaper, sleep, and activity patterns
- **Growth Tracking**: Weight, height, and head circumference monitoring with percentile charts
- **Milestone Progress**: Track developmental milestones across motor, language, social, cognitive, and physical categories
- **Time Frame Selection**: View progress across different time periods

### ⚙️ Settings & Family Sharing
- **Baby Profile Management**: Customize baby information and photos
- **Family Invitations**: Share tracking with partners, grandparents, and caregivers
- **Data Sync**: Cloud synchronization across devices
- **Export & Backup**: Export data for pediatrician visits or backup

### ➕ Activity Logging
- **Comprehensive Tracking**: Log feedings (bottle, breastfeeding, solids), diaper changes, sleep sessions, play time, and milestones
- **Mood Tracking**: Record baby's mood for each activity (happy, content, sleepy, fussy, curious, neutral)
- **Smart Defaults**: Intelligent suggestions based on previous activities and patterns
- **Notes & Details**: Add custom notes and specific details for each activity

## 🎨 Design Philosophy

Tots AI follows a clean, modern design inspired by premium productivity apps:

- **Gradient Accents**: Beautiful pink-to-purple gradients throughout the interface
- **Smooth Animations**: Delightful micro-interactions and transitions
- **Circular Progress**: Intuitive circular progress indicators for daily goals
- **Card-Based Layout**: Clean, scannable information cards
- **Thoughtful Typography**: Clear hierarchy and readable fonts
- **Mood-Based Colors**: Each activity type has its own color scheme

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- macOS 14.0 or later

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/tots-ai.git
   cd tots-ai
   ```

2. Open the project in Xcode:
   ```bash
   open Tots.xcodeproj
   ```

3. Select your target device or simulator

4. Build and run the project (⌘+R)

## 🏗️ Architecture

The app follows the MVVM (Model-View-ViewModel) pattern with SwiftUI:

- **Models**: `TotsDataManager` handles all data operations and state management
- **Views**: SwiftUI views organized by feature (Home, Progress, Settings, AddActivity)
- **Components**: Reusable UI components (CircularProgressView, TrackingCard, etc.)

### Key Components
- `TotsDataManager`: Central data management with realistic sample data
- `TotsActivity`: Rich activity model with mood, duration, and notes
- `ActivityType`: Enum defining different activity types with colors and icons
- `BabyMood`: Mood tracking for each activity
- `Milestone`: Developmental milestone tracking across categories

## 📱 Screenshots

The app includes:
- Beautiful home dashboard with circular progress rings
- Comprehensive activity logging with mood selection
- Rich progress charts and milestone tracking
- Family sharing and settings management

## 🔮 Future Enhancements

- [ ] AI-powered insights and recommendations
- [ ] Photo attachment for activities and milestones
- [ ] Apple Watch companion app
- [ ] Widget extensions for home screen
- [ ] Integration with Apple Health
- [ ] Pediatrician report generation
- [ ] Multi-baby support for families with twins/multiples

## 🤝 Contributing

We welcome contributions! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👶 Made with Love

Tots AI is designed by parents, for parents. We understand the challenges of tracking your baby's activities and wanted to create something beautiful, intuitive, and genuinely helpful.

---

*Built with SwiftUI, love, and lots of coffee ☕*