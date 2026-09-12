# دليل النشر والربط السريع: Supabase + Render لتطبيق ميزان (MIZAN)

هذا الدليل يشرح لك خطوة بخطوة كيفية رفع وتشغيل الـ Backend لتطبيق **ميزان** مجاناً بالكامل عبر **Supabase (قاعدة بيانات PostgreSQL)** و **Render (استضافة السيرفر)** وربطه مع تطبيق فلاتر.

---

## 🌟 لماذا هذا الخيار هو الأفضل لمشروعك؟
1. **مجاني 100%**: باقة مجانية دائمة على Supabase (قاعدة بيانات 500 ميجابايت مع نسخ احتياطي) وباقة مجانية على Render.
2. **سهل جداً وسريع**: بدون الحاجة لأوامر معقدة أو بطاقة بنكية في البداية.
3. **لوحة تحكم خرافية**: Supabase يعطيك واجهة سهلة مثل الإكسل لتصفح الجداول، المستخدمين، والمصروفات مباشرة من المتصفح.
4. **تحديث تلقائي**: بمجرد أن ترفع كودك إلى GitHub، يقوم Render بإعادة البناء والتحديث تلقائياً (`Continuous Deployment`).

---

## 🛠️ الخطوة 1: إنشاء قاعدة بيانات Supabase (دقيقتين)

1. ادخل إلى موقع [supabase.com](https://supabase.com) واضغط **Start your project** وسجل دخول بحساب GitHub أو Google.
2. اضغط على **New project**:
   - **Name**: اكتب `mizan-db`
   - **Database Password**: اكتب كلمة مرور قوية واحفظها عندك (مثلاً: `MizanSecure2026!`).
   - **Region**: اختر `Frankfurt` أو `London` (الأقرب للشرق الأوسط).
   - اضغط **Create new project** وانتظر دقيقة حتى يكتمل تجهيز القاعدة.
3. انسخ رابط الاتصال:
   - من القائمة الجانبية في Supabase اضغط على **Project Settings (أيقونة الترس)** ⚙️ -> **Database**.
   - انزل إلى قسم **Connection string** واختر تبويب **URI** أو **Parameters**.
   - سيكون الرابط بهذا الشكل تقريباً:
     ```text
     Host=aws-0-eu-central-1.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.YOUR_PROJECT_REF;Password=كلمة_المرور_التي_اخترتها;SSL Mode=Require;Trust Server Certificate=true;
     ```
   *(استبدل `Password` بكلمة المرور التي حددتها في الخطوة 2).*

---

## 🚀 الخطوة 2: رفع كود ميزان إلى GitHub

إذا لم تكن قد أنشأت مستودعاً للمشروع على GitHub بعد:

1. افتح الطرفية (Terminal) في مجلد المشروع الرئيسي:
   ```bash
   git init
   git add .
   git commit -m "Initial production commit for Mizan with Supabase and Render"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/mizan.git
   git push -u origin main
   ```
*(أنشئ مستودعاً جديداً فارغاً على حسابك في GitHub باسم `mizan` واستبدل `YOUR_USERNAME` باسم حسابك).*

---

## 🌐 الخطوة 3: إنشاء الخدمة على Render.com (3 دقائق)

1. ادخل إلى موقع [render.com](https://render.com) وسجل دخول بحساب GitHub.
2. في الصفحة الرئيسية، اضغط على زر **New +** واختر **Web Service**.
3. اختر مستودع مشروع **Mizan** من قائمة مستودعاتك على GitHub واضغط **Connect**.
4. سيقرأ Render ملف `Dockerfile` تلقائياً. املأ الإعدادات التالية:
   - **Name**: `mizan-api`
   - **Region**: `Frankfurt (EU Central)`
   - **Instance Type**: `Free`
5. انزل إلى قسم **Environment Variables** (المتغيرات البيئية) واضغط **Add Environment Variable** وأضف الآتي:

| Key (اسم المتغير) | Value (القيمة) |
| :--- | :--- |
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `ConnectionStrings__DefaultConnection` | *(رابط اتصال Supabase الذي نسخته من الخطوة 1)* |
| `AUTO_MIGRATE` | `true` *(لإنشاء الجداول والفئات في Supabase تلقائياً)* |
| `Jwt__Key` | `Mizan_Super_Secret_Jwt_Key_2026_SaudiArabia_SecureToken_Minimum_64_Chars_Long!` |
| `AI__Provider` | `Gemini` |
| `AI__ApiKey` | `YOUR_GEMINI_API_KEY` |
| `Notification__Enabled` | `true` |

6. اضغط على **Create Web Service** في أسفل الصفحة.

✨ **ماذا سيحدث الآن؟**
- سيقوم Render بسحب الكود وبناء الحاوية Docker تلقائياً.
- عند تشغيل السيرفر، سيتصل تلقائياً بقاعدة بيانات Supabase، ويُنشئ جميع الجداول الـ 14 (المستخدمين، المحافظ، المصروفات، الميزانيات، الفئات، مستشار الذكاء الاصطناعي)، ويملأ الفئات الـ 12 المعتمدة.
- بعد دقيقتين ستظهر علامة **Live** باللون الأخضر، وسيعطيك Render رابطاً مثل:
  `https://mizan-api.onrender.com`

---

## 🔍 الخطوة 4: التحقق من نجاح الرفع

1. افتح الرابط التالي في المتصفح:
   ```text
   https://mizan-api.onrender.com/health
   ```
   يجب أن تظهر لك النتيجة فوراً:
   ```json
   {"status":"Healthy"}
   ```
2. ادخل إلى **Supabase** -> ثم اضغط على **Table Editor** من القائمة الجانبية:
   - ستجد جميع الجداول تم إنشاؤها تلقائياً: `Users`, `Wallets`, `Transactions`, `Categories`, `Budgets`, `FinancialCommitments`, إلخ.
   - عند فتح جدول `Categories` ستجد الفئات الـ 12 الرئيسية مضافة ومترجمة باللغتين العربية والإنجليزية.

---

## 📱 الخطوة 5: ربط تطبيق الجوال (Flutter) بالسيرفر الجديد

الآن بعد أن حصلت على رابط الـ API الحي، يمكنك ربطه بالتطبيق بإحدى طريقتين:

### الطريقة 1 (الأسهل - تعديل الرابط الافتراضي):
افتح الملف:
[mobile/lib/core/config/api_config.dart](file:///e:/all-project/Mizan/mobile/lib/core/config/api_config.dart)
وعدل السطر التالي بالرابط الذي حصلت عليه من Render:
```dart
static const String prodBaseUrl = 'https://mizan-api.onrender.com/api';
```

### الطريقة 2 (أثناء بناء التطبيق مباشرة عبر Terminal):
```bash
cd mobile

# بناء نسخة الـ APK للأندرويد:
flutter build apk --release --dart-define=MIZAN_ENV=prod --dart-define=API_BASE_URL="https://mizan-api.onrender.com/api"
```

وستجد ملف الـ APK الجاهز للتثبيت في:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## 💡 نصيحة بخصوص باقة Render المجانية
في باقة Render المجانية، إذا لم يتلقَ السيرفر أي طلب لمدة 15 دقيقة فإنه يدخل في وضع النوم (Spin down) لتوفير الموارد، وعند فتح التطبيق لأول مرة يستغرق نحو 10 إلى 20 ثانية للاستيقاظ (Cold Start). 
إذا رغبت لاحقاً في أن يكون السيرفر سريعاً واستجابته فورية دائماً دون نوم، يمكنك ترقيته إلى باقة `Starter` بـ 7$ شهرياً فقط.
