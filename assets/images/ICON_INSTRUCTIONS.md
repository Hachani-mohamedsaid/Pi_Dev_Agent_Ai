# Official Google and Apple Icons Setup

## Google Icon

1. **Download the official Google "G" icon:**
   - Visit: https://developers.google.com/identity/branding-guidelines
   - Download the "G" logo in PNG format
   - Choose the white/light version suitable for dark backgrounds
   - Recommended size: 24x24px or 32x32px (will be scaled automatically)

2. **Save the file:**
   - Name it: `google_icon.png`
   - Place it in: `assets/images/google_icon.png`

## Apple Icon

1. **Download the official Apple icon:**
   - Visit: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
   - Download the Apple logo icon in PNG format
   - Choose the white/light version suitable for dark backgrounds
   - Recommended size: 24x24px or 32x32px (will be scaled automatically)

2. **Save the file:**
   - Name it: `apple_icon.png`
   - Place it in: `assets/images/apple_icon.png`

## Alternative: Quick Download Links

If you need direct download links, you can also:
- Search for "Google G logo PNG white" on Google Images
- Search for "Apple logo PNG white" on Google Images
- Make sure to use official brand assets to comply with brand guidelines

## After Adding Icons

1. The icons are already configured in the code
2. Run `flutter pub get` (if needed)
3. Rebuild the app
4. The icons will automatically appear in the login/register buttons

## Note

If the image files are not found, the app will show fallback icons (text "G" for Google and an Apple icon for Apple) so the app will still work while you add the official assets.
