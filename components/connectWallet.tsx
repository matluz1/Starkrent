import { useAccount } from '@starknet-react/core';
import { useConnectors } from '@starknet-react/core';
import Image from 'next/image';

const buttonStyle = {
  color: '#2C354E',
  backgroundColor: '#FFF',
  borderRadius: '15rem',
  fontSize: '.9rem',
  padding: '.8rem 1.5rem',
  width: '10.4rem',
};

const disconnectWrapper = {
  marginLeft: 'auto',
  minWidth: '10.4rem',
  display: 'flex',
  justifyContent: 'right',
  alignItems: 'center',
  gap: '.5rem',
};

function shortenAddress(address: string) {
  return '0x' + address.slice(2, 6) + '...' + address.slice(-4);
}

export default function ConnectWallet() {
  const { address, status } = useAccount();
  const { connectors, connect, disconnect } = useConnectors();

  return status === 'disconnected' ? (
    <button style={buttonStyle} onClick={() => connect(connectors[1])}>
      Connect ArgentX
    </button>
  ) : (
    <div style={disconnectWrapper}>
      <span>{shortenAddress(address || '')}</span>
      <button style={{ backgroundImage: 'none' }} onClick={() => disconnect()}>
        <Image src="/x.svg" alt="Disconnect" width={12} height={12} />
      </button>
    </div>
  );
}
