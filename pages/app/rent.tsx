import { useState } from 'react';
import { useRouter } from 'next/router';
import Image from 'next/image';
import styles from '../../styles/Rent.module.scss';
import collections from '../../info/collections.json';

interface Collection {
  address: string;
  info: CollectionInfo;
}

interface CollectionInfo {
  name: string;
  profileImage: string;
  description: string;
  showingDescription?: boolean;
  twitter?: string;
  discord?: string;
  medium?: string;
}

type showDescriptionState = {
  [address: string]: boolean;
};

function getCollectionDescription(collection: Collection) {
  const socialIconSize = 20;

  return (
    <div className={styles.collectionDescription}>
      <span>{collection.info.description}</span>
      <div className={styles.socials}>
        {collection.info.twitter && (
          <a href={collection.info.twitter} target="blank">
            <Image
              src="/twitter.svg"
              alt="Twitter icon"
              width={socialIconSize}
              height={socialIconSize}
            />
          </a>
        )}
        {collection.info.discord && (
          <a href={collection.info.discord} target="blank">
            <Image
              src="/discord.svg"
              alt="Discord icon"
              width={socialIconSize}
              height={socialIconSize}
            />
          </a>
        )}
        {collection.info.medium && (
          <a href={collection.info.medium} target="blank">
            <Image
              src="/medium.svg"
              alt="Medium icon"
              width={socialIconSize}
              height={socialIconSize}
            />
          </a>
        )}
      </div>
    </div>
  );
}

export default function Rent() {
  const router = useRouter();
  const collectionArray: Collection[] = collections;
  const toggleDescriptionButtonSize = 12;
  const [showDescription, setShowDescription] = useState<showDescriptionState>(
    {},
  );

  function toggleDescription(address: string) {
    setShowDescription({
      ...showDescription,
      [address]: !showDescription[address],
    });
  }

  const handleClick = (address: string) => {
    router.push(`/app/rent/${address}`);
  };

  return (
    <section className={styles.rent}>
      <h1>Select the Collection</h1>
      <div className={styles.collectionWrapper}>
        {collectionArray.map((collection) => (
          <div className={styles.collection} key={collection.address}>
            <button
              className={styles.collectionTitle}
              onClick={() => handleClick(collection.address)}
            >
              <Image
                className={styles.profileImage}
                src={collection.info.profileImage}
                alt="Collection name"
                width={70}
                height={70}
              />
              <h3>{collection.info.name}</h3>
            </button>
            {showDescription[collection.address] &&
              getCollectionDescription(collection)}
            <button
              className={styles.toggleDescription}
              onClick={() => toggleDescription(collection.address)}
            >
              {showDescription[collection.address] ? (
                <Image
                  src="/minus.svg"
                  alt="Show less"
                  width={toggleDescriptionButtonSize}
                  height={toggleDescriptionButtonSize}
                />
              ) : (
                <Image
                  src="/plus.svg"
                  alt="Show more"
                  width={toggleDescriptionButtonSize}
                  height={toggleDescriptionButtonSize}
                />
              )}
            </button>
          </div>
        ))}
      </div>
    </section>
  );
}
