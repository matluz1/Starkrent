import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import collections from '../../../info/collections.json';
import NftCard from '../../../components/nftCard';
import styles from '../../../styles/[collectionAddress].module.scss';
import Image from 'next/image';
import {
  getMetadata,
  getContractOffers,
} from '../../../utils/readBlockchainInfo';

interface ContractOffer {
  index: number;
  owner: string;
  collection: string;
  tokenId: string;
  collateral: string;
  collateral_amount: number;
  interest_rate: number;
  rent_time_min: number;
  rent_time_max: number;
  timestamp: number;
}

export interface NftOffer extends ContractOffer {
  metadata: any;
}

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;

  const fullImage = collections.find(
    (element) => element.address === collectionAddress,
  )?.info.fullImageItems;

  const [nftInfoArray, setNftInfoArray] = useState<NftOffer[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const starknetIdAddress =
      '0x0783a9097b26eae0586373b2ce0ed3529ddc44069d1e0fbc4f66d42b69d6850d';
    async function fetchAsync() {
      const nftInfoArray = await getContractOffers(starknetIdAddress);
      const collectionAddress = starknetIdAddress;
      const rentalAndMetadataArray: NftOffer[] = await Promise.all(
        nftInfoArray.map(async (element) => {
          const metadata = await getMetadata(
            collectionAddress,
            element.tokenId,
          );
          return { ...element, metadata };
        }),
      );
      console.log(rentalAndMetadataArray);
      setNftInfoArray(rentalAndMetadataArray);
      setIsLoading(false);
    }
    fetchAsync();
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
            key={element.tokenId}
            nftOffer={element}
            fullImage={fullImage}
          />
        ))}
    </div>
  );
}
