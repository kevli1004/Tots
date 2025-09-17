# Tots Widget Setup Instructions

## Overview
The Tots app now includes countdown timers and widget support similar to Cal AI. The app tracks feeding, diaper changes, and sleep patterns, predicting when the next activity is due.

## Features Added

### 1. Countdown Timers ⏰
- **Next Feeding**: Predicts next feeding time based on 3-hour intervals
- **Next Diaper**: Predicts next diaper change based on 2.5-hour intervals  
- **Next Sleep**: Predicts next sleep time based on 2-hour intervals
- **Live Updates**: Timers update every minute automatically
- **Visual Display**: Clean countdown cards in the main app

### 2. Widget Files Created 📱
The following widget files have been created and are ready to be added to Xcode:

- `TotsWidget/TotsWidget.swift` - Main widget implementation
- `TotsWidget/TotsWidgetBundle.swift` - Widget bundle configuration
- `TotsWidget/Info.plist` - Widget Info.plist
- `Tots/Models/AppIntents.swift` - App Intents for Siri shortcuts

### 3. Widget Types Supported
- **Small Widget**: Shows all three countdown timers in a compact format
- **Medium Widget**: Shows countdowns with predicted times
- **Lock Screen Widget**: Minimal countdown display for lock screen

## Setup Instructions

### Adding Widget Extension to Xcode:

1. **Open Tots.xcodeproj in Xcode**

2. **Add Widget Extension:**
   - File → New → Target
   - Choose "Widget Extension"
   - Product Name: "TotsWidget"
   - Include Configuration Intent: No
   - Click Finish

3. **Replace Generated Files:**
   - Replace the generated `TotsWidget.swift` with our version
   - Replace the generated `TotsWidgetBundle.swift` with our version
   - Update Info.plist if needed

4. **Add App Intents:**
   - Add `AppIntents.swift` to the main Tots target
   - This enables Siri shortcuts for quick activity logging

5. **Configure App Groups (Optional):**
   - For real data sharing between app and widget
   - Add App Group capability to both targets
   - Use UserDefaults with app group container

## Current Implementation

### In-App Countdown Display
The main app now shows countdown timers at the top of the home screen:
- 🍼 **Feed**: Shows time until next predicted feeding
- 🩲 **Diaper**: Shows time until next predicted diaper change  
- 😴 **Sleep**: Shows time until next predicted sleep time

### Prediction Logic
- **Feeding**: 3 hours after last feeding
- **Diaper**: 2.5 hours after last diaper change
- **Sleep**: 2 hours after last sleep period
- **Updates**: Every minute via Timer

### Widget Features (When Added)
- **Real-time countdowns** on home screen and lock screen
- **Cal AI-inspired design** with clean, minimal interface
- **Multiple sizes** for different use cases
- **Tap to open app** functionality

## Next Steps

1. **Add widget extension** through Xcode (manual step required)
2. **Test widgets** on device or simulator
3. **Configure app groups** for data sharing
4. **Customize prediction intervals** based on baby's patterns
5. **Add notification support** when activities are due

## Notes

- Widget files are created but need to be added to Xcode project manually
- Current implementation uses sample data - real data sharing requires App Groups
- Countdown timers work immediately in the main app
- Widget extension requires iOS 17+ for lock screen widgets
