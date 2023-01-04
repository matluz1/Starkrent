import Link from 'next/link';
import Image from 'next/image';
import styles from '../styles/Nav.module.scss';
import ConnectWallet from './connectWallet';
import { useRouter } from 'next/router';
import { StarknetConfig, InjectedConnector } from '@starknet-react/core';

export default function mainNavigation() {
  const router = useRouter();
  const connectors = [
    new InjectedConnector({ options: { id: 'braavos' } }),
    new InjectedConnector({ options: { id: 'argentX' } }),
  ];

  return (
    <nav className={styles.nav}>
      <ul>
        <li>
          <Link href="/">
            <Image
              src="/logo.svg"
              alt="Starkrent lion logo"
              width={60}
              height={60}
            />
          </Link>
        </li>
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
        <StarknetConfig connectors={connectors}>
          <ConnectWallet />
        </StarknetConfig>
      </ul>
    </nav>
  );
}
