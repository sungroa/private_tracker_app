# Fixing Cloud Sync in Release Build

The `GoogleSignInExceptionCode.canceled` error you received occurs because your **Release APK** is signed with a different key than your development environment. Google Cloud rejects the sync request because its SHA-1 fingerprint hasn't been registered.

## Step 1: Copy your Release SHA-1
You already found your release SHA-1 in the previous step:
`34:ED:78:36:10:E4:70:10:2C:50:4F:30:49:59:92:F5:60:83:83:07`

## Step 2: Add to Google Cloud Console
1. Go to the [Google Cloud Console Credentials Page](https://console.cloud.google.com/apis/credentials).
2. Find the **OAuth 2.0 Client IDs** section.
3. Look for your existing **Android Client ID** (or create a new one for Release if you prefer to keep them separate).
4. Click the Edit (pencil) icon.
5. Under **SHA-1 certificate fingerprint**, paste the SHA-1 from Step 1.
   - *Note: You can add multiple SHA-1s to the same Client ID.*
6. Click **SAVE**.

## Step 3: Wait and Re-test
- It can take a few minutes (up to 5-10) for Google's servers to propagate the change.
- You **do not** need to re-build your APK for this change, as the SHA-1 is verified on the server side.
- Try clicking "SYNC NOW" in the app again.

## Why this happened?
Each Android app build (Debug vs Release) has a unique digital signature. Google Sign-In uses this signature to verify that the authentication request is coming from your authorized app and not an impersonator.
