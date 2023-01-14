import axios from 'axios';
import { Contract, Provider } from 'starknet';

function tokenUriCleaner(tokenUri: any) {
  const tokenUriCleaned = tokenUri?.map((element: any) => element.words[0]);
  const tokenUriAddress = tokenUriCleaned.map((element: number) =>
    String.fromCharCode(element),
  );
  return tokenUriAddress.join('');
}

export default async function getMetadata(collectionAddress: string, tokenId: string) {
  const provider = new Provider({ sequencer: { network: 'goerli-alpha' } });
  const { abi } = await provider.getClassAt(collectionAddress);
  if (abi === undefined) {
    throw new Error('no abi.');
  }

  const contract = new Contract(abi, collectionAddress, provider);

  const response = await contract.call('tokenURI', [[tokenId, '0']]);
  const tokenUriAddress = tokenUriCleaner(response.tokenURI);
  const metadata = await axios.get(tokenUriAddress);
  return metadata.data;
}
