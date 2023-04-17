import { useState, useEffect, Dispatch } from 'react';
import { useAccount } from '@starknet-react/core';
import Blockies from 'react-blockies';
import styles from '../../styles/Profile.module.scss';
import NftCard from '../../components/nftCard';
import Listbox from '../../components/listbox';
import { getUserRents, getMetadata } from '../../utils/readBlockchainInfo';
import { Metadata, IndexedRentContract } from '../../utils/starkrentInterfaces';
import { getUserAssetsFromCollection } from '../../utils/readBlockchainInfo';

interface NftInfo {
  rentInfo: IndexedRentContract;
  metadata: any;
}

interface OwnedNft {
  owner: string;
  collection: string;
  tokenId: string;
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

export default function Profile() {
  const { status: userStatus, address: userAddress } = useAccount();

  const [nftInfoArray, setNftInfoArray] = useState<NftInfo[]>([]);
  const [ownedNftArray, setOwnedNftArray] = useState<OwnedNft[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState(categories[0]);

  function getMenu() {
    return <Listbox categories={categories} selectedCategory={selectedCategory} setSelectedCategory={setSelectedCategory} />
  }

  function getNftCards(category: string) {
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
    if (category === "Owned") {
      nftCards = <div className={styles.collectionItemWrapper}> {ownedNftArray.map((element) => (
        <NftCard
          key={element.tokenId}
          metadata={element.metadata}
          fullImage={false}
        />
      ))}</div>;
      }
  
    return nftCards;
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
    const collection = "0x0783a9097b26eae0586373b2ce0ed3529ddc44069d1e0fbc4f66d42b69d6850d"; //starkid
    const userAssets = await getUserAssetsFromCollection(collection, userAddress || '');
    const ownedNfts = userAssets.assets.map((element: any) => {
      const metadata: Metadata = {
        name: element.name,
        image: element.image_small_url_copy,
        description: element.description,
        attributes: element.attributes
      }
      return { 
        owner: element.owner.accountAddress,
        collection: element.contract.contract_address,
        tokenId: element.token_id,
        metadata
      }
    } )
    setNftInfoArray(rentalAndMetadataArray);
    setOwnedNftArray(ownedNfts);
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
      {!isLoading && userStatus == 'connected' && getNftCards(selectedCategory.name)}
    </section>
  );
}
