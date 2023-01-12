import { useState, useEffect } from 'react';
import Image from 'next/image';
import { useRouter } from 'next/router';
import axios from 'axios';
import { Contract, Provider } from 'starknet';
import { useStarknetExecute } from '@starknet-react/core';
import styles from '../../../styles/[collectionAddress].module.scss';
import collections from '../../../placeholder/collections.json';
import _ from 'lodash';

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
  const ethIconSize = 15;

  const notFullImage = collections.find(
    (item) => item.address === collectionAddress,
  )?.info.notFullImageItems;

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
    <>
      <div className={styles.collectionItemWrapper}>
        {!isLoading &&
          nftInfoArray.map((item) => (
            <div className={styles.collectionItem} key={item.id}>
              <button className={styles.itemContent}>
                <div
                  className={
                    notFullImage
                      ? `${styles.itemImage} ${styles.notFullImage}`
                      : styles.itemImage
                  }
                >
                  <Image
                    src={item.metadata.image}
                    alt={item.metadata.description}
                    width={60}
                    height={60}
                    unoptimized //reason for the 'unoptimized': https://github.com/vercel/next.js/issues/42032
                  />
                </div>
                <div className={styles.itemInfo}>
                  <div className={styles.name}>
                    <span className={styles.nameValue}>
                      {item.metadata.name}
                    </span>
                  </div>
                  <div className={styles.collateral}>
                    <div className={styles.collateralValue}>
                      <span>{item.rentalInfo.collateralValue}</span>
                      <Image
                        src="/ethereum.svg"
                        alt="Ethereum logo"
                        width={ethIconSize}
                        height={ethIconSize}
                      />
                    </div>
                    <span className={styles.collateralLabel}>Collateral</span>
                  </div>
                  <div className={styles.dailyTax}>
                    <div className={styles.collateralValue}>
                      <span>{item.rentalInfo.dailyTax}</span>
                      <Image
                        src="/ethereum.svg"
                        alt="Ethereum logo"
                        width={ethIconSize}
                        height={ethIconSize}
                      />
                    </div>
                    <span className={styles.dailyTaxLabel}>Daily Tax</span>
                  </div>
                </div>
              </button>
              <button
                className={styles.borrow}
                onClick={() => execute()}
              >
                <span>Borrow</span>
              </button>
              <div className={styles.dayMinMax}>
                <span>{item.rentalInfo.minDays} day min - {item.rentalInfo.maxDays} day max</span>
              </div>
            </div>
          ))}
      </div>
    </>
  );
}
