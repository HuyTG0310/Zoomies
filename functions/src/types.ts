import { FieldValue, Timestamp } from "firebase-admin/firestore";

export type UrgencyLevel = "GREEN" | "YELLOW" | "RED";

export interface TriageCard {
  urgencyLevel: UrgencyLevel;
  summary: string;
  possibleCauses: string[];
  immediateActions: string[];
  vetQuestions: string[];
}

export interface SessionDocument {
  userId: string;
  petType: "Chó" | "Mèo" | string;
  imageUrl: string;
  initialSymptoms: string;
  triageCard: TriageCard;
  createdAt: Timestamp | FieldValue;
  updatedAt?: Timestamp | FieldValue;
}

export interface MessageDocument {
  role: "user" | "model";
  text: string;
  createdAt: Timestamp | FieldValue;
}

export interface AnalyzeInitialSymptomData {
  imageUrl?: string;
  imageBase64?: string;
  imageMimeType?: string;
  petType: "Chó" | "Mèo" | string;
  symptoms: string;
  userId?: string;
}

export interface AnalyzeInitialSymptomResult {
  sessionId: string;
  triageCard: TriageCard;
}

export interface SendChatMessageData {
  sessionId: string;
  userMessage: string;
}

export interface SendChatMessageResult {
  reply: string;
}

