import { useAccount } from '@starknet-react/core';
import { useConnectors } from '@starknet-react/core';

const buttonStyle = {
  marginLeft: 'auto',
  color: '#2C354E',
  backgroundColor: '#FFF',
  borderRadius: '15rem',
  fontSize: '.9rem',
  padding: '.8rem 1.5rem',
};

export default function ConnectWallet() {
  const { account, address, status } = useAccount();
  const { connect, connectors } = useConnectors();

  return status === 'disconnected' ? (
    <button style={buttonStyle} onClick={() => connect(connectors[1])}>
      Connect ArgentX
    </button>
  ) : (
    <span>Account: {address}</span>
  );
}
