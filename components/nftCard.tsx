import React from 'react';
import Image from 'next/image';
import styles from '../styles/NftCard.module.scss';
import { useAccount } from '@starknet-react/core';
import { useConnectors } from '@starknet-react/core';
import { RentContract, getRentExecute } from '../utils/writeBlockchainInfo';

type AccountStatus = 'connected' | 'disconnected';

interface NftOffer extends RentContract {
  metadata: any;
}

interface Props {
  nftOffer: NftOffer;
  fullImage?: boolean;
  offered?: boolean;
  rented?: boolean;
}

const ethIconSize = 15;

export default function NftCard({
  nftOffer,
  fullImage = true,
  offered = false,
  rented = false,
}: Props) {
  const { status } = useAccount();
  const { connectors, connect } = useConnectors();
  const rentExecute = getRentExecute({ ...nftOffer });
  const returnExecute = {}; //add returnExecute

  function getExecuteButton(status: AccountStatus) {
    let button = (
      <button className={styles.borrow} onClick={() => connect(connectors[1])}>
        <span>Connect Wallet</span>
      </button>
    );
    if (status === 'connected' && (offered || rented)) {
      button = (
        <button className={styles.borrow} onClick={() => rentExecute()}>
          <span>Borrow</span>
        </button>
      );
    } else if (status === 'connected' && rented) {
      button = (
        <button
          className={styles.borrow}
          onClick={() => console.log('returnExecute')}
        >
          <span>Return</span>
        </button>
      );
    }
    return button;
  }

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
      {offered || rented ? getExecuteButton(status) : ''}
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
