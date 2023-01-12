import { useEffect } from 'react';
import Image from 'next/image';
import { useRouter } from 'next/router';
import axios from 'axios';
import {
  useAccount,
  useContract,
  useStarknetCall,
  useStarknetExecute,
} from '@starknet-react/core';
import styles from '../../../styles/[collectionAddress].module.scss';
import collections from '../../../placeholder/collections.json';
import rentPlaceholder from '../../../placeholder/starkIdFolderStarknetBucketS3.json';
import starknetIdAbi from '../../../abi/starknetId.abi.json';
import starknet101Abi from '../../../abi/starknet101.abi.json';

async function fetchData() {
  const contractStruct = await axios.get(
    '/api/collection/rental/0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b',
  );
  console.log(contractStruct.data.contractRental);
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

function getTokenUri() {}

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;
  const ethIconSize = 15;

  const notFullImage = collections.find(
    (item) => item.address === collectionAddress,
  )?.info.notFullImageItems;

  useEffect(() => {
    
    fetchData();
  }, []);

  const execute = getExecuteMethod();

  //console.log tokenURI from id
  // const { contract } = useContract({
  //   address:
  //     '0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b',
  //   abi: starknetIdAbi,
  // });
  // const { address } = useAccount();
  // const { data, loading, error, refresh } = useStarknetCall({
  //   contract,
  //   method: 'name',
  //   args: [],
  //   options: {
  //     watch: false,
  //   },
  // });


  return (
    <>
      {/* {loading && <span>Loading...</span>}
      {error && <span>Error: {error}</span>}
      {error && <span>Data: {JSON.stringify(data)}</span>} */}
      <div className={styles.collectionItemWrapper}>
        {rentPlaceholder.map((item) => (
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
                  <span className={styles.nameValue}>{item.metadata.name}</span>
                </div>
                <div className={styles.collateral}>
                  <div className={styles.collateralValue}>
                    <span>15</span>
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
                    <span>0.01</span>
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
            <button className={styles.borrow} onClick={() => execute()}>
              <span>Borrow</span>
            </button>
            <div className={styles.dayMinMax}>
              <span>{}</span>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
