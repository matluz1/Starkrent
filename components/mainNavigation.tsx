import Link from 'next/link';
import Image from 'next/image';
import styles from '../styles/Nav.module.scss';
import ConnectWallet from './connectWallet';
import { useRouter } from 'next/router';

export default function MainNavigation() {
  const router = useRouter();

  return (
    <section className={styles.navigationWrapper}>
      <Link href="/">
        <Image
          src="/logo.svg"
          alt="SwordRent lion logo"
          width={65}
          height={65}
        />
      </Link>
      <nav className={styles.nav}>
        <ul>
          <li
            className={
              router.pathname.startsWith('/app/rent')
                ? styles.active
                : styles.nonActive
            }
          >
            <Link href="/app/rent">Rent</Link>
          </li>
          <li
            className={
              router.pathname.startsWith('/app/profile')
                ? styles.active
                : styles.nonActive
            }
          >
            <Link href="/app/profile">Profile</Link>
          </li>
        </ul>
      </nav>
      <ConnectWallet />
    </section>
  );
}
