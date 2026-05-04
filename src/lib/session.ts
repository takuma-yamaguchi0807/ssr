import { cookies } from "next/headers";
import { v4 as uuidv4 } from "uuid";
import redis from "./redis";

const SESSION_TTL = 60 * 60 * 24; // 24時間

export async function getSession(): Promise<Record<string, string> | null> {
  const cookieStore = await cookies();
  const sessionId = cookieStore.get("session_id")?.value;
  if (!sessionId) return null;

  const data = await redis.get(`session:${sessionId}`);
  if (!data) return null;

  return JSON.parse(data);
}

export async function setSession(data: Record<string, string>): Promise<string> {
  const sessionId = uuidv4();
  await redis.set(`session:${sessionId}`, JSON.stringify(data), "EX", SESSION_TTL);
  return sessionId;
}

export async function destroySession(): Promise<void> {
  const cookieStore = await cookies();
  const sessionId = cookieStore.get("session_id")?.value;
  if (sessionId) {
    await redis.del(`session:${sessionId}`);
  }
}
