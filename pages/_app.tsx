import '../styles/globals.css';
import Head from 'next/head';
import { useRouter } from 'next/router';
import type { AppProps } from 'next/app';
import Navigation from '../components/mainNavigation';

export default function App({ Component, pageProps }: AppProps) {
  const router = useRouter();

  function getHead() {
    return (
      <Head>
        <title>Starkrent</title>
      </Head>
    );
  }

  function getNav() {
    return <Navigation />;
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
          <Component {...pageProps} />
        </main>
      </>
    );
  }

  return getPageContent();
}
