import React from 'react';
import Image from 'next/image';
import styles from '../styles/NftCard.module.scss';
import { useAccount } from '@starknet-react/core';
import { useConnectors } from '@starknet-react/core';
import {
  IndexedOfferContract,
  IndexedRentContract,
} from '../utils/starkrentInterfaces';
import { getRentExecute } from '../utils/writeBlockchainInfo';

interface Metadata {
  name: string;
  image: string;
  description: string;
}

interface Props {
  metadata: Metadata;
  offerInfo?: IndexedOfferContract;
  rentInfo?: IndexedRentContract;
  fullImage?: boolean;
}

const ethIconSize = 15;

function getOfferModal() {}
function getReturnExecute() {}

function getExecuteButton(
  execute: VoidFunction,
  offerInfo?: IndexedOfferContract,
  rentInfo?: IndexedRentContract,
) {
  let button = (
    <button className={styles.borrow} onClick={() => execute()}>
      <span>Offer for Rent</span>
    </button>
  );
  const { status } = useAccount();
  const { connectors, connect } = useConnectors();
  if (status === 'disconnected') {
    button = (
      <button className={styles.borrow} onClick={() => connect(connectors[1])}>
        <span>Connect Wallet</span>
      </button>
    );
  }
  if (status === 'connected' && offerInfo) {
    button = (
      <button className={styles.borrow} onClick={() => execute()}>
        <span>Borrow</span>
      </button>
    );
  }
  if (status === 'connected' && rentInfo) {
    button = (
      <button className={styles.borrow} onClick={() => execute()}>
        <span>Return</span>
      </button>
    );
  }
  return button;
}

function getFooter(
  offerInfo?: IndexedOfferContract,
  rentInfo?: IndexedRentContract,
) {
  let footerInfo = <span>owned by user</span>;
  if (offerInfo) {
    footerInfo = (
      <span>
        {offerInfo.rent_time_min} day min - {offerInfo.rent_time_max} day max
      </span>
    );
  }
  if (rentInfo) {
    footerInfo = (
      <span>{rentInfo.timestamp} days y minutes left to return nft</span>
    );
  }

  return <div className={styles.dayMinMax}>{footerInfo}</div>;
}

export default function NftCard({
  metadata,
  offerInfo,
  rentInfo,
  fullImage = true,
}: Props) {
  let execute = getOfferModal;
  if (offerInfo) {
    execute = getRentExecute({ ...offerInfo });
  }
  if (rentInfo) {
    execute = getReturnExecute;
  }

  let nftInfo: any;
  if (offerInfo) {
    nftInfo = offerInfo;
  }
  if (rentInfo) {
    nftInfo = offerInfo;
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
            src={metadata.image}
            alt={metadata.description}
            width={60}
            height={60}
            unoptimized //reason for the 'unoptimized': https://github.com/vercel/next.js/issues/42032
          />
        </div>
        <div className={styles.itemInfo}>
          <div className={styles.name}>
            <span className={styles.nameValue}>{metadata.name}</span>
          </div>
          {(offerInfo || rentInfo) && (
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
          )}
          {(offerInfo || rentInfo) && (
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
          )}
        </div>
      </button>
      {getExecuteButton(
        execute,
        offerInfo,
        rentInfo,
      )}
      {getFooter(offerInfo, rentInfo)}
    </div>
  );
}
