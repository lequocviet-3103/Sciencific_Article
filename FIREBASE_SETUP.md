# Firebase Setup Guide - ResearchHub

## 1. Tạo Firebase Project

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** → đặt tên: `scientific-article-b73bc`
3. Tắt Google Analytics nếu không cần → **Create project**
4. Sau khi tạo xong, vào **Project Settings**

---

## 2. Android App

### Step 1: Thêm Android App
1. Trong Project Settings → **Add app** → chọn **Android**
2. Điền:
   - **Android package name**: `com.example.prm393lab2jta`
   - **App nickname**: `ResearchHub`
   - **Debug signing certificate SHA-1**: (optional - chạy lệnh bên dưới để lấy)

```bash
# Lấy SHA-1 từ debug keystore (default password: android)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

3. Click **Register app**
4. Download `google-services.json` → copy vào `Journal_Trend_Analysis/android/app/`
5. Tiếp tục setup theo hướng dẫn trên màn hình (thêm classpath và plugin vào build.gradle)

### Step 2: Cấu hình build.gradle
File `android/build.gradle` (project level):
```groovy
dependencies {
    classpath 'com.android.tools.build:gradle:8.1.0'
    classpath 'com.google.gms:google-services:4.4.0'  // Thêm dòng này
}
```

File `android/app/build.gradle`:
```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "com.google.gms.google-services"  // Thêm dòng này
}
```

---

## 3. iOS App (optional)

1. Trong Firebase Console → **Add app** → **iOS**
2. Điền:
   - **iOS bundle ID**: `com.example.prm393lab2jta`
   - **App Store ID**: (optional)
3. Download `GoogleService-Info.plist`
4. Import vào Xcode: kéo thả vào `ios/Runner/`

---

## 4. Bật Authentication

1. **Authentication** → **Get started**
2. Tab **Sign-in method**:
   - **Email/Password**: bật → Save
   - **Google**: bật → chọn Web Client ID (tạo ở bước 5)

---

## 5. Google Sign-In OAuth 2.0 Client IDs

### Tạo Web Client ID (bắt buộc cho Google Sign-In)
1. Mở [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn project `scientific-article-b73bc`
3. Menu → **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Chọn **Web application**
6. Đặt tên: `ResearchHub Web Client`
7. **Authorized JavaScript origins**:
   - `http://localhost:5255`
   - `http://localhost:8080`
8. **Authorized redirect URIs**:
   - `http://localhost:5255`
9. Click **Create**
10. Copy **Client ID** (dạng: `xxx.apps.googleusercontent.com`)

### Cập nhật Firebase Console
1. Firebase Console → **Authentication** → **Sign-in method** → **Google**
2. Paste **Web client ID** và **Web secret** (từ Google Cloud Console)

---

## 6. Các Key cần lấy cho Backend .NET

### Firebase Service Account (cho backend)
1. Firebase Console → **Project Settings** → tab **Service accounts**
2. Click **Generate new private key**
3. File JSON sẽ download về
4. Các giá trị cần extract vào `appsettings.json`:

```json
{
  "Firebase": {
    "type": "service_account",
    "project_id": "scientific-article-b73bc",
    "private_key_id": "...",
    "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-xxxxx@scientific-article-b73bc.iam.gserviceaccount.com",
    "client_id": "...",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
  }
}
```

---

## 7. Các Key cần lấy cho Flutter App

### File `lib/firebase_options.dart`
Lấy từ Firebase Console → Project Settings → **Your apps** → **Web app** → Config:

```dart
// Thay thế các giá trị DUMMY bằng:
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...',           // from Firebase Console
  appId: '1:xxx:android:xxx',   // from Firebase Console
  messagingSenderId: 'xxx',      // from Firebase Console
  projectId: 'scientific-article-b73bc',
  storageBucket: 'scientific-article-b73bc.appspot.com',
);
```

### Google Sign-In (lib/screens/login_screen.dart)
```dart
final googleSignIn = GoogleSignIn(
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```
→ Thay `YOUR_WEB_CLIENT_ID` bằng Web Client ID từ Google Cloud Console (bước 5)

---

## 8. Các Service Firebase cần bật

| Service | Mục đích | Cách bật |
|---|---|---|
| **Authentication** | Đăng nhập email/password, Google | Firebase Console → Authentication → Sign-in method |
| **Cloud Messaging (FCM)** | Push notifications | Firebase Console → Project Settings → Cloud Messaging |
| **Storage** | Upload avatar, report PDF | Firebase Console → Storage → Get started |
| **Analytics** | Log events login, search, view | Firebase Console → Analytics (bật tự động khi thêm Firebase) |
| **Remote Config** | Cấu hình từ xa | Firebase Console → Remote Config |
| **Crashlytics** | Theo dõi crash | Firebase Console → Crashlytics |

---

## 9. Tóm tắt Checklist

### Firebase Console:
- [ ] Tạo project `scientific-article-b73bc`
- [ ] Thêm Android app + download `google-services.json`
- [ ] Thêm iOS app + download `GoogleService-Info.plist` (optional)
- [ ] Bật **Email/Password** auth
- [ ] Bật **Google** auth + paste Web Client ID
- [ ] Bật **Cloud Messaging**
- [ ] Bật **Storage**
- [ ] Bật **Analytics**
- [ ] Bật **Remote Config**
- [ ] Bật **Crashlytics**
- [ ] Download **Service Account** JSON

### Google Cloud Console:
- [ ] Tạo **OAuth 2.0 Web Client ID**
- [ ] Copy Client ID → Firebase Console (Google Sign-In settings)
- [ ] Copy Client ID → Flutter `login_screen.dart`

### Flutter:
- [ ] Copy `google-services.json` → `android/app/`
- [ ] Update `lib/firebase_options.dart` với real values
- [ ] Update `login_screen.dart` `serverClientId`

### Backend .NET:
- [ ] Update `appsettings.json` với Firebase service account values
