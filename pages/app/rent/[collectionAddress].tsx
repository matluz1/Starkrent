import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import axios from 'axios';
import { useStarknetExecute } from '@starknet-react/core';
import collections from '../../../placeholder/collections.json';
import NftCard from '../../../components/nftCard';
import styles from '../../../styles/[collectionAddress].module.scss';
import Image from 'next/image';
import getMetadata from '../../../utils/getMetadata';

interface ContractRental {
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

interface NftInfo {
  tokenId: string;
  collateral: string;
  collateral_amount: number;
  interest_rate: number;
  rent_time_min: number;
  rent_time_max: number;
  metadata: any;
}

async function fetchContractData(): Promise<ContractRental[]> {
  const contractStruct = await axios.get(
    '/api/collection/rental/0x0783a9097b26eae0586373b2ce0ed3529ddc44069d1e0fbc4f66d42b69d6850d',
  );
  return contractStruct.data.contractRental;
}

function getExecuteMethod() {
  //run reset_counter method from https://github.com/starknet-edu/starknet-cairo-101/blob/main/contracts/ex03.cairo
  const calls = [
    {
      contractAddress:
        '0x79275e734d50d7122ef37bb939220a44d0b1ad5d8e92be9cdb043d85ec85e24',
      entrypoint: 'reset_counter',
      calldata: [],
    },
  ];

  return useStarknetExecute({ calls }).execute;
}

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;

  const fullImage = collections.find(
    (element) => element.address === collectionAddress,
  )?.info.fullImageItems;

  const [nftInfoArray, setNftInfoArray] = useState<NftInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function fetchAsync() {
      const rentPlaceholder = await fetchContractData();
      const collectionAddress =
        '0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b';
        //0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b - Old Starknet
        //0x0783a9097b26eae0586373b2ce0ed3529ddc44069d1e0fbc4f66d42b69d6850d - New Starknet - Doesn't have TokenURI view method
      const rentalAndMetadataArray = await Promise.all(
        rentPlaceholder.map(async (element) => {
          const metadata = await getMetadata(
            collectionAddress,
            element.tokenId,
          );
          return { ...element, metadata };
        }),
      );
      setNftInfoArray(rentalAndMetadataArray);
      setIsLoading(false);
    }
    fetchAsync();
  }, [isLoading]);

  const execute = getExecuteMethod();

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
            nftInfo={element}
            fullImage={fullImage}
            execute={execute}
          />
        ))}
    </div>
  );
}
