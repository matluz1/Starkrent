import { useState } from 'react';
import { useRouter } from 'next/router';
import Image from 'next/image';
import styles from '../../../styles/Rent.module.scss';
import collections from '../../../components/placeholder/collections';

const socialIconSize = 20;
const toggleDescriptionButtonSize = 12;

interface Collection {
  name: string;
  icon: string;
  description: string;
  showingDescription?: boolean;
  address: string;
  twitter?: string;
  discord?: string;
  medium?: string;
}

type showDescriptionState = {
  [address: string]: boolean;
};

const collectionArray: Collection[] = collections;

function getCollectionDescription(collectionInfo: Collection) {
  return (
    <div className={styles.collectionDescription}>
      <span>{collectionInfo.description}</span>
      <div className={styles.socials}>
        {collectionInfo.twitter && (
          <a href={collectionInfo.twitter} target="blank">
            <Image
              src="/twitter.svg"
              alt="Twitter icon"
              width={socialIconSize}
              height={socialIconSize}
            />
          </a>
        )}
        {collectionInfo.discord && (
          <a href={collectionInfo.discord} target="blank">
            <Image
              src="/discord.svg"
              alt="Discord icon"
              width={socialIconSize}
              height={socialIconSize}
            />
          </a>
        )}
        {collectionInfo.medium && (
          <a href={collectionInfo.medium} target="blank">
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

function Rent() {
  const router = useRouter();
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
      <h1>Select your Collection</h1>
      <div className={styles.collectionWrapper}>
        {collectionArray.map((collectionInfo) => (
          <div className={styles.collection} key={collectionInfo.address}>
            <button
              className={styles.collectionTitle}
              onClick={() => handleClick(collectionInfo.address)}
            >
              <Image
                className={styles.profileImage}
                src="/placeholder.png"
                alt="Collection name"
                width={70}
                height={70}
              />
              <h3>{collectionInfo.name}</h3>
            </button>
            {showDescription[collectionInfo.address] &&
              getCollectionDescription(collectionInfo)}
            <button
              className={styles.toggleDescription}
              onClick={() => toggleDescription(collectionInfo.address)}
            >
              {showDescription[collectionInfo.address] ? (
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

export default Rent;
