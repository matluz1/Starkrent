import Image from 'next/image';
import { useRouter } from 'next/router';
import styles from '../../../styles/[collectionAddress].module.scss';
import rentPlaceholder from '../../../components/placeholder/starknetidRentPlaceholder';

export default function Page() {
  const router = useRouter();
  const { collectionAddress } = router.query;

  return (
    <>
      {/* {collectionAddress} */}
      <div className={styles.collectionItemWrapper}>
        {rentPlaceholder.map((item) => (
          <div className={styles.collectionItem}>
            <div className={styles.itemImage}>
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
                <span className={styles.nameValue}>
                  {item.info.name}
                </span>
              </div>
              <div className={styles.collateral}>
                <span className={styles.collateralValue}>0.01</span>
                <span className={styles.collateralLabel}>Collateral</span>
              </div>
              <div className={styles.dailyTax}>
                <span className={styles.dailyTaxValue}>0.01</span>
                <span className={styles.dailyTaxLabel}>Daily Tax</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
