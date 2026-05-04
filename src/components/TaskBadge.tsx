export default function TaskBadge() {
  const hostname = process.env.HOSTNAME ?? "local";
  return (
    <p style={{ fontSize: "0.75rem", color: "#888" }}>
      ECS Task: {hostname}
    </p>
  );
}
