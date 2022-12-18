import { useRouter } from 'next/router';
import Image from 'next/image';
import styles from '../../styles/Rent.module.scss';
import Link from 'next/link';

const socialIconSize = 20;

const Home = () => {
  const router = useRouter();

  return (
    <section className={styles.rent}>
      <h1>Select your Collection</h1>
      <div className={styles.collectionWrapper}>
        <Link href="/app/rent/collection" className={styles.collection}>
          <div className={styles.collectionHeader}>
            <Image
              className={styles.profileImage}
              src="/placeholder.png"
              alt="Collection name"
              width={70}
              height={70}
            />
            <h3>CollectionName</h3>
          </div>
          <div className={styles.collectionContent}>
            <span>test</span>
            <div className={styles.socials}>
              <Image
                src="/twitter.svg"
                alt="Twitter icon"
                width={socialIconSize}
                height={socialIconSize}
              />
              <Image
                src="/discord.svg"
                alt="Discord icon"
                width={socialIconSize}
                height={socialIconSize}
              />
            </div>
          </div>
          <button className={styles.toggleContent}>
            <Image
              src="/plus.svg"
              alt="Show more"
              width={socialIconSize}
              height={socialIconSize}
            />
          </button>
        </Link>
      </div>
    </section>
  );
};

export default Home;
