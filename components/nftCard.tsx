import React from 'react';
import Image from 'next/image';
import styles from '../styles/NftCard.module.scss';
import { useAccount } from '@starknet-react/core';
import { useConnectors } from '@starknet-react/core';

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
  fullImage?: boolean;
  execute: Function;
}

const ethIconSize = 15;

export default function NftCard({ nftInfo, fullImage = true, execute }: Props) {
  const { status } = useAccount();
  const { connectors, connect } = useConnectors();

  return (
    <div className={styles.collectionItem}>
      <button className={styles.itemContent}>
        <div
          className={
            fullImage
              ? styles.itemImage
              : `${styles.itemImage} ${styles.notFullImage}`
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
      {status === 'disconnected' ? (
        <button className={styles.borrow} onClick={() => connect(connectors[1])}>
          <span>Connect Wallet</span>
        </button>
      ) : (
        <button className={styles.borrow} onClick={() => execute()}>
          <span>Borrow</span>
        </button>
      )}

      <div className={styles.dayMinMax}>
        <span>
          {nftInfo.rent_time_min} day min - {nftInfo.rent_time_max}
          &nbsp;day max
          {/* prettier keeps removing the necessary non-breaking space */}
        </span>
      </div>
    </div>
  );
}
