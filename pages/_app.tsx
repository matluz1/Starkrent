import React from 'react';
import '../styles/globals.css';
import styles from '../styles/Nav.module.scss';
import Head from 'next/head';
import Link from 'next/link';
import Image from 'next/image';
import { useRouter } from 'next/router';
import { StarknetConfig, InjectedConnector } from '@starknet-react/core';
import ConnectWallet from '../components/connectWallet';
import { QueryClient, QueryClientProvider, useQuery } from 'react-query'
import type { AppProps } from 'next/app';

export default function App({ Component, pageProps }: AppProps) {
  const router = useRouter();
  const queryClient = new QueryClient();
  const connectors = [
    new InjectedConnector({ options: { id: 'braavos' } }),
    new InjectedConnector({ options: { id: 'argentX' } }),
  ];

  function getHead() {
    return (
      <Head>
        <title>Starkrent</title>
      </Head>
    );
  }

  function getNav() {
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

  function getPageContent() {
    return router.pathname === '/' ? (
      <>
        {getHead()}
        <Component {...pageProps} />
      </>
    ) : (
      <>
        {getHead()}
        {getNav()}
        <main>
        <QueryClientProvider client={queryClient}>
          <Component {...pageProps} />
        </QueryClientProvider>
        </main>
      </>
    );
  }

  return getPageContent();
}
