# Codemagic iOS Deployment - Troubleshooting Context

## Project
- **App**: FitTracker - Flutter Fitness Tracker
- **Platform**: iOS deployment via Codemagic (free tier)
- **Installation Method**: AltStore to iPhone

## Current Status
✅ Codemagic build completed successfully (Build ID: 69e703bb1e86bfe628be8113)
✅ Build finished in 10m 32s
✅ iOS build step completed (5m 13s)
❌ **BLOCKED**: Cannot install to iPhone due to "Invalid anisette data" error

## The Error
```
Could not install AltStore to ZXN.
Invalid anisette data. Please close both iTunes and iCloud, then try again.
```

## Root Cause
- **3 AltServer instances running simultaneously** in system tray
- Multiple instances cause anisette data authentication conflicts
- iTunes/iCloud are NOT the issue (they're already closed)

## Solution Steps
1. Close ALL 3 AltServer instances from system tray (right-click → Quit)
2. Open Task Manager (Ctrl+Shift+Esc) and end all "AltServer.exe" processes
3. Also end these background processes if present:
   - AppleMobileDeviceService.exe
   - AppleApplicationSupport.exe
   - Any iTunes/iCloud helper processes
4. Restart computer (clears anisette cache)
5. Start only ONE AltServer instance
6. Wait for "Registering PC with Apple..." to complete
7. Retry Codemagic installation to iPhone

## Key Info
- **Codemagic URL**: https://codemagic.io/app/69e6feacb9ca8f3cb/build/69e703bb1e86bfe628be8113
- **GitHub Repo**: github.com/JmMosH16/fitness-tracker-app
- **Branch**: main
- **Commit**: e417f9f
- **Machine**: Mac mini M2

## Next Steps After Fix
1. Download .ipa from Codemagic artifacts
2. Use single AltServer instance to sideload to iPhone
3. Trust developer certificate on iPhone (Settings → General → VPN & Device Management)
4. Launch FitTracker app

## Alternative if AltStore Fails
- Use Sideloadly instead of AltStore
- Direct USB sideload with Xcode (requires Mac)
- TestFlight (requires Apple Developer account - $99/year)

---
**Use this prompt**: Reference this file with `@codemagic-troubleshooting.md` in future chats to restore context.
