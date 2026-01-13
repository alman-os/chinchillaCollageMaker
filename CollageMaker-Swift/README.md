# Collage Maker - Swift + SwiftUI

Native macOS photo collage maker built with Swift and SwiftUI.

## Phase A: Scaffold + Run

### What's Included
- Complete Xcode project
- SwiftUI app entry point
- Minimal ContentView scaffold
- Native macOS window (500x600, non-resizable)

### How to Run

1. **Open the project:**
   ```bash
   open CollageMaker.xcodeproj
   ```

2. **In Xcode:**
   - Wait for indexing to complete
   - Press `Cmd + R` to build and run
   - Or click the Play button in top-left

### Expected Result (Phase A)

A native macOS window opens showing:
- **"📸 Collage Maker"** heading
- **"Phase A - Swift + SwiftUI"** 
- **"Native macOS app is running!"**

Window properties:
- Size: 500x600
- Non-resizable
- Native macOS look and feel

### Next Phase

Once Phase A window opens successfully, reply with:
**"Phase A ✅ - native window opens"**

Then we proceed to **Phase B: UI Layout** (drop zone, buttons, counter).

## Project Structure

```
CollageMaker/
├── CollageMakerApp.swift    # App entry point
├── ContentView.swift         # Main view
├── Assets.xcassets/          # App assets & icons
└── CollageMaker.entitlements # Sandbox permissions
```

## 📦 Installation

**Note:** This app is not signed with an Apple Developer ID (because I'm an indie dev sharing free tools!).

1. Download the latest `CollageMaker.zip` from [Releases](link-to-your-releases).
2. Unzip the app and drag it to your Applications folder.
3. **If macOS says the app is "damaged" or "cannot be opened":**
   
   **Option A (Right Click):**
   * Right-click the app and select **Open**.
   * Click **Open** again in the dialog box.
   
   **Option B (Terminal - The "Pro" Way):**
   * Open Terminal.
   * Paste this command and hit Enter:
     ```bash
     xattr -cr /Applications/CollageMaker.app
     ```
   * Open the app normally.