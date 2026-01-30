# Fix Xcode Build Error - PhaseScriptExecution

## Quick Fix Steps:

1. **Open the project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   (NOT .xcodeproj - must use .xcworkspace)

2. **Select the Runner target:**
   - Click on "Runner" in the left navigator
   - Select the "Runner" target (not the project)
   - Go to "Signing & Capabilities" tab

3. **For Simulator builds:**
   - Uncheck "Automatically manage signing" temporarily
   - Or select "None" for Team
   - This allows building for simulator without signing

4. **For Device builds:**
   - Check "Automatically manage signing"
   - Select your Apple ID/Development Team
   - Xcode will automatically create a provisioning profile

5. **Clean Build Folder:**
   - In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
   - Then try building again

## Alternative: Use Flutter Command

Instead of building in Xcode, you can use Flutter which handles signing automatically:

```bash
flutter run -d <simulator-id>
```

This will automatically handle code signing for simulators.
