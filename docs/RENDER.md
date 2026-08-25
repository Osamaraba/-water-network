# نشر منصة مياه اليرموك على Render

تتضمن المنصة:
- **Backend** (FastAPI + PostgreSQL + Redis) يُنشر كخدمة Web.
- **Frontend** (لوحة تحكم ويب بـ Flutter) يُبنى عبر Docker ويُقدَّم بـ nginx.

---

## 1) رفع الكود إلى GitHub
المشروع أصبح مستودع Git محلياً. ارفعه إلى مستودع GitHub جديد (أو موجود):

```bash
git remote add origin <رابط_المستودع_على_GitHub>
git push -u origin main
```

## 2) الربط مع Render
1. سجّل الدخول إلى [dashboard.render.com](https://dashboard.render.com).
2. **New → Blueprint**.
3. اختر المستودع، واتركه يقرأ ملف `render.yaml` الموجود في الجذر.
4. اضغط **Apply**؛ سيُنشئ Render الخدمات:
   - `yarmouk-db` (Postgres)
   - `yarmouk-redis`
   - `yarmouk-backend` (الـ API على `https://yarmouk-backend.onrender.com`)
   - `yarmouk-web` (لوحة التحكم)

> أسماء الخدمات مهمة: الواجهة مُترجَمة مسبقاً لتستدعي
> `https://yarmouk-backend.onrender.com/v1`. إن غيّرت اسم خدمة الـ Backend،
> حدّث قيمة `API_BASE_URL` في `render.yaml` وأعد البناء.

## 3) الحساب الموحّد (Universal Login)
يُنشئ الـ Backend تلقائياً عند التشغيل حساباً مشتركاً للدخول المباشر:
- **اسم المستخدم:** `ENG.OR`
- **كلمة المرور:** `ENG.OR`

يُسجَّل الدخول تلقائياً للجميع، ويمكن من شاشة **الإعدادات** تغيير:
- اسم الموظف ورقم الهاتف (`PATCH /employees/me`)
- كلمة المرور (`POST /auth/change-password`)

## 4) متغيّرات البيئة (تُضبط تلقائياً عبر Blueprint)
| المتغيّر | المصدر |
|---------|--------|
| `DATABASE_URL` | من قاعدة Postgres المُنشأة |
| `REDIS_URL` | من خدمة Redis المُنشأة |
| `JWT_SECRET_KEY` | يولّدها Render تلقائياً |
| `PYTHON_VERSION` | `3.11` |

## 5) ملاحظات
- خطط `free` تتوقف بعد فترة خمول؛ أول طلب قد يتأخر قليلاً.
- إن أردت بناء الواجهة محلياً بدل Docker:
  ```bash
  cd mobile_app
  flutter build web -t lib/main_web.dart \
    --dart-define=API_BASE_URL=https://yarmouk-backend.onrender.com/v1 --release
  ```
  ثم انشر محتوى `build/web` كـ Static Site.
