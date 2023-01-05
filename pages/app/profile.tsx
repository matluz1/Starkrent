import { useRouter } from 'next/router';

export default function Profile() {
  const router = useRouter();

  return (
    <div>
      <h1>My Next.js Component</h1>
      <p>You are currently on: {router.pathname}</p>
    </div>
  );
}
