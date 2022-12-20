import { useRouter } from 'next/router'

export default function Page() {
  const router = useRouter()
  const { collectionAddress } = router.query
  return <p>{collectionAddress}</p>
}
