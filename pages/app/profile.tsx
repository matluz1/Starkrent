import { useState, useEffect } from 'react';
import { useAccount } from '@starknet-react/core';
import Blockies from 'react-blockies';
import styles from '../../styles/Profile.module.scss';
import NftCard from '../../components/nftCard';
import { getUserRents, getMetadata } from '../../utils/readBlockchainInfo';
import { IndexedRentContract } from '../../utils/starkrentInterfaces';
import { Listbox } from '@headlessui/react';

interface NftInfo {
  rentInfo: IndexedRentContract;
  metadata: any;
}

const category = [
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

function getNftCards(nftInfoArray: NftInfo[]) {
  return <div className={styles.collectionItemWrapper}> {nftInfoArray.map((element) => (
    <NftCard
      key={element.rentInfo.index}
      metadata={element.metadata}
      rentInfo={element.rentInfo}
      fullImage={false}
    />
  ))}</div>;
}

function MyListbox() {
  const [selectedPerson, setSelectedPerson] = useState(category[0])

  return (
    <Listbox value={selectedPerson} onChange={setSelectedPerson}>
      <div className={styles.listboxWrapper}>
        <Listbox.Button className={styles.listboxButton}>{selectedPerson.name}</Listbox.Button>
        <Listbox.Options className={styles.listboxOptions}>
          {category.map((category) => (
            <Listbox.Option
              key={category.id}
              value={category}
              disabled={category.unavailable}
            >
              {category.name}
            </Listbox.Option>
          ))}
        </Listbox.Options>
      </div>
    </Listbox>
  )
}

export default function Profile() {
  const { status: userStatus, address: userAddress } = useAccount();

  const [nftInfoArray, setNftInfoArray] = useState<NftInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);

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
      {userAddress && getProfileContent(userAddress)}
      {isLoading && userStatus == 'connected' && getLoading()}
      {!isLoading && userStatus == 'connected' && getNftCards(nftInfoArray)}
      <MyListbox />
    </section>
  );
}
