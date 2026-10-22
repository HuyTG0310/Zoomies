# 🐾 Zoomies - AI-Powered Pet Health Triage & Care Assistant

Ứng dụng di động thông minh hỗ trợ chủ nuôi phân loại mức độ khẩn cấp (Triage) và sơ cứu sức khỏe ban đầu cho thú cưng (Chó & Mèo) bằng công nghệ trí tuệ nhân tạo **Google Gemini AI**, kết hợp cơ chế trò chuyện tiếp nối theo mô hình **Hybrid Triage Flow**.

---

## 📌 Mục lục
- [Giới thiệu dự án](#-giới-thiệu-dự-án)
- [Tính năng nổi bật](#-tính-năng-nổi-bật)
- [Kiến trúc công nghệ (Tech Stack)](#-kiến-trúc-công-nghệ-tech-stack)
- [Cấu trúc cơ sở dữ liệu Firestore](#-cấu-trúc-cơ-sở-dữ-liệu-firestore)
- [Cấu trúc thư mục dự án](#-cấu-trúc-thư-mục-dự-án)
- [Hướng dẫn cài đặt & Chạy ứng dụng](#-hướng-dẫn-cài-đặt--chạy-ứng-dụng)
- [Hướng dẫn phát triển Backend (Cloud Functions)](#-hướng-dẫn-phát-triển-backend-cloud-functions)
- [Nguyên tắc An toàn & Miễn trừ y tế](#-nguyên-tắc-an-toàn--miễn-trừ-y-tế)

---

## 📖 Giới thiệu dự án

Khi thú cưng xuất hiện các biểu hiện lạ (nôn mửa, ngứa gãi, biếng ăn, khó thở...), chủ nuôi thường rơi vào trạng thái hoang mang, không biết tình trạng có nguy hiểm cần đi cấp cứu ngay hay có thể theo dõi tại nhà. 

**Zoomies** giải quyết bài toán này thông qua luồng **Hybrid Triage Flow**:
1. **Thẻ đánh giá cố định (Triage Header Card):** AI phân tích nhanh hình ảnh triệu chứng + mô tả để phân loại mức độ khẩn cấp theo 3 màu tiêu chuẩn (Xanh - Vàng - Đỏ).
2. **Khung hội thoại thời gian thực (Follow-up Chat):** Trợ lý AI đồng hành, hướng dẫn các bước xử lý ngay tại nhà và cảnh báo khẩn cấp kịp thời nếu phát hiện tình trạng trở nặng.

---

## ✨ Tính năng nổi bật

### 1. Phân loại mức độ khẩn cấp sơ bộ (AI Triage)
- **Đa phương thức (Multimodal):** Phân tích kết hợp giữa hình ảnh chụp tổn thương và mô tả triệu chứng của chủ nuôi.
- **Nén ảnh tự động:** Tự động tối ưu dung lượng ảnh trên thiết bị trước khi gửi lên máy chủ để tiết kiệm băng thông và tăng tốc độ xử lý.
- **3 Cấp độ Triage tiêu chuẩn y tế thú y:**
  - 🟢 **Mức Xanh (GREEN):** Triệu chứng nhẹ, ổn định (trầy xước nông, ngứa nhẹ, biếng ăn 1 bữa nhưng vẫn lanh lợi...). Hướng dẫn theo dõi và chăm sóc cơ bản tại nhà.
  - 🟡 **Mức Vàng (YELLOW):** Dấu hiệu bất thường cần lưu ý (nôn 1-2 lần, tiêu chảy nhẹ, ho, nấm da...). Khuyến nghị đưa đi khám thú y trong vòng 24–48h.
  - 🔴 **Mức Đỏ (RED - CẤP CỨU):** Nguy hiểm đe dọa tính mạng (khó thở, thở há mồm, co giật, hôn mê, nôn/tiêu chảy ra máu...). Yêu cầu đưa đến trạm cấp cứu thú y **ngay lập tức** kèm hướng dẫn sơ cứu trên đường đi.

### 2. Trò chuyện giải đáp chuyên sâu (Hybrid Chat)
- Thẻ Triage Card ghim cố định ở đỉnh màn hình để người dùng luôn nắm rõ tình trạng và các bước sơ cứu cấp bách.
- Lịch sử hỏi đáp nối tiếp đồng bộ thời gian thực (Firestore Realtime Streams).
- **Phản ứng tức thì với tình huống nguy kịch:** Nếu người dùng thông báo triệu chứng chuyển biến xấu đột ngột, AI lập tức kích hoạt `🚨 [CẢNH BÁO MỨC ĐỘ ĐỎ]` ngay tại dòng đầu tiên của phản hồi.

### 3. Quản lý lịch sử ca bệnh (Checkup History)
- Quản lý toàn bộ các ca bệnh theo từng tài khoản.
- Lọc ca khám theo mức độ Triage (Tất cả, Xanh, Vàng, Đỏ) và trạng thái điều trị (Đang hoạt động, Theo dõi, Đã khỏi).

---

## 🛠 Kiến trúc công nghệ (Tech Stack)

### Frontend (Mobile App)
- **Framework:** [Flutter](https://flutter.dev/) (Dart 3.x), Material Design 3.
- **Quản lý kết nối Firebase:** `firebase_core`, `cloud_firestore`, `cloud_functions`.
- **Đa phương tiện & Xử lý ảnh:** `image_picker`, `flutter_image_compress`.
- **Định dạng thời gian:** `intl`.

### Backend & Cloud Infrastructure
- **Serverless Compute:** [Firebase Cloud Functions v2](https://firebase.google.com/docs/functions) (Node.js 22 LTS, TypeScript).
- **Trí tuệ nhân tạo (AI Engine):** [Google Gemini AI API](https://ai.google.dev/) (`@google/generative-ai`) với `gemini-1.5-flash` và cơ chế tự động chuyển vùng dự phòng (`gemini-3.5-flash`, `gemini-3.8-flash`).
- **Cơ sở dữ liệu:** [Cloud Firestore](https://firebase.google.com/docs/firestore) (NoSQL Database).
- **Bảo mật:** 
  - Firebase Secret Manager (`GEMINI_API_KEY`).
  - Firestore Security Rules phân quyền theo người dùng (`request.auth.uid`).

---

## 🗄 Cấu trúc cơ sở dữ liệu Firestore

```text
cloud.firestore
└── sessions/ (Collection các ca bệnh)
    └── {sessionId}/ (Document từng ca bệnh)
        ├── userId: string                    // UID người dùng
        ├── petType: "Chó" | "Mèo"            // Loài thú cưng
        ├── imageUrl: string                  // URL ảnh trên Firebase Storage
        ├── initialSymptoms: string           // Mô tả triệu chứng ban đầu
        ├── triageCard: map                   // Dữ liệu Thẻ Triage Card
        │   ├── urgencyLevel: "GREEN" | "YELLOW" | "RED"
        │   ├── summary: string               // Nhận định sơ bộ (2-3 câu)
        │   ├── possibleCauses: string[]      // Các nguyên nhân có thể
        │   ├── immediateActions: string[]    // Hướng dẫn xử lý ngay tại nhà
        │   └── vetQuestions: string[]        // Câu hỏi gợi ý cho bác sĩ thú y
        ├── createdAt: timestamp              // Thời điểm tạo ca bệnh
        ├── updatedAt: timestamp              // Thời điểm cập nhật tin nhắn cuối
        │
        └── messages/ (Sub-collection lưu lịch sử chat nối tiếp)
            └── {messageId}/
                ├── role: "user" | "model"    // Vai trò người gửi
                ├── text: string              // Nội dung tin nhắn
                └── createdAt: timestamp      // Thời gian gửi
```

---

## 📁 Cấu trúc thư mục dự án

```text
Zoomies/
├── android/                        # Cấu hình Android & google-services.json
├── functions/                      # Backend Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── gemini.ts               # Kết nối Gemini AI, Schema JSON & Fallback
│   │   ├── prompts.ts              # System Prompts (Prompt 1: Triage, Prompt 2: Chat)
│   │   ├── types.ts                # Khai báo TypeScript types & interfaces
│   │   └── index.ts                # 2 Callable Cloud Functions chính
│   ├── .secret.local               # Khóa API bí mật cục bộ (đã gitignore)
│   ├── package.json
│   └── tsconfig.json
├── lib/                            # Mã nguồn ứng dụng Flutter
│   ├── models/                     # Data models (SessionModel, ChatMessage, PetType, TriageLevel)
│   ├── screens/                    # Màn hình (NewCheckup, HybridTriageChat, History, HomeShell)
│   ├── services/                   # Logic nghiệp vụ (SessionService, ImageCompressionService)
│   ├── widgets/                    # Thành phần giao diện (TriageHeaderCard, ChatBubble, StepLoading)
│   ├── firebase_options.dart       # Cấu hình kết nối Firebase sinh bởi FlutterFire CLI
│   └── main.dart                   # Điểm khởi chạy ứng dụng (Khởi tạo Firebase)
├── firestore.rules                 # Quy tắc bảo mật Firestore
├── firestore.indexes.json          # Cấu hình Composite Index Firestore
├── firebase.json                   # Cấu hình dự án Firebase
└── README.md
```

---

## 🚀 Hướng dẫn cài đặt & Chạy ứng dụng

### Yêu cầu môi trường
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản `>= 3.13.5`)
- Thiết bị thật kết nối USB Debugging hoặc Android/iOS Emulator

### Các bước khởi chạy

1. **Clone repository về máy:**
   ```bash
   git clone https://github.com/tantrung0204/Zoomies.git
   cd Zoomies
   ```

2. **Chuyển sang nhánh tính năng:**
   ```bash
   git checkout feature/connect-firebase
   ```

3. **Cài đặt các gói phụ thuộc:**
   ```bash
   flutter pub get
   ```

4. **Kiểm tra trạng thái mã nguồn:**
   ```bash
   flutter analyze
   ```

5. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

> 💡 **Lưu ý:** Backend Cloud Functions đã được triển khai sẵn trên máy chủ Firebase (`zoomies-e296d`). Bạn có thể thử nghiệm tạo ca khám mới và trò chuyện với AI ngay mà không cần cấu hình thêm backend trên máy cá nhân.

---

## ⚙️ Hướng dẫn phát triển Backend (Cloud Functions)

Nếu bạn cần sửa đổi hoặc deploy lại Cloud Functions:

1. **Cài đặt dependencies cho thư mục `functions`:**
   ```bash
   cd functions
   npm install
   ```

2. **Biên dịch mã nguồn TypeScript:**
   ```bash
   npm run build
   ```

3. **Cấu hình GEMINI_API_KEY vào Firebase Secret Manager:**
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```

4. **Triển khai Functions & Firestore Rules:**
   ```bash
   firebase deploy --only functions,firestore
   ```

---

## ⚠️ Nguyên tắc An toàn & Miễn trừ y tế

> **LƯU Ý QUAN TRỌNG:**  
> Hệ thống Zoomies và AI Trợ lý Sơ cứu Thú cưng được xây dựng nhằm mục đích **sàng lọc sơ bộ ban đầu và cung cấp kiến thức chăm sóc hỗ trợ tại nhà**.  
> - AI **KHÔNG PHẢI** là bác sĩ thú y và **KHÔNG** đưa ra chẩn đoán y khoa xác định 100%.  
> - Hệ thống **TUYỆT ĐỐI KHÔNG KÊ ĐƠN THUỐC**, không cung cấp liều lượng thuốc đặc trị hay kháng sinh.  
> - Khi phát hiện các dấu hiệu khẩn cấp đe dọa tính mạng (khó thở, co giật, xuất huyết nặng...), hãy liên hệ ngay và đưa thú cưng đến **bệnh viện hoặc phòng khám thú y gần nhất**.

**Zoomies** giải quyết bài toán này thông qua luồng **Hybrid Triage Flow**:
1. **Thẻ đánh giá cố định (Triage Header Card):** AI phân tích nhanh hình ảnh triệu chứng + mô tả để phân loại mức độ khẩn cấp theo 3 màu tiêu chuẩn (Xanh - Vàng - Đỏ).
2. **Khung hội thoại thời gian thực (Follow-up Chat):** Trợ lý AI đồng hành, hướng dẫn các bước xử lý ngay tại nhà và cảnh báo khẩn cấp kịp thời nếu phát hiện tình trạng trở nặng.

---

## ✨ Tính năng nổi bật

### 1. Phân loại mức độ khẩn cấp sơ bộ (AI Triage)
- **Đa phương thức (Multimodal):** Phân tích kết hợp giữa hình ảnh chụp tổn thương và mô tả triệu chứng của chủ nuôi.
- **Nén ảnh tự động:** Tự động tối ưu dung lượng ảnh trên thiết bị trước khi gửi lên máy chủ để tiết kiệm băng thông và tăng tốc độ xử lý.
- **3 Cấp độ Triage tiêu chuẩn y tế thú y:**
  - 🟢 **Mức Xanh (GREEN):** Triệu chứng nhẹ, ổn định (trầy xước nông, ngứa nhẹ, biếng ăn 1 bữa nhưng vẫn lanh lợi...). Hướng dẫn theo dõi và chăm sóc cơ bản tại nhà.
  - 🟡 **Mức Vàng (YELLOW):** Dấu hiệu bất thường cần lưu ý (nôn 1-2 lần, tiêu chảy nhẹ, ho, nấm da...). Khuyến nghị đưa đi khám thú y trong vòng 24–48h.
  - 🔴 **Mức Đỏ (RED - CẤP CỨU):** Nguy hiểm đe dọa tính mạng (khó thở, thở há mồm, co giật, hôn mê, nôn/tiêu chảy ra máu...). Yêu cầu đưa đến trạm cấp cứu thú y **ngay lập tức** kèm hướng dẫn sơ cứu trên đường đi.

### 2. Trò chuyện giải đáp chuyên sâu (Hybrid Chat)
- Thẻ Triage Card ghim cố định ở đỉnh màn hình để người dùng luôn nắm rõ tình trạng và các bước sơ cứu cấp bách.
- Lịch sử hỏi đáp nối tiếp đồng bộ thời gian thực (Firestore Realtime Streams).
- **Phản ứng tức thì với tình huống nguy kịch:** Nếu người dùng thông báo triệu chứng chuyển biến xấu đột ngột, AI lập tức kích hoạt `🚨 [CẢNH BÁO MỨC ĐỘ ĐỎ]` ngay tại dòng đầu tiên của phản hồi.

### 3. Quản lý lịch sử ca bệnh (Checkup History)
- Quản lý toàn bộ các ca bệnh theo từng tài khoản.
- Lọc ca khám theo mức độ Triage (Tất cả, Xanh, Vàng, Đỏ) và trạng thái điều trị (Đang hoạt động, Theo dõi, Đã khỏi).

---

## 🛠 Kiến trúc công nghệ (Tech Stack)

### Frontend (Mobile App)
- **Framework:** [Flutter](https://flutter.dev/) (Dart 3.x), Material Design 3.
- **Quản lý kết nối Firebase:** `firebase_core`, `cloud_firestore`, `cloud_functions`.
- **Đa phương tiện & Xử lý ảnh:** `image_picker`, `flutter_image_compress`.
- **Định dạng thời gian:** `intl`.

### Backend & Cloud Infrastructure
- **Serverless Compute:** [Firebase Cloud Functions v2](https://firebase.google.com/docs/functions) (Node.js 22 LTS, TypeScript).
- **Trí tuệ nhân tạo (AI Engine):** [Google Gemini AI API](https://ai.google.dev/) (`@google/generative-ai`) với `gemini-1.5-flash` và cơ chế tự động chuyển vùng dự phòng (`gemini-3.5-flash`, `gemini-3.8-flash`).
- **Cơ sở dữ liệu:** [Cloud Firestore](https://firebase.google.com/docs/firestore) (NoSQL Database).
- **Bảo mật:** 
  - Firebase Secret Manager (`GEMINI_API_KEY`).
  - Firestore Security Rules phân quyền theo người dùng (`request.auth.uid`).

---

## 🗄 Cấu trúc cơ sở dữ liệu Firestore

```text
cloud.firestore
└── sessions/ (Collection các ca bệnh)
    └── {sessionId}/ (Document từng ca bệnh)
        ├── userId: string                    // UID người dùng
        ├── petType: "Chó" | "Mèo"            // Loài thú cưng
        ├── imageUrl: string                  // URL ảnh trên Firebase Storage
        ├── initialSymptoms: string           // Mô tả triệu chứng ban đầu
        ├── triageCard: map                   // Dữ liệu Thẻ Triage Card
        │   ├── urgencyLevel: "GREEN" | "YELLOW" | "RED"
        │   ├── summary: string               // Nhận định sơ bộ (2-3 câu)
        │   ├── possibleCauses: string[]      // Các nguyên nhân có thể
        │   ├── immediateActions: string[]    // Hướng dẫn xử lý ngay tại nhà
        │   └── vetQuestions: string[]        // Câu hỏi gợi ý cho bác sĩ thú y
        ├── createdAt: timestamp              // Thời điểm tạo ca bệnh
        ├── updatedAt: timestamp              // Thời điểm cập nhật tin nhắn cuối
        │
        └── messages/ (Sub-collection lưu lịch sử chat nối tiếp)
            └── {messageId}/
                ├── role: "user" | "model"    // Vai trò người gửi
                ├── text: string              // Nội dung tin nhắn
                └── createdAt: timestamp      // Thời gian gửi
```

---

## 📁 Cấu trúc thư mục dự án

```text
Zoomies/
├── android/                        # Cấu hình Android & google-services.json
├── functions/                      # Backend Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── gemini.ts               # Kết nối Gemini AI, Schema JSON & Fallback
│   │   ├── prompts.ts              # System Prompts (Prompt 1: Triage, Prompt 2: Chat)
│   │   ├── types.ts                # Khai báo TypeScript types & interfaces
│   │   └── index.ts                # 2 Callable Cloud Functions chính
│   ├── .secret.local               # Khóa API bí mật cục bộ (đã gitignore)
│   ├── package.json
│   └── tsconfig.json
├── lib/                            # Mã nguồn ứng dụng Flutter
│   ├── models/                     # Data models (SessionModel, ChatMessage, PetType, TriageLevel)
│   ├── screens/                    # Màn hình (NewCheckup, HybridTriageChat, History, HomeShell)
│   ├── services/                   # Logic nghiệp vụ (SessionService, ImageCompressionService)
│   ├── widgets/                    # Thành phần giao diện (TriageHeaderCard, ChatBubble, StepLoading)
│   ├── firebase_options.dart       # Cấu hình kết nối Firebase sinh bởi FlutterFire CLI
│   └── main.dart                   # Điểm khởi chạy ứng dụng (Khởi tạo Firebase)
├── firestore.rules                 # Quy tắc bảo mật Firestore
├── firestore.indexes.json          # Cấu hình Composite Index Firestore
├── firebase.json                   # Cấu hình dự án Firebase
└── README.md
```

---

## 🚀 Hướng dẫn cài đặt & Chạy ứng dụng

### Yêu cầu môi trường
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản `>= 3.13.5`)
- Thiết bị thật kết nối USB Debugging hoặc Android/iOS Emulator

### Các bước khởi chạy

1. **Clone repository về máy:**
   ```bash
   git clone https://github.com/tantrung0204/Zoomies.git
   cd Zoomies
   ```

2. **Chuyển sang nhánh tính năng:**
   ```bash
   git checkout feature/connect-firebase
   ```

3. **Cài đặt các gói phụ thuộc:**
   ```bash
   flutter pub get
   ```

4. **Kiểm tra trạng thái mã nguồn:**
   ```bash
   flutter analyze
   ```

5. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

> 💡 **Lưu ý:** Backend Cloud Functions đã được triển khai sẵn trên máy chủ Firebase (`zoomies-e296d`). Bạn có thể thử nghiệm tạo ca khám mới và trò chuyện với AI ngay mà không cần cấu hình thêm backend trên máy cá nhân.

---

## ⚙️ Hướng dẫn phát triển Backend (Cloud Functions)

Nếu bạn cần sửa đổi hoặc deploy lại Cloud Functions:

1. **Cài đặt dependencies cho thư mục `functions`:**
   ```bash
   cd functions
   npm install
   ```

2. **Biên dịch mã nguồn TypeScript:**
   ```bash
   npm run build
   ```

3. **Cấu hình GEMINI_API_KEY vào Firebase Secret Manager:**
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```

4. **Triển khai Functions & Firestore Rules:**
   ```bash
   firebase deploy --only functions,firestore
   ```

---

## ⚠️ Nguyên tắc An toàn & Miễn trừ y tế

> **LƯU Ý QUAN TRỌNG:**  
> Hệ thống Zoomies và AI Trợ lý Sơ cứu Thú cưng được xây dựng nhằm mục đích **sàng lọc sơ bộ ban đầu và cung cấp kiến thức chăm sóc hỗ trợ tại nhà**.  
> - AI **KHÔNG PHẢI** là bác sĩ thú y và **KHÔNG** đưa ra chẩn đoán y khoa xác định 100%.  
> - Hệ thống **TUYỆT ĐỐI KHÔNG KÊ ĐƠN THUỐC**, không cung cấp liều lượng thuốc đặc trị hay kháng sinh.  
> - Khi phát hiện các dấu hiệu khẩn cấp đe dọa tính mạng (khó thở, co giật, xuất huyết nặng...), hãy liên hệ ngay và đưa thú cưng đến **bệnh viện hoặc phòng khám thú y gần nhất**.

