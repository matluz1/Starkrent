import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import axios from 'axios';
import { Contract, Provider } from 'starknet';
import { useStarknetExecute } from '@starknet-react/core';
import collections from '../../../placeholder/collections.json';
import NftCard from '../../../components/nftCard';
import styles from '../../../styles/[collectionAddress].module.scss';
import Image from 'next/image';

interface ContractRental {
  id: string;
  rentalInfo: {
    collateralValue: number;
    collateralToken: string;
    dailyTax: number;
    minDays: number;
    maxDays: number;
  };
}

interface NftInfo {
  id: string;
  rentalInfo: {
    collateralValue: number;
    collateralToken: string;
    dailyTax: number;
    minDays: number;
    maxDays: number;
  };
  metadata: any;
}

async function fetchData(): Promise<ContractRental[]> {
  const contractStruct = await axios.get(
    '/api/collection/rental/0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b',
  );
  return contractStruct.data.contractRental;
}

function tokenUriCleaner(tokenUri: any) {
  const tokenUriCleaned = tokenUri?.map((element: any) => element.words[0]);
  const tokenUriAddress = tokenUriCleaned.map((element: number) =>
    String.fromCharCode(element),
  );
  return tokenUriAddress.join('');
}

async function getMetadata(collectionAddress: string, tokenId: string) {
  const provider = new Provider({ sequencer: { network: 'goerli-alpha' } });
  const { abi } = await provider.getClassAt(collectionAddress);
  if (abi === undefined) {
    throw new Error('no abi.');
  }

  const contract = new Contract(abi, collectionAddress, provider);

  const response = await contract.call('tokenURI', [[tokenId, '0']]);
  const tokenUriAddress = tokenUriCleaner(response.tokenURI);
  const metadata = await axios.get(tokenUriAddress);
  return metadata.data;
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

  const notFullImage =
    collections.find((item) => item.address === collectionAddress)?.info
      .notFullImageItems || true;

  const [nftInfoArray, setNftInfoArray] = useState<NftInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function fetchAsync() {
      const rentPlaceholder = await fetchData();
      const collectionAddress =
        '0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b';
      const rentalAndMetadataArray = await Promise.all(
        rentPlaceholder.map(async (element) => {
          const metadata = await getMetadata(collectionAddress, element.id);
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
            key={element.id}
            nftInfo={element}
            notFullImage={notFullImage}
            execute={execute}
          />
        ))}
    </div>
  );
}
