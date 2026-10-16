import {
  GoogleGenerativeAI,
  SchemaType,
  Schema,
  Part,
  Content,
} from "@google/generative-ai";
import { SYSTEM_PROMPT_1_TRIAGE, SYSTEM_PROMPT_2_CHAT } from "./prompts";
import { TriageCard, UrgencyLevel } from "./types";

/**
 * Danh sách model ưu tiên:
 * 1. Model chỉ định trong biến môi trường GEMINI_MODEL hoặc mặc định gemini-1.5-flash theo yêu cầu
 * 2. Các model dự phòng thế hệ mới (gemini-3.5-flash-lite, gemini-3.5-flash, gemini-3.8-flash)
 *    nhằm đảm bảo không bị gián đoạn khi endpoint bị quá tải hoặc thay đổi phiên bản.
 */
function getCandidateModels(): string[] {
  const preferred = process.env.GEMINI_MODEL || "gemini-1.5-flash";
  const fallbacks = [
    preferred,
    "gemini-3.5-flash-lite",
    "gemini-3.5-flash",
    "gemini-3.8-flash",
  ];
  return Array.from(new Set(fallbacks.filter(Boolean)));
}

/**
 * Triage JSON Schema dùng cho responseSchema của Gemini
 */
const triageSchema: Schema = {
  type: SchemaType.OBJECT,
  properties: {
    urgencyLevel: {
      type: SchemaType.STRING,
      format: "enum",
      enum: ["GREEN", "YELLOW", "RED"],
      description: "Mức độ khẩn cấp: GREEN (nhẹ/tại nhà), YELLOW (cần khám sớm), RED (cấp cứu ngay)",
    },
    summary: {
      type: SchemaType.STRING,
      description: "Nhận định sơ bộ ngắn gọn bằng tiếng Việt (2-3 câu)",
    },
    possibleCauses: {
      type: SchemaType.ARRAY,
      items: { type: SchemaType.STRING },
      description: "Mảng các nguyên nhân có thể xảy ra",
    },
    immediateActions: {
      type: SchemaType.ARRAY,
      items: { type: SchemaType.STRING },
      description: "Mảng các bước xử lý ngay tại nhà",
    },
    vetQuestions: {
      type: SchemaType.ARRAY,
      items: { type: SchemaType.STRING },
      description: "Mảng câu hỏi gợi ý cho bác sĩ thú y",
    },
  },
  required: [
    "urgencyLevel",
    "summary",
    "possibleCauses",
    "immediateActions",
    "vetQuestions",
  ],
};

/**
 * Helper tải ảnh từ URL (Firebase Storage / HTTPS) thành Part inlineData
 */
export async function fetchImagePartFromUrl(url: string): Promise<Part | null> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      console.warn(`[Gemini] Không thể tải ảnh từ URL: ${url}, status: ${response.status}`);
      return null;
    }
    const contentType = response.headers.get("content-type") || "image/jpeg";
    const arrayBuffer = await response.arrayBuffer();
    const base64Data = Buffer.from(arrayBuffer).toString("base64");
    return {
      inlineData: {
        mimeType: contentType,
        data: base64Data,
      },
    };
  } catch (error) {
    console.error("[Gemini] Lỗi khi nạp ảnh từ URL:", error);
    return null;
  }
}

/**
 * Helper chuyển Base64 string thành Part inlineData
 */
export function parseBase64ImagePart(base64: string, mimeType = "image/jpeg"): Part {
  const cleanBase64 = base64.replace(/^data:image\/\w+;base64,/, "");
  return {
    inlineData: {
      mimeType,
      data: cleanBase64,
    },
  };
}

/**
 * Làm sạch JSON và parse an toàn
 */
function cleanAndParseJson<T>(rawText: string): T {
  let cleaned = rawText.trim();
  if (cleaned.startsWith("```json")) {
    cleaned = cleaned.replace(/^```json\s*/i, "").replace(/\s*```$/, "");
  } else if (cleaned.startsWith("```")) {
    cleaned = cleaned.replace(/^```\s*/, "").replace(/\s*```$/, "");
  }
  return JSON.parse(cleaned) as T;
}

/**
 * Chuẩn hóa TriageCard đảm bảo không bị lỗi dữ liệu
 */
export function sanitizeTriageCard(raw: any): TriageCard {
  const validUrgency: UrgencyLevel =
    raw?.urgencyLevel === "GREEN" ||
    raw?.urgencyLevel === "YELLOW" ||
    raw?.urgencyLevel === "RED"
      ? raw.urgencyLevel
      : "YELLOW";

  return {
    urgencyLevel: validUrgency,
    summary:
      typeof raw?.summary === "string" && raw.summary.trim().length > 0
        ? raw.summary.trim()
        : "Đã phân tích sơ bộ tình trạng thú cưng. Vui lòng theo dõi sát các biểu hiện của bé.",
    possibleCauses: Array.isArray(raw?.possibleCauses)
      ? raw.possibleCauses.filter((item: any) => typeof item === "string" && item.trim().length > 0)
      : [],
    immediateActions: Array.isArray(raw?.immediateActions)
      ? raw.immediateActions.filter((item: any) => typeof item === "string" && item.trim().length > 0)
      : [],
    vetQuestions: Array.isArray(raw?.vetQuestions)
      ? raw.vetQuestions.filter((item: any) => typeof item === "string" && item.trim().length > 0)
      : [],
  };
}

/**
 * Hàm phân tích triệu chứng ban đầu (Hàm 1: analyzeInitialSymptom)
 * Gọi Gemini với System Prompt số 1 và responseMimeType: "application/json"
 */
export async function analyzeInitialSymptomWithGemini(
  apiKey: string,
  petType: string,
  symptoms: string,
  imagePart?: Part | null
): Promise<TriageCard> {
  const genAI = new GoogleGenerativeAI(apiKey);
  const models = getCandidateModels();

  const promptText = `Hãy phân loại và phân tích tình trạng ca bệnh thú cưng sau:
- Loài thú cưng: ${petType || "Chó/Mèo"}
- Mô tả triệu chứng ban đầu của chủ nuôi: ${symptoms || "Không có mô tả chi tiết"}`;

  const parts: (string | Part)[] = [];
  if (imagePart) {
    parts.push(imagePart);
  }
  parts.push(promptText);

  let lastError: any = null;

  for (const modelName of models) {
    try {
      const model = genAI.getGenerativeModel({
        model: modelName,
        systemInstruction: SYSTEM_PROMPT_1_TRIAGE,
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: triageSchema,
          temperature: 0.2,
        },
      });

      const result = await model.generateContent(parts);
      const textResponse = result.response.text();

      if (!textResponse) {
        continue;
      }

      const rawJson = cleanAndParseJson<any>(textResponse);
      return sanitizeTriageCard(rawJson);
    } catch (error: any) {
      lastError = error;
      console.warn(`[Gemini Triage] Model ${modelName} gặp sự cố: ${error?.message || error}. Thử model tiếp theo...`);
    }
  }

  throw lastError || new Error("Không thể phân tích triệu chứng với các model Gemini hiện có.");
}

/**
 * Chuẩn bị lịch sử chat hợp lệ cho startChat của Gemini
 * - Bắt đầu bằng role: "user"
 * - Luân phiên user -> model -> user -> model
 * - Kết thúc bằng role: "model"
 */
export function buildGeminiHistory(
  petType: string,
  initialSymptoms: string,
  triageCard: TriageCard,
  firestoreMessages: Array<{ role: "user" | "model"; text: string }>
): Content[] {
  const history: Content[] = [];

  // Lượt mở đầu: Cung cấp bối cảnh ca bệnh cho AI
  const initialContextPrompt = `[BỐI CẢNH CA BỆNH THÚ CƯNG]
- Loài thú cưng: ${petType}
- Triệu chứng ban đầu: ${initialSymptoms}`;

  const initialTriageSummary = `[KẾT QUẢ PHÂN TÍCH TRIAGE CARD BAN ĐẦU]
- Mức độ khẩn cấp: ${triageCard.urgencyLevel}
- Nhận định sơ bộ: ${triageCard.summary}
- Các nguyên nhân có thể: ${triageCard.possibleCauses.join("; ") || "Chưa xác định rõ"}
- Hướng dẫn xử lý ngay tại nhà: ${triageCard.immediateActions.join("; ") || "Theo dõi sát sao"}
- Câu hỏi gợi ý cho bác sĩ: ${triageCard.vetQuestions.join("; ") || "Không có"}`;

  history.push({
    role: "user",
    parts: [{ text: initialContextPrompt }],
  });

  // Nếu trong Firestore messages đã có tin nhắn mở đầu của model, gộp vào lượt model đầu tiên
  let firstModelGreeting = "";
  let startIndex = 0;

  if (firestoreMessages.length > 0 && firestoreMessages[0].role === "model") {
    firstModelGreeting = `\n\n[LỜI CHÀO/TIN NHẮN MỞ ĐẦU]:\n${firestoreMessages[0].text}`;
    startIndex = 1; // Đã gộp tin nhắn đầu
  }

  history.push({
    role: "model",
    parts: [{ text: `${initialTriageSummary}${firstModelGreeting}` }],
  });

  // Đưa các tin nhắn tiếp theo vào history, đảm bảo luân phiên đúng quy cách
  for (let i = startIndex; i < firestoreMessages.length; i++) {
    const msg = firestoreMessages[i];
    const role: "user" | "model" = msg.role === "user" ? "user" : "model";
    const text = msg.text?.trim() || "";
    if (!text) continue;

    const last = history[history.length - 1];
    if (last && last.role === role) {
      last.parts.push({ text: `\n${text}` });
    } else {
      history.push({
        role,
        parts: [{ text }],
      });
    }
  }

  // Đảm bảo history kết thúc bằng role "model" để lượt gửi tiếp theo của user hợp lệ
  if (history.length > 0 && history[history.length - 1].role === "user") {
    history.push({
      role: "model",
      parts: [{ text: "Tôi đã hiểu thông tin. Bạn cần trao đổi thêm điều gì?" }],
    });
  }

  return history;
}

/**
 * Gửi tin nhắn chat tới Gemini với System Prompt số 2 và lịch sử đầy đủ
 */
export async function sendChatMessageWithGemini(
  apiKey: string,
  history: Content[],
  userMessage: string
): Promise<string> {
  const genAI = new GoogleGenerativeAI(apiKey);
  const models = getCandidateModels();

  let lastError: any = null;

  for (const modelName of models) {
    try {
      const model = genAI.getGenerativeModel({
        model: modelName,
        systemInstruction: SYSTEM_PROMPT_2_CHAT,
        generationConfig: {
          temperature: 0.4,
        },
      });

      // Sao chép deep copy lịch sử để không ảnh hưởng nếu thử lại model tiếp theo
      const historyCopy: Content[] = JSON.parse(JSON.stringify(history));
      const chatSession = model.startChat({ history: historyCopy });

      const result = await chatSession.sendMessage(userMessage);
      const replyText = result.response.text();

      if (replyText && replyText.trim().length > 0) {
        return replyText.trim();
      }
    } catch (error: any) {
      lastError = error;
      console.warn(`[Gemini Chat] Model ${modelName} gặp sự cố: ${error?.message || error}. Thử model tiếp theo...`);
    }
  }

  throw lastError || new Error("Không thể xử lý tin nhắn chat từ Gemini.");
}

