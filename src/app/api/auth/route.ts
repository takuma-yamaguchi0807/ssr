import { NextRequest, NextResponse } from "next/server";
import { setSession, destroySession } from "@/lib/session";
import { cookies } from "next/headers";

export async function POST(req: NextRequest) {
  const formData = await req.formData();
  const action = formData.get("action");
  const userId = formData.get("userId") as string;

  if (action === "login") {
    const sessionId = await setSession({ userId });
    const cookieStore = await cookies();
    cookieStore.set("session_id", sessionId, { httpOnly: true, path: "/" });
    return NextResponse.redirect(new URL("/", req.url));
  }

  return NextResponse.json({ error: "invalid action" }, { status: 400 });
}

export async function GET(req: NextRequest) {
  const action = new URL(req.url).searchParams.get("action");

  if (action === "logout") {
    await destroySession();
    const cookieStore = await cookies();
    cookieStore.delete("session_id");
    return NextResponse.redirect(new URL("/", req.url));
  }

  return NextResponse.json({ error: "invalid action" }, { status: 400 });
}
