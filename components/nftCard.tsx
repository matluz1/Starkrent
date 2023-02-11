import React from 'react';
import Image from 'next/image';
import styles from '../styles/NftCard.module.scss';
import { useAccount } from '@starknet-react/core';
import { useConnectors } from '@starknet-react/core';
import { getRentExecute } from '../utils/writeBlockchainInfo';

interface ContractOffer {
  index: number;
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

interface NftOffer extends ContractOffer {
  metadata: any;
}

interface Props {
  nftOffer: NftOffer;
  fullImage?: boolean;
}

const ethIconSize = 15;

export default function NftCard({ nftOffer, fullImage = true }: Props) {
  const { status } = useAccount();
  const { connectors, connect } = useConnectors();
  const execute = getRentExecute({ ...nftOffer });

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
            src={nftOffer.metadata.image}
            alt={nftOffer.metadata.description}
            width={60}
            height={60}
            unoptimized //reason for the 'unoptimized': https://github.com/vercel/next.js/issues/42032
          />
        </div>
        <div className={styles.itemInfo}>
          <div className={styles.name}>
            <span className={styles.nameValue}>{nftOffer.metadata.name}</span>
          </div>
          <div className={styles.collateral}>
            <div className={styles.collateralValue}>
              <span>{nftOffer.collateral_amount}</span>
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
              <span>{nftOffer.interest_rate}</span>
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
        <button
          className={styles.borrow}
          onClick={() => connect(connectors[1])}
        >
          <span>Connect Wallet</span>
        </button>
      ) : (
        <button className={styles.borrow} onClick={() => execute()}>
          <span>Borrow</span>
        </button>
      )}

      <div className={styles.dayMinMax}>
        <span>
          {nftOffer.rent_time_min} day min - {nftOffer.rent_time_max}
          &nbsp;day max
          {/* prettier keeps removing the necessary non-breaking space */}
        </span>
      </div>
    </div>
  );
}
