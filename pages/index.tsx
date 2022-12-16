import Image from 'next/image';
import styles from '../styles/Home.module.scss';
import Link from 'next/link';

export default function Home() {
  return (
    <section className={styles.home}>
      <main className={styles.main}>
        <div className={styles.content}>
          <Image
            className={styles.logo}
            src="/logo.svg"
            alt="Starkrent lion logo"
            width={150}
            height={150}
          />
          <Image
            src="/starkrent.svg"
            alt="Starkrent logotype"
            width={500}
            height={50}
          />
          <span>The FIRST and BEST renting protocol on STARKNET</span>
        </div>

        <Link href="/app/rent">Launch app</Link>
      </main>

      <footer className={styles.footer}>
        <a href="https://www.twitter.com" target="blank">
          <Image src="/twitter.svg" alt="Twitter icon" width={30} height={30} />
        </a>
        <a href="https://www.discord.com" target="blank">
          <Image src="/discord.svg" alt="Discord icon" width={30} height={30} />
        </a>
        <a href="https://www.medium.com" target="blank">
          <Image src="/medium.svg" alt="Medium icon" width={30} height={30} />
        </a>
      </footer>
    </section>
  );
}
