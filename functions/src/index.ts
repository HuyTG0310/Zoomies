import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import {
  AnalyzeInitialSymptomData,
  AnalyzeInitialSymptomResult,
  SendChatMessageData,
  SendChatMessageResult,
  SessionDocument,
} from "./types";
import {
  analyzeInitialSymptomWithGemini,
  buildGeminiHistory,
  sendChatMessageWithGemini,
  fetchImagePartFromUrl,
  parseBase64ImagePart,
} from "./gemini";

// Khởi tạo Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Định nghĩa Secret cho GEMINI_API_KEY
const geminiApiKeySecret = defineSecret("GEMINI_API_KEY");

/**
 * Lấy API key từ Secret Manager hoặc biến môi trường fallback
 */
function resolveGeminiApiKey(): string {
  const secretVal = geminiApiKeySecret.value();
  if (secretVal && secretVal.trim().length > 0) {
    return secretVal.trim();
  }
  const envVal = process.env.GEMINI_API_KEY;
  if (envVal && envVal.trim().length > 0) {
    return envVal.trim();
  }
  throw new HttpsError(
    "failed-precondition",
    "GEMINI_API_KEY chưa được cấu hình. Vui lòng thiết lập Firebase Secret hoặc biến môi trường."
  );
}

/**
 * =========================================================================
 * HÀM 1: analyzeInitialSymptom (Xử lý lượt đầu tiên - Triage)
 * =========================================================================
 * - Input từ Flutter: imageUrl (hoặc chuỗi ảnh Base64), petType, symptoms.
 * - Xử lý:
 *   + Gọi gemini-1.5-flash kèm System Prompt số 1 và responseMimeType: "application/json".
 *   + Tự động tạo document mới trong collection 'sessions'.
 *   + Lưu luôn tin nhắn mở đầu vào sub-collection 'messages'.
 * - Output: { sessionId, triageCard }
 */
export const analyzeInitialSymptom = onCall(
  {
    secrets: [geminiApiKeySecret],
    timeoutSeconds: 60,
    memory: "512MiB",
    cors: true,
  },
  async (request): Promise<AnalyzeInitialSymptomResult> => {
    const data = request.data as AnalyzeInitialSymptomData;
    const apiKey = resolveGeminiApiKey();

    const petType = data?.petType?.trim() || "Chó/Mèo";
    const symptoms = data?.symptoms?.trim() || "";
    const imageUrl = data?.imageUrl?.trim() || "";
    const imageBase64 = data?.imageBase64?.trim() || "";
    const imageMimeType = data?.imageMimeType || "image/jpeg";
    const userId = request.auth?.uid || data?.userId || "anonymous";

    if (!symptoms) {
      throw new HttpsError(
        "invalid-argument",
        "Vui lòng cung cấp mô tả triệu chứng ban đầu của thú cưng."
      );
    }

    // 1. Chuẩn bị ảnh (nếu có: Base64 hoặc từ Storage URL)
    let imagePart = null;
    if (imageBase64) {
      imagePart = parseBase64ImagePart(imageBase64, imageMimeType);
    } else if (imageUrl) {
      imagePart = await fetchImagePartFromUrl(imageUrl);
    }

    // 2. Gọi Gemini để phân tích Triage Card
    let triageCard;
    try {
      triageCard = await analyzeInitialSymptomWithGemini(
        apiKey,
        petType,
        symptoms,
        imagePart
      );
    } catch (error: any) {
      console.error("[analyzeInitialSymptom] Lỗi Gemini:", error);
      throw new HttpsError(
        "internal",
        `Không thể phân tích triệu chứng bằng Gemini: ${error?.message || error}`
      );
    }

    // 3. Tạo document mới trong collection 'sessions'
    const sessionRef = db.collection("sessions").doc();
    const sessionId = sessionRef.id;

    const sessionDocData: SessionDocument = {
      userId,
      petType,
      imageUrl,
      initialSymptoms: symptoms,
      triageCard,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await sessionRef.set(sessionDocData);

    // 4. Lưu tin nhắn mở đầu vào sub-collection 'sessions/{sessionId}/messages'
    const openingGreeting =
      `Xin chào! Tôi là Trợ lý Sức khỏe Thú cưng Zoomies.\n` +
      `Tôi đã tạo Thẻ đánh giá sơ bộ (Triage Card) ở phía trên dựa trên thông tin bạn cung cấp (Mức độ: ${triageCard.urgencyLevel}).\n\n` +
      `📌 **Tóm tắt nhanh:** ${triageCard.summary}\n\n` +
      `Bạn có thể đặt câu hỏi bên dưới hoặc cung cấp thêm diễn biến của bé để tôi hỗ trợ thêm nhé!`;

    await sessionRef.collection("messages").add({
      role: "model",
      text: openingGreeting,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      sessionId,
      triageCard,
    };
  }
);

/**
 * =========================================================================
 * HÀM 2: sendChatMessage (Xử lý các lượt hỏi đáp tiếp theo)
 * =========================================================================
 * - Input từ Flutter: sessionId, userMessage.
 * - Xử lý:
 *   + Đọc thông tin triageCard và toàn bộ lịch sử trong sessions/{sessionId}/messages.
 *   + Khởi tạo model.startChat({ history: ... }) với System Prompt số 2.
 *   + Gửi userMessage tới Gemini, nhận phản hồi.
 *   + Lưu cả câu hỏi của user và câu trả lời của AI vào sub-collection messages.
 * - Output: { reply }
 */
export const sendChatMessage = onCall(
  {
    secrets: [geminiApiKeySecret],
    timeoutSeconds: 60,
    memory: "512MiB",
    cors: true,
  },
  async (request): Promise<SendChatMessageResult> => {
    const data = request.data as SendChatMessageData;
    const apiKey = resolveGeminiApiKey();

    const sessionId = data?.sessionId?.trim();
    const userMessage = data?.userMessage?.trim();

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "Thiếu sessionId của ca bệnh.");
    }
    if (!userMessage) {
      throw new HttpsError("invalid-argument", "Nội dung câu hỏi không được để trống.");
    }

    // 1. Đọc thông tin ca bệnh từ Firestore
    const sessionDocRef = db.collection("sessions").doc(sessionId);
    const sessionSnapshot = await sessionDocRef.get();

    if (!sessionSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        `Không tìm thấy ca bệnh tương ứng với sessionId: ${sessionId}`
      );
    }

    const sessionData = sessionSnapshot.data() as SessionDocument;

    // 2. Đọc toàn bộ lịch sử chat trong sessions/{sessionId}/messages sắp xếp theo thời gian
    const messagesSnapshot = await sessionDocRef
      .collection("messages")
      .orderBy("createdAt", "asc")
      .get();

    const messagesHistory = messagesSnapshot.docs.map((doc) => {
      const docData = doc.data();
      return {
        role: (docData.role === "user" ? "user" : "model") as "user" | "model",
        text: docData.text || "",
      };
    });

    // 3. Khởi tạo lịch sử Gemini với System Prompt số 2
    const history = buildGeminiHistory(
      sessionData.petType,
      sessionData.initialSymptoms,
      sessionData.triageCard,
      messagesHistory
    );

    // 4. Gửi userMessage tới Gemini và nhận câu trả lời
    let aiReply = "";
    try {
      aiReply = await sendChatMessageWithGemini(apiKey, history, userMessage);
    } catch (error: any) {
      console.error("[sendChatMessage] Lỗi khi gọi Gemini chat:", error);
      throw new HttpsError(
        "internal",
        `Lỗi khi xử lý phản hồi từ Gemini: ${error?.message || error}`
      );
    }

    if (!aiReply) {
      aiReply = "Tôi đã ghi nhận thông tin. Vui lòng đưa bé đến cơ sở thú y gần nhất nếu thấy có triệu chứng bất thường kéo dài.";
    }

    // 5. Lưu cả câu hỏi của user và câu trả lời của AI vào sub-collection messages
    const messagesCollection = sessionDocRef.collection("messages");
    const batch = db.batch();

    const userMessageRef = messagesCollection.doc();
    batch.set(userMessageRef, {
      role: "user",
      text: userMessage,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const aiMessageRef = messagesCollection.doc();
    batch.set(aiMessageRef, {
      role: "model",
      text: aiReply,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Cập nhật lại thời gian cập nhật của session
    batch.update(sessionDocRef, {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return {
      reply: aiReply,
    };
  }
);

