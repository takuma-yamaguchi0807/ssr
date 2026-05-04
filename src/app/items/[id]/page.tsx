import db from "@/lib/db";
import redis from "@/lib/redis";
import { notFound } from "next/navigation";

type Item = {
  id: number;
  name: string;
  description: string;
};

const CACHE_TTL = 60; // 60秒

export default async function ItemPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const cacheKey = `item:${id}`;

  const cached = await redis.get(cacheKey);
  if (cached) {
    const item = JSON.parse(cached) as Item;
    return <ItemDetail item={item} cached />;
  }

  const [rows] = await db.query("SELECT id, name, description FROM items WHERE id = ?", [id]);
  const items = rows as Item[];
  if (items.length === 0) notFound();

  const item = items[0];
  await redis.set(cacheKey, JSON.stringify(item), "EX", CACHE_TTL);

  return <ItemDetail item={item} cached={false} />;
}

function ItemDetail({ item, cached }: { item: Item; cached: boolean }) {
  return (
    <main>
      <h1>{item.name}</h1>
      <p>{item.description}</p>
      <p>キャッシュ: {cached ? "Redis（キャッシュ）" : "DB（初回取得）"}</p>
      <a href="/">← 一覧に戻る</a>
    </main>
  );
}
