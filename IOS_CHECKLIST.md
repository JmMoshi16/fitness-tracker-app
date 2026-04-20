# ✅ Pre-Build Checklist - iOS

## Before Pushing to GitHub:

### 1. Firebase iOS Configuration (REQUIRED)
- [ ] Go to [Firebase Console](https://console.firebase.google.com)
- [ ] Select your project
- [ ] Click "Add app" → iOS
- [ ] Bundle ID: `com.yourname.fitnesstracker` (or your custom ID)
- [ ] Download `GoogleService-Info.plist`
- [ ] Place file in: `ios/Runner/GoogleService-Info.plist`
- [ ] Verify file exists: `ls ios/Runner/GoogleService-Info.plist`

### 2. Update Codemagic Email
- [ ] Open `codemagic.yaml`
- [ ] Find line: `NOTIFICATION_EMAIL: "your@email.com"`
- [ ] Replace with your actual email
- [ ] Save file

### 3. Update Bundle Identifier (Optional)
- [ ] Open `ios/Runner.xcodeproj/project.pbxproj`
- [ ] Search for: `PRODUCT_BUNDLE_IDENTIFIER`
- [ ] Change to your custom ID (e.g., `com.yourname.fitnesstracker`)
- [ ] Or keep default: `com.example.fitnessTracker`

### 4. Verify iOS Files
- [ ] Check `ios/Runner/Info.plist` exists
- [ ] Check permissions are added (camera, location, motion)
- [ ] Check `ios/Podfile` exists

### 5. Test Build Locally (Optional)
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --debug --no-codesign
```

### 6. Commit and Push
```bash
git add .
git commit -m "iOS build configuration complete"
git push origin main
```

---

## On Codemagic:

### 1. Sign Up
- [ ] Go to [codemagic.io](https://codemagic.io)
- [ ] Click "Sign in with GitHub"
- [ ] Authorize Codemagic

### 2. Add Application
- [ ] Click "Add application"
- [ ] Select `fitness_tracker` repo
- [ ] Choose "Flutter App"

### 3. Configure Workflow
- [ ] Codemagic detects `codemagic.yaml`
- [ ] Select workflow: "iOS Debug (FREE - No Signing)"
- [ ] Click "Start new build"

### 4. Wait for Build
- [ ] First build: ~15-20 minutes
- [ ] Check build logs for errors
- [ ] Download IPA when complete

---

## On Your iPhone:

### 1. Install AltStore
- [ ] Download [AltServer](https://altstore.io) on Windows PC
- [ ] Install iTunes (required)
- [ ] Run AltServer (check system tray)
- [ ] Connect iPhone via USB
- [ ] Trust computer on iPhone
- [ ] Install AltStore via AltServer

### 2. Install Your App
- [ ] Open AltStore on iPhone
- [ ] Go to "My Apps"
- [ ] Tap "+" button
- [ ] Select `fitness_tracker_debug.ipa`
- [ ] Wait for installation
- [ ] App appears on home screen

### 3. Trust Developer
- [ ] Settings → General → VPN & Device Management
- [ ] Tap your Apple ID
- [ ] Tap "Trust"

### 4. Launch App
- [ ] Open FitTracker from home screen
- [ ] Grant permissions when prompted
- [ ] Test all features

---

## Weekly Maintenance:

### Every 7 Days:
- [ ] Connect iPhone to PC (same WiFi)
- [ ] Open AltStore on iPhone
- [ ] Tap "Refresh All"
- [ ] Keep AltServer running on PC

---

## Troubleshooting Quick Fixes:

**Build fails on Codemagic**:
```bash
# Check build logs for specific error
# Common fix: Update Podfile platform version
```

**AltStore can't find AltServer**:
- Restart AltServer
- Check same WiFi network
- Disable VPN

**App crashes on launch**:
- Check iOS version (need 12.0+)
- Verify Firebase config
- Check permissions in Info.plist

---

## 🎯 Ready to Build?

If all checkboxes above are ✅, you're ready!

**Estimated Time**:
- Setup: 10 minutes
- First build: 15 minutes
- Installation: 5 minutes
- **Total: 30 minutes**

**Cost**: $0.00 ✅

---

## 📚 Full Documentation:

- Detailed guide: `IOS_BUILD_GUIDE.md`
- Quick answer: `IOS_QUICK_ANSWER.md`
- Build config: `codemagic.yaml`

**Good luck! 🚀**
