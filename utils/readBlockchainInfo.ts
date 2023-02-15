import axios from 'axios';
import { Contract, Provider } from 'starknet';
import collections from '../info/collections.json';

interface OfferContract {
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

interface RentContract {
  index: number;
  owner: string;
  tax_fee: number;
  offer: OfferContract;
  timestamp: number;
}

async function getStarknetContract(contractAddress: string) {
  const provider = new Provider({ sequencer: { network: 'goerli-alpha' } });
  const { abi } = await provider.getClassAt(contractAddress);
  if (abi === undefined) {
    throw new Error('no abi.');
  }
  const contract = new Contract(abi, contractAddress, provider);
  return contract;
}

function getProcessedOffer(offerResponse: any) {
  return {
    owner: '0x' + offerResponse.owner.toString(16),
    collection: '0x' + offerResponse.collection.toString(16),
    tokenId: (
      Number(offerResponse.tokenId.low) +
      Number(offerResponse.tokenId.high) * 2 ** 128
    ).toString(),
    collateral: '0x' + offerResponse.collateral.toString(16),
    collateral_amount:
      Number(offerResponse.collateral_amount.low) +
      Number(offerResponse.collateral_amount.high) * 2 ** 128,
    interest_rate:
      Number(offerResponse.interest_rate.low) +
      Number(offerResponse.interest_rate.high) * 2 ** 128,
    rent_time_min: Number(offerResponse.rent_time_min),
    rent_time_max: Number(offerResponse.rent_time_max),
    timestamp: Number(offerResponse.timestamp),
  };
}

export async function getCollectionOffers(collectionAddress: string) {
  const contractAddress =
    '0xbb744a86ffce5a42be9b14f5bfaa02ee535e0b62db5af127411f5f35ce8153'; //testnet contract
  const contract = await getStarknetContract(contractAddress);
  const response = await contract.call('listOffers', [
    '0',
    '0',
    collectionAddress,
    '0',
    '0',
  ]);
  const offers: OfferContract[] = response.offers.map((offerElement: any) => {
    return {
      index: Number(offerElement.index),
      ...getProcessedOffer(offerElement.offer)
    };
  });
  return offers;
}

export async function getUserRents(userAddress: string) {
  const contractAddress =
    '0xbb744a86ffce5a42be9b14f5bfaa02ee535e0b62db5af127411f5f35ce8153'; //testnet contract
  const contract = await getStarknetContract(contractAddress);
  const response = await contract.call('listRents', [
    '0',
    '0',
    '0',
    userAddress,
    '0',
  ]);
  const rents: RentContract[] = response.rents.map((rentElement: any) => {
    return {
      index: Number(rentElement.index),
      owner: '0x' + rentElement.rent.owner.toString(16),
      tax_fee: Number(rentElement.rent.tax_fee),
      offer: getProcessedOffer(rentElement.rent.offer),
      timestamp: Number(rentElement.rent.timestamp),
    }
  });
  return rents;
}

export async function getMetadata(collectionAddress: string, tokenId: string) {
  const baseUri = collections.find(
    (element) => element.address === collectionAddress,
  )?.baseUri;
  const metadata = await axios.get(baseUri + tokenId);
  return metadata.data;
}
