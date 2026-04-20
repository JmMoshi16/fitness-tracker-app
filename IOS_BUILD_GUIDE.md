# 🍎 iOS Build Setup Guide - FitTracker

## 💰 Cost Breakdown - 100% HONEST ANSWER

### ✅ What's FREE:
- **Codemagic Free Tier**: 500 build minutes/month (enough for 30-50 builds)
- **Building the IPA**: Completely free using debug mode
- **Installing on YOUR iPhone**: Free via AltStore
- **Duration**: Works for your school project timeline

### ❌ What's NOT FREE (The Catch):
1. **App Expiration**: 
   - Debug builds installed via AltStore expire after **7 days**
   - You must re-install every week
   - This is an Apple limitation, not Codemagic

2. **Distribution to Others**:
   - Can't share the app with classmates/teachers easily
   - Each person needs to install via AltStore on their own

3. **App Store Release** (Optional):
   - Requires Apple Developer Account: **$99/year**
   - Only needed if you want to publish to App Store
   - NOT required for school projects

### 🎓 For School Projects:
**Verdict**: 100% FREE if you're okay with:
- Re-installing every 7 days
- Only installing on your own iPhone
- Not publishing to App Store

---

## 🚀 Step-by-Step Setup

### Step 1: Prepare Your Project

1. **Add Firebase iOS Configuration** (if not done):
   ```bash
   # Download GoogleService-Info.plist from Firebase Console
   # Place it in: ios/Runner/GoogleService-Info.plist
   ```

2. **Update Bundle Identifier**:
   - Open `ios/Runner.xcodeproj` in Xcode (if you have Mac)
   - OR edit `ios/Runner.xcodeproj/project.pbxproj` and search for `PRODUCT_BUNDLE_IDENTIFIER`
   - Change to: `com.yourname.fitnesstracker`

3. **Commit and Push to GitHub**:
   ```bash
   git add .
   git commit -m "iOS configuration ready"
   git push origin main
   ```

### Step 2: Codemagic Setup

1. **Sign Up**:
   - Go to [codemagic.io](https://codemagic.io)
   - Click "Sign in with GitHub"
   - Authorize Codemagic to access your repos

2. **Add Application**:
   - Click "Add application"
   - Select your `fitness_tracker` repository
   - Choose "Flutter App"

3. **Configure Build**:
   - Codemagic will detect `codemagic.yaml` automatically
   - Select workflow: **"iOS Debug (FREE - No Signing)"**
   - Update email in `codemagic.yaml`:
     ```yaml
     vars:
       NOTIFICATION_EMAIL: "your@email.com"
     ```

4. **Start Build**:
   - Click "Start new build"
   - Select branch: `main`
   - Wait 10-15 minutes for first build

5. **Download IPA**:
   - Build completes → Click "Artifacts"
   - Download `fitness_tracker_debug.ipa`

### Step 3: Install on iPhone (FREE Method)

#### Option A: AltStore (Recommended)

**On Windows PC**:
1. Download [AltServer](https://altstore.io) for Windows
2. Install iTunes (required for device communication)
3. Run AltServer from system tray (look for icon)

**On iPhone**:
1. Connect iPhone to PC via USB cable
2. Trust the computer when prompted on iPhone
3. In AltServer (PC), click icon → Install AltStore → Select your iPhone
4. Enter Apple ID and password (stays on your device only)
5. AltStore app installs on iPhone

**Install Your App**:
1. Open AltStore on iPhone
2. Go to "My Apps" tab
3. Tap "+" button
4. Select `fitness_tracker_debug.ipa` from your PC
5. App installs and appears on home screen

**Important**:
- Refresh every 7 days: Open AltStore → Refresh
- Keep AltServer running on PC when refreshing
- iPhone must be on same WiFi as PC

#### Option B: Xcode (If You Have Mac)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Connect iPhone via USB
3. Select your iPhone as target device
4. Click Run button
5. Trust developer certificate on iPhone

---

## 🔧 Troubleshooting

### Build Fails: "Pod install failed"

**Fix**: Update `ios/Podfile`:
```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

# Add this at the end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

### Build Fails: "Firebase not configured"

**Fix**: 
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Add iOS app with bundle ID: `com.yourname.fitnesstracker`
4. Download `GoogleService-Info.plist`
5. Place in `ios/Runner/` folder
6. Commit and push to GitHub

### AltStore: "Could not find AltServer"

**Fix**:
- Make sure AltServer is running (check system tray)
- iPhone and PC must be on same WiFi network
- Disable VPN if active
- Restart AltServer

### App Crashes on Launch

**Fix**:
- Check iOS version (requires iOS 12.0+)
- View crash logs: Settings → Privacy → Analytics → Analytics Data
- Look for `Runner-` logs
- Share logs for debugging

---

## 📊 Build Time & Cost Estimates

| Task | Time | Cost |
|------|------|------|
| First build | 15-20 min | FREE |
| Subsequent builds | 5-8 min | FREE |
| Monthly builds (30x) | ~150 min | FREE (within 500 min limit) |
| AltStore setup | 10 min | FREE |
| Weekly refresh | 2 min | FREE |

**Total for School Project**: $0.00 ✅

---

## 🎯 Recommended Workflow for School Project

### Week 1-2: Development
- Build on Android (faster testing)
- Use Android emulator or physical device

### Week 3: iOS Testing
- Create iOS build on Codemagic
- Install via AltStore
- Test all features on iPhone

### Week 4: Demo Preparation
- Build final version 1-2 days before presentation
- Test thoroughly
- Keep AltStore refreshed

### Demo Day:
- App will work perfectly (within 7-day window)
- Have backup: Screen recording or Android version

---

## 🆚 Alternatives Comparison

| Method | Cost | Expiry | Ease | Best For |
|--------|------|--------|------|----------|
| **AltStore** | FREE | 7 days | Medium | School projects |
| **Xcode (Mac)** | FREE | 7 days | Easy | If you have Mac |
| **TestFlight** | $99/year | None | Easy | Professional apps |
| **App Store** | $99/year | None | Hard | Public release |

---

## ❓ FAQ

**Q: Can I avoid the 7-day expiry?**
A: No, unless you pay $99/year for Apple Developer account.

**Q: Can my teacher install the app?**
A: Yes, but they need to use AltStore too. Better: Show on your phone or use screen recording.

**Q: Will this work for my final presentation?**
A: Yes! Just build 1-2 days before and it'll work perfectly during demo.

**Q: What if I run out of 500 free minutes?**
A: Unlikely for school project. If needed, create new Codemagic account with different email.

**Q: Is this legal?**
A: 100% legal. Apple allows this for personal development and testing.

---

## 📞 Support

**Codemagic Issues**:
- Docs: https://docs.codemagic.io
- Support: support@codemagic.io

**AltStore Issues**:
- FAQ: https://altstore.io/faq
- Reddit: r/AltStore

**Firebase Issues**:
- Console: https://console.firebase.google.com
- Docs: https://firebase.google.com/docs

---

## ✅ Final Checklist

Before building:
- [ ] iOS folder created (`flutter create --platforms=ios .`)
- [ ] Info.plist has all permissions
- [ ] GoogleService-Info.plist added (if using Firebase)
- [ ] Bundle identifier updated
- [ ] Code pushed to GitHub
- [ ] Email updated in codemagic.yaml

Before demo:
- [ ] Build created within last 7 days
- [ ] App tested on iPhone
- [ ] AltStore refreshed
- [ ] Backup plan ready (screen recording)

---

**Good luck with your school project! 🎓📱**
