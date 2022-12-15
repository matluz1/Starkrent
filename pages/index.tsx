import Image from 'next/image';
import styles from '../styles/Home.module.scss';
import Link from 'next/link';

export default function Home() {
  return (
    <section className={styles.home}>
      <main className={styles.main}>
        <Image
          src="/logo.svg"
          alt="Starkrent lion logo"
          width={150}
          height={150}
        />
        <div className={styles.content}>
          <Image
            src="/starkrent.svg"
            className=".image"
            alt="Starkrent"
            width={500}
            height={50}
          />
          <span>The FIRST and BEST renting protocol on STARKNET</span>
        </div>

        <Link href="/app/rent">Launch app</Link>
      </main>

      <footer className={styles.footer}>{/* add social icons */}</footer>
    </section>
  );
}
