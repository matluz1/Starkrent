import React from 'react';
import Image from 'next/image';
import styles from '../styles/NftCard.module.scss';

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

interface Props {
  nftInfo: NftInfo;
  notFullImage: boolean;
  execute: Function;
}

const ethIconSize = 15;

export default function NftCard({
  nftInfo,
  notFullImage = true,
  execute,
}: Props) {
  return (
    <div className={styles.collectionItem}>
      <button className={styles.itemContent}>
        <div
          className={
            notFullImage
              ? `${styles.itemImage} ${styles.notFullImage}`
              : styles.itemImage
          }
        >
          <Image
            src={nftInfo.metadata.image}
            alt={nftInfo.metadata.description}
            width={60}
            height={60}
            unoptimized //reason for the 'unoptimized': https://github.com/vercel/next.js/issues/42032
          />
        </div>
        <div className={styles.itemInfo}>
          <div className={styles.name}>
            <span className={styles.nameValue}>{nftInfo.metadata.name}</span>
          </div>
          <div className={styles.collateral}>
            <div className={styles.collateralValue}>
              <span>{nftInfo.rentalInfo.collateralValue}</span>
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
              <span>{nftInfo.rentalInfo.dailyTax}</span>
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
        <span>
          {nftInfo.rentalInfo.minDays} day min - {nftInfo.rentalInfo.maxDays}
          day max
        </span>
      </div>
    </div>
  );
}
