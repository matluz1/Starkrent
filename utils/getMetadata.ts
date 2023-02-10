import axios from 'axios';
import { Contract, Provider } from 'starknet';
import collections from '../info/collections.json';

export async function getContractOffers(collectionAddress: string) {
  const contractAddress = "0x02a28030a1b1166e5e66bb25abe2bea61b31a21a1be791386210ad4a901c2275";
  const provider = new Provider({ sequencer: { network: 'goerli-alpha' } });
  const { abi } = await provider.getClassAt(contractAddress);
  if (abi === undefined) {
    throw new Error('no abi.');
  }
  const contract = new Contract(abi, contractAddress, provider);
  const response = await contract.call('listOffers', ['0', '0', collectionAddress, '0', '0']);
  return response.offers;
}

export async function getMetadata(
  collectionAddress: string,
  tokenId: string,
) {
  const baseUri = collections.find(
    (element) => element.address === collectionAddress,
  )?.baseUri;
  const metadata = await axios.get(baseUri+tokenId);
  return metadata.data;
}
