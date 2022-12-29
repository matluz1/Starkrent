import Image from 'next/image';
import { useRouter } from 'next/router';
import styles from '../../../styles/[collectionAddress].module.scss';
import rentPlaceholder from '../../../components/placeholder/starknetidRentPlaceholder';
import collections from '../../../components/placeholder/collections';

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;

  const notFullImage = collections.find(
    (item) => item.address === collectionAddress,
  )?.info.notFullImageItems;

  return (
    <>
      <div className={styles.collectionItemWrapper}>
        {rentPlaceholder.map((item) => (
          <button className={styles.collectionItem} key={item.id}>
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
                    width={15}
                    height={15}
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
                    width={15}
                    height={15}
                  />
                </div>
                <span className={styles.dailyTaxLabel}>Daily Tax</span>
              </div>
            </div>
          </button>
        ))}
      </div>
    </>
  );
}
