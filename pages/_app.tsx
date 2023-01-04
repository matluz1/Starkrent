import '../styles/globals.css';
import Head from 'next/head';
import { useRouter } from 'next/router';
import type { AppProps } from 'next/app';
import { StarknetConfig, InjectedConnector } from '@starknet-react/core';
import Navigation from '../components/mainNavigation';

export default function App({ Component, pageProps }: AppProps) {
  const router = useRouter();
  const connectors = [
    new InjectedConnector({ options: { id: 'braavos' } }),
    new InjectedConnector({ options: { id: 'argentX' } }),
  ];

  function getPageContent() {
    return router.pathname === '/' ? (
      <>
        <Head>
          <title>Starkrent</title>
        </Head>
        <Component {...pageProps} />
      </>
    ) : (
      <StarknetConfig connectors={connectors}>
        <Head>
          <title>Starkrent</title>
        </Head>
        <Navigation />
        <main>
          <Component {...pageProps} />
        </main>
      </StarknetConfig>
    );
  }

  return getPageContent();
}
