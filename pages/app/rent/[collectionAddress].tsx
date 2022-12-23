import Image from 'next/image';
import { useRouter } from 'next/router';

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;
  return (
    <p>
      {collectionAddress}
      <Image
        src="https://starknet.id/api/identicons/626200613416"
        alt="Starkrent lion logo"
        width={60}
        height={60}
        unoptimized //reason for the 'unoptimized': https://github.com/vercel/next.js/issues/42032
      />
    </p>
  );
}
