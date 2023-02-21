import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import collections from '../../../info/collections.json';
import NftCard from '../../../components/nftCard';
import styles from '../../../styles/[collectionAddress].module.scss';
import Image from 'next/image';
import { IndexedOfferContract } from '../../../utils/starkrentInterfaces';
import {
  getMetadata,
  getCollectionOffers,
} from '../../../utils/readBlockchainInfo';

interface NftInfo {
  offerInfo: IndexedOfferContract;
  metadata: any;
}

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;

  const [nftInfoArray, setNftInfoArray] = useState<NftInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const fullImage = collections.find(
    (element) => element.address === collectionAddress,
  )?.info.fullImageItems;

  async function fetchAsync(collectionAddress: string) {
    const nftInfoArray = await getCollectionOffers(collectionAddress);
    const rentalAndMetadataArray: NftInfo[] = await Promise.all(
      nftInfoArray.map(async (element) => {
        const metadata = await getMetadata(
          collectionAddress,
          element.tokenId,
        );
        return { offerInfo: element, metadata };
      }),
    );
    setNftInfoArray(rentalAndMetadataArray);
    setIsLoading(false);
  }

  useEffect(() => {
    const starknetIdAddress =
      '0x783a9097b26eae0586373b2ce0ed3529ddc44069d1e0fbc4f66d42b69d6850d';
    fetchAsync(starknetIdAddress);
  }, [isLoading]);

  return (
    <div className={styles.collectionItemWrapper}>
      {isLoading && (
        <Image
          className={styles.spinner}
          src="/spinner.svg"
          alt="spinner"
          width={30}
          height={30}
        />
      )}

      {!isLoading &&
        nftInfoArray.map((element) => (
          <NftCard
            key={element.offerInfo.index}
            metadata={element.metadata}
            offerInfo={element.offerInfo}
            fullImage={fullImage}
          />
        ))}
    </div>
  );
}
