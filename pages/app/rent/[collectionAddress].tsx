import Image from 'next/image';
import { useRouter } from 'next/router';
import { useStarknetExecute } from '@starknet-react/core';
import styles from '../../../styles/[collectionAddress].module.scss';
import rentPlaceholder from '../../../placeholder/starknetidRentPlaceholder.json';
import collections from '../../../placeholder/collections.json';

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;
  const ethIconSize = 15;

  const notFullImage = collections.find(
    (item) => item.address === collectionAddress,
  )?.info.notFullImageItems;


  //run reset_counter method from https://github.com/starknet-edu/starknet-cairo-101/blob/main/contracts/ex03.cairo
  const calls = [{
    contractAddress: '0x79275e734d50d7122ef37bb939220a44d0b1ad5d8e92be9cdb043d85ec85e24',
    entrypoint: 'reset_counter',
    calldata: [],
  }]

  const { execute } = useStarknetExecute({ calls })

  return (
    <>
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
                  src={item.info.image}
                  alt={item.info.description}
                  width={60}
                  height={60}
                  unoptimized //reason for the 'unoptimized': https://github.com/vercel/next.js/issues/42032
                />
              </div>
              <div className={styles.itemInfo}>
                <div className={styles.name}>
                  <span className={styles.nameValue}>{item.info.name}</span>
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
              <span>day min - days max</span>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
