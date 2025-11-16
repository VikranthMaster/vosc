import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config({ path: path.resolve("./supabase/.env.example") });

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);
