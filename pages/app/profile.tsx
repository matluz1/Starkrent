import { useState, useEffect } from 'react';
import { useAccount } from '@starknet-react/core';
import NftCard from '../../components/nftCard';
import { getUserRents, getMetadata } from '../../utils/readBlockchainInfo';
import { IndexedRentContract } from '../../utils/starkrentInterfaces';

interface NftInfo {
  rentInfo: IndexedRentContract;
  metadata: any;
}

export default function Profile() {
  const { status: userStatus, address: userAddress } = useAccount();

  const [nftInfoArray, setNftInfoArray] = useState<NftInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  async function fetchAsync() {
    const nftInfoArray = await getUserRents(userAddress || '');
    const rentalAndMetadataArray: NftInfo[] = await Promise.all(
      nftInfoArray.map(async (element) => {
        const metadata = await getMetadata(
          element.offer.collection,
          element.offer.tokenId,
        );
        return { rentInfo: element, metadata };
      }),
    );
    setNftInfoArray(rentalAndMetadataArray);
    setIsLoading(false);
  }

  useEffect(() => {
    if (userStatus === 'connected') {
      fetchAsync();
    }
  }, [isLoading, userStatus]);

  return (
    <>
      {isLoading && <h1>loading</h1>}
      {!isLoading &&
        nftInfoArray.map((element) => (
          <NftCard
            key={element.rentInfo.index}
            metadata={element.metadata}
            rentInfo={element.rentInfo}
            fullImage={false}
          />
        ))}
    </>
  );
}
