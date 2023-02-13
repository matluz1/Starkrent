import axios from 'axios';
import { Contract, Provider } from 'starknet';
import collections from '../info/collections.json';

interface ContractOffer {
  index: number;
  owner: string;
  collection: string;
  tokenId: string;
  collateral: string;
  collateral_amount: number;
  interest_rate: number;
  rent_time_min: number;
  rent_time_max: number;
  timestamp: number;
}

export async function getContractOffers(collectionAddress: string) {
  const contractAddress =
    '0x02a28030a1b1166e5e66bb25abe2bea61b31a21a1be791386210ad4a901c2275';
  const provider = new Provider({ sequencer: { network: 'goerli-alpha' } });
  const { abi } = await provider.getClassAt(contractAddress);
  if (abi === undefined) {
    throw new Error('no abi.');
  }
  const contract = new Contract(abi, contractAddress, provider);
  const response = await contract.call('listOffers', [
    '0',
    '0',
    collectionAddress,
    '0',
    '0',
  ]);
  const offers: ContractOffer[] = response.offers.map((offer: any) => {
    return {
      index: Number(offer.index),
      owner: '0x' + offer.offer.owner.toString(16),
      collection: '0x' + offer.offer.collection.toString(16),
      tokenId: (
        Number(offer.offer.tokenId.low) +
        Number(offer.offer.tokenId.high) * 2 ** 128
      ).toString(),
      collateral: '0x' + offer.offer.collateral.toString(16),
      collateral_amount:
        Number(offer.offer.collateral_amount.low) +
        Number(offer.offer.collateral_amount.high) * 2 ** 128,
      interest_rate:
        Number(offer.offer.interest_rate.low) +
        Number(offer.offer.interest_rate.high) * 2 ** 128,
      rent_time_min: Number(offer.offer.rent_time_min),
      rent_time_max: Number(offer.offer.rent_time_max),
      timestamp: offer.offer.timestamp.toString(),
    };
  });
  return offers;
}

export async function getMetadata(collectionAddress: string, tokenId: string) {
  const baseUri = collections.find(
    (element) => element.address === collectionAddress,
  )?.baseUri;
  const metadata = await axios.get(baseUri + tokenId);
  return metadata.data;
}
