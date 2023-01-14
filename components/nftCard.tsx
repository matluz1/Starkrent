import React from 'react';
import Image from 'next/image';
import styles from '../styles/NftCard.module.scss';

interface NftInfo {
  tokenId: string;
  collateral: string;
  collateral_amount: number;
  interest_rate: number;
  rent_time_min: number;
  rent_time_max: number;
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
              <span>{nftInfo.collateral_amount}</span>
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
              <span>{nftInfo.interest_rate}</span>
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
          {nftInfo.rent_time_min} day min - {nftInfo.rent_time_max}
          day max
        </span>
      </div>
    </div>
  );
}
