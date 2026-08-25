# النشر على Render (تجربة حقيقية)

## ملخص مهم عن قاعدة البيانات
النظام صمّمناه ليدعم **PostGIS بشكل اختياري**:
- إن استخدمت قاعدة تدعم PostGIS (مثل **Supabase**) → تعمل كل الميزات (الخرائط الحية، الجيوفنس، تقييم الثقة بالموقع).
- إن استخدمت **Render Postgres العادي** (مجاني، بحساب Render واحد فقط) → يُخزَّن الموقع كنصوص، ويعمل باقي النظام بالكامل للتجربة: الدخول، الموظفون، **التقارير (Excel/PDF)**، الحوافز، التقييمات، البلاغات.

يعني: تقدر ترفع كل شي على Render بحساب واحد بدون استخدام Supabase.

---

## 1) إنشاء قاعدة البيانات (Render Postgres)
1. في Render: **New → PostgreSQL**.
2. الاسم مثلاً `yarmouk-db`، الخطة **Free**، المنطقة الأقرب لك.
3. بعد الإنشاء انسخ رابط `Internal Database URL` (أو External Database URL).

> تريد الميزات الجغرافية الكاملة؟ أنشئ مشروع **Supabase** بدلاً من ذلك، ونفّذ في SQL Editor:
> `create extension if not exists postgis;`
> ثم استخدم رابط قاعدة Supabase كـ `DATABASE_URL`.

---

## 2) نشر الـ Backend (Web Service)
1. **New → Web Service** واربط مستودع GitHub الخاص بالمشروع.
2. استخدم ملف `render.yaml` (يُنشئ خدمة `yarmouk-backend` تلقائياً):
   - **Root Directory:** `backend`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path:** `/health`
3. في تبويب **Environment** اضبط المتغيرات:
   - `DATABASE_URL` = رابط قاعدة البيانات من الخطوة 1 (Render Postgres أو Supabase).
   - `JWT_SECRET_KEY` = نص طويل عشوائي، مثلاً:
     `python -c "import secrets; print(secrets.token_hex(32))"`
4. عند أول تشغيل، النظام تلقائياً: يُنشئ الجداول، يبذر الـ**17 دوراً**، ويُنشئ حساب **`admin`**.

---

## 3) بناء الواجهة ونشرها (Static Site)
### أ) ابنِ الويب محلياً (استبدل الرابط برابط الباك-إند من Render):
```bash
cd mobile_app
flutter build web --target=lib/main_web.dart \
  --dart-define=API_BASE_URL=https://yarmouk-backend.onrender.com/v1 \
  --release
```
### ب) ارفعه على Render كـ Static Site:
- **الطريقة الأسهل (يدوي):** Render → **New → Static Site** → اسحب وأفلت مجلد `mobile_app/build/web`. (لا يحتاج بناء على Render.)
- **أو من الريبو:** اربط المستودع، Root = `mobile_app`، Build Command = `echo "prebuilt"`، Publish Directory = `build/web` (يشترط أن يكون المجلد مرفوعاً في الريبو).

---

## 4) الدخول والتجربة
- افتح رابط الويب على Render.
- **دخول تجريبي (بدون سيرفر):** اضغط «دخول تجريبي» ثم اختر دوراً (مثل مشرف النظام) — يظهر لك كل الوحدات ببيانات وهمية.
- **دخول حقيقي بقاعدة منشورة:** `admin` / `Yarmouk@2025` (يُنشأ تلقائياً عند أول تشغيل للباك-إند على قاعدة حقيقية).
- جرّب: لوحة المعلومات، الموظفون، **التقارير** (تصدير Excel / طباعة PDF)، الحوافز، التقييمات، البلاغات.

---

## 5) ملاحظات
- CORS مفتوح مؤقتاً (`allow_origins=["*"]`) لتسهيل التجربط أثناء التجربة.
- كل مسارات الـ API تحت بادئة `/v1` (مطابقة لما يتوقعه تصريف الويب).
- مجاناً: خدمة Render Free تنام بعد فترة من عدم النشاط، أول طلب قد يتأخر قليلاً.
- للإنتاج لاحقاً: اربط نطاق `api.yarmouk-water.jo` واضبط `API_BASE_URL` عند البناء، وشدّد الـ CORS.
