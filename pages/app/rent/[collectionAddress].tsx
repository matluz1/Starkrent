import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { ParsedUrlQuery } from 'querystring';
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

function processRouterQuery(query: ParsedUrlQuery, routeName: string) {
  const { [routeName]: routeQuery } = query;
  let processedRouterQuery = '';
  if (typeof routeQuery == 'string') {
    processedRouterQuery = routeQuery;
  }
  return processedRouterQuery;
}

export default function Page() {
  const router = useRouter();
  const collectionAddress = processRouterQuery(router.query, 'collectionAddress');

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
    if (collectionAddress) {
      fetchAsync(collectionAddress);
    }
  }, [isLoading, collectionAddress]);

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
