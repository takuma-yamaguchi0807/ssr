import db from "@/lib/db";
import { getSession } from "@/lib/session";
import TaskBadge from "@/components/TaskBadge";
import Link from "next/link";

export default async function HomePage() {
  const session = await getSession();
  const items = await db.item.findMany();

  return (
    <main>
      <TaskBadge />
      <h1>アイテム一覧</h1>
      {session ? (
        <p>ログイン中: {session.userId} ｜ <a href="/api/auth?action=logout">ログアウト</a></p>
      ) : (
        <form action="/api/auth" method="POST">
          <input type="hidden" name="action" value="login" />
          <input type="text" name="userId" placeholder="ユーザーID" required />
          <button type="submit">ログイン</button>
        </form>
      )}
      <ul>
        {items.map((item) => (
          <li key={item.id}>
            <Link href={`/items/${item.id}`}>{item.name}</Link>
            <p>{item.description}</p>
          </li>
        ))}
      </ul>
    </main>
  );
}
