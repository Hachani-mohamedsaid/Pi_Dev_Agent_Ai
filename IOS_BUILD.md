# iOS build – run on your iPhone

## If you see "resource fork / detritus not allowed" or "CodeSign failed"

On **macOS Sequoia and later**, the system can add extended attributes that break codesigning. Do this:

### 1. Grant Full Disk Access (required for codesign to succeed)

1. Open **System Settings → Privacy & Security → Full Disk Access**.
2. Click **+** and add:
   - **Terminal** (e.g. `/Applications/Utilities/Terminal.app`)
   - **Xcode** (if you build/run from Xcode)
   - **Cursor** (if you run `flutter` from Cursor’s terminal)
3. Quit and reopen Terminal/Xcode/Cursor so the change applies.

### 2. Build and run

**Option A – from Terminal (recommended)**

```bash
cd /path/to/Pi_Dev_Agent_Ai
./scripts/ios_build_fix_codesign.sh
```

Then in Xcode: open `ios/Runner.xcworkspace`, select your iPhone, and click Run.

**Option B – from Xcode only**

After granting Full Disk Access to **Xcode**, open `ios/Runner.xcworkspace`, select your iPhone, and click Run.

**Option C – Flutter CLI then device**

```bash
flutter build ios --debug
# Then run on device from Xcode, or:
flutter run
```

### 3. If you still get "sandbox not in sync with Podfile.lock"

```bash
cd ios && pod install && cd ..
```

### 4. If you get "disk I/O error" or odd Xcode build errors

Clear Xcode’s build data for this project:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
```

Then build again.
