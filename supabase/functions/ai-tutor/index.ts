// Gemini proxy for the Dawnlit app. Keeps the Gemini key on the server and
// only answers requests carrying a valid Firebase ID token for this project.
//
// Deploy:
//   supabase secrets set GEMINI_API_KEY=... FIREBASE_PROJECT_ID=arunachal-exam-app
//   supabase functions deploy ai-tutor --no-verify-jwt
// (--no-verify-jwt because callers are verified by their Firebase token below,
//  not by a Supabase session.)

import { createRemoteJWKSet, jwtVerify } from "https://deno.land/x/jose@v5.2.0/index.ts";

const PROJECT = Deno.env.get("FIREBASE_PROJECT_ID") ?? "arunachal-exam-app";
const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const ALLOWED_MODELS = new Set(["gemini-3.6-flash"]);
const MAX_BODY_BYTES = 2_000_000; // one compressed photo plus a short chat

const jwks = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"),
);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-firebase-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "method not allowed" });
  if (!GEMINI_KEY) return json(500, { error: "server not configured" });

  const token = req.headers.get("x-firebase-token") ?? "";
  try {
    await jwtVerify(token, jwks, {
      issuer: `https://securetoken.google.com/${PROJECT}`,
      audience: PROJECT,
    });
  } catch {
    return json(401, { error: "sign in required" });
  }

  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) return json(413, { error: "request too large" });

  let model: string, request: unknown;
  try {
    ({ model, request } = JSON.parse(raw));
  } catch {
    return json(400, { error: "bad json" });
  }
  if (!ALLOWED_MODELS.has(model)) return json(400, { error: "model not allowed" });

  const upstream = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": GEMINI_KEY },
      body: JSON.stringify(request),
    },
  );
  return new Response(await upstream.text(), {
    status: upstream.status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
