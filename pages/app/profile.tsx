import { useState, useEffect, Dispatch } from 'react';
import { useAccount } from '@starknet-react/core';
import Blockies from 'react-blockies';
import styles from '../../styles/Profile.module.scss';
import NftCard from '../../components/nftCard';
import Listbox from '../../components/listbox';
import { getUserRents, getMetadata } from '../../utils/readBlockchainInfo';
import { IndexedRentContract } from '../../utils/starkrentInterfaces';

interface NftInfo {
  rentInfo: IndexedRentContract;
  metadata: any;
}

const categories = [
  { id: 1, name: 'Rented', unavailable: false },
  { id: 2, name: 'Owned', unavailable: false },
];

function getConnectWallet() {
  return <h1>connect wallet</h1>;
}

function getLoading() {
  return <h1>loading</h1>;
}

function getProfileContent(userAddress: string) {
  return <div className={styles.blockiesWrapper}>
    <Blockies seed={userAddress} className={styles.blockies} scale={15} />
    <h1>{'0x' + userAddress.slice(2, 6) + '...' + userAddress.slice(-4)}</h1>
  </div>
}

function getNftCards(nftInfoArray: NftInfo[], category: string) {
  let nftCards;
  if (category === "Rented") {
  nftCards = <div className={styles.collectionItemWrapper}> {nftInfoArray.map((element) => (
    <NftCard
      key={element.rentInfo.index}
      metadata={element.metadata}
      rentInfo={element.rentInfo}
      fullImage={false}
    />
  ))}</div>;
  } 

  return nftCards;
}

export default function Profile() {
  const { status: userStatus, address: userAddress } = useAccount();

  const [nftInfoArray, setNftInfoArray] = useState<NftInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedPerson, setSelectedPerson] = useState(categories[0]);

  function getMenu() {
    return <Listbox categories={categories} selectedPerson={selectedPerson} setSelectedPerson={setSelectedPerson} />
  }

  async function fetchAsync() {
    const nftInfoArray = await getUserRents(userAddress || '');
    const rentalAndMetadataArray: NftInfo[] = await Promise.all(
      nftInfoArray.map(async (element) => {
        const metadata = await getMetadata(
          element.offer.collection,
          element.offer.tokenId,
        );
        return { rentInfo: element, metadata };
      }),
    );
    setNftInfoArray(rentalAndMetadataArray);
    setIsLoading(false);
  }

  useEffect(() => {
    if (userStatus === 'connected') {
      fetchAsync();
    }
  }, [isLoading, userStatus]);

  return (
    <section className={styles.profile}>
      {userStatus == 'disconnected' && getConnectWallet()}
      {userAddress && [getProfileContent(userAddress), getMenu()]}
      {isLoading && userStatus == 'connected' && getLoading()}
      {!isLoading && userStatus == 'connected' && getNftCards(nftInfoArray, selectedPerson.name)}
    </section>
  );
}
