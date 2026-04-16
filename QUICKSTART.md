
### Step 1: Clone & Setup (1 min)
```bash
cd <project-root>
flutter pub get
```

### Step 2: Firebase Setup (2 mins)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project named "Holics"
3. Add Android app (package: `com.example.the_holics`)
4. Download `google-services.json` → place in `android/app/`
5. Copy Firebase credentials to `.env` file

### Step 3: Configure `.env` (1 min)
```env
FIREBASE_API_KEY=YOUR_KEY_HERE
FIREBASE_APP_ID=YOUR_APP_ID_HERE
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID_HERE
FIREBASE_PROJECT_ID=the-holics
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
```

### Step 4: Run App (1 min)
```bash
flutter run
```

## 📱 Default Test Credentials

**Test User:**
- Email: `member@holics.app`
- Password: `test123456`
- Role: Member

**Admin User:**
- Email: `admin@holics.app`
- Password: `test123456`
- Role: Admin

> ⚠️ Create these users in Firebase Auth after initial setup

## 🎯 First Time Setup Checklist

- [ ] Flutter installed (`flutter --version`)
- [ ] Firebase project created
- [ ] `google-services.json` added to `android/app/`
- [ ] `.env` file configured with credentials
- [ ] Test users created in Firebase Auth
- [ ] Firestore database created
- [ ] iOS/Android emulator or device connected
- [ ] Run `flutter pub get`
- [ ] Run `flutter run`

## 🔑 Key Features to Test

### Authentication
1. Launch app → sees login screen
2. Sign up with new email
3. Sign in as member or admin
4. Test password reset

### Home Screen
- View upcoming appointments
- Navigate to Body/Skin Holics sections
- Access profile settings

### Body Holics
- Browse subscription plans
- View locked/unlocked workouts
- Check nutrition plans

### Skin Holics  
- Go through 4-step booking flow
- Select service → date/time → specialist → confirm
- Appointment appears in profile

### Admin Dashboard
- View statistics dashboard
- Browse members table
- Check subscription data
- Manage appointments

## 🐛 Common First-Time Issues

### "Firebase not initialized"
→ Check `.env` file has correct credentials

### "Missing google-services.json"
→ Download from Firebase Console and place in `android/app/`

### "Firestore permission denied"
→ Update Firestore rules (see README_SETUP.md)

### "App won't run on device"
→ Run `flutter clean && flutter pub get`

## 📚 Documentation

- **Full Setup Guide:** See `README_SETUP.md`
- **Project Structure:** See below
- **API Documentation:** In code comments

## 📁 Project Structure Overview

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── theme/app_theme.dart  # Design system
│   ├── router/app_routes.dart # Navigation
│   └── constants/            # App strings & constants
├── features/
│   ├── auth/                 # Login, signup, reset password
│   ├── home/                 # Main dashboard
│   ├── body_holics/          # Gym & fitness section
│   ├── skin_holics/          # Beauty & appointments
│   ├── admin/                # Admin dashboard
│   └── profile/              # User profile
├── shared/
│   ├── models/               # Data classes
│   ├── providers/            # Riverpod state
│   ├── services/             # Firebase services
│   └── widgets/              # Reusable UI components
```

## 🔗 Useful Links

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Console](https://console.firebase.google.com)
- [Stripe Dashboard](https://dashboard.stripe.com)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Go Router Docs](https://pub.dev/packages/go_router)

## ✅ Next Steps

1. **Test all features** with test credentials
2. **Configure Stripe** for payments (see README_SETUP.md)
3. **Customize branding** (colors, fonts, logos)
4. **Add push notifications** setup
5. **Deploy to stores** when ready

## 🆘 Need Help?

- Check `README_SETUP.md` for detailed setup instructions
- Look for comments in code files
- Check Flutter & Firebase official documentation
- Review Firestore security rules in README_SETUP.md

---

**Happy coding! 🎉**

For issues or questions, refer to the full setup guide in `README_SETUP.md`.
