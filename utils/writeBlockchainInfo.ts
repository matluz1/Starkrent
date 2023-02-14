import { useStarknetExecute } from '@starknet-react/core';

export interface OfferContract {
  collection: string;
  tokenId: string;
  collateral: string;
  collateral_amount: number;
  interest_rate: number;
  rent_time_min: number;
  rent_time_max: number;
}

export interface RentContract extends OfferContract {
  index: number;
  owner: string;
  timestamp: number;
}

export function getOfferExecute({
  collection,
  tokenId,
  collateral,
  collateral_amount,
  interest_rate,
  rent_time_min,
  rent_time_max,
}: OfferContract) {
  const starkrentContract =
    '0xbb744a86ffce5a42be9b14f5bfaa02ee535e0b62db5af127411f5f35ce8153'; //testnet contract
  const calls = [
    {
      contractAddress: starkrentContract,
      entrypoint: 'offer',
      calldata: [
        collection,
        tokenId, //cairo Uint256
        0,
        collateral,
        collateral_amount, //cairo Uint256
        0,
        interest_rate, //cairo Uint256
        0,
        rent_time_min,
        rent_time_max,
      ],
    },
  ];

  return useStarknetExecute({ calls }).execute;
}

export function getRentExecute({
  index,
  collection,
  tokenId,
  collateral,
  collateral_amount,
  interest_rate,
  rent_time_min,
  rent_time_max,
  timestamp,
}: RentContract) {
  const starkrentContract =
    '0xbb744a86ffce5a42be9b14f5bfaa02ee535e0b62db5af127411f5f35ce8153'; //testnet contract
  const calls = [
    {
      contractAddress: starkrentContract,
      entrypoint: 'rent',
      calldata: [
        index,
        collection,
        tokenId, //cairo Uint256
        0,
        collateral,
        collateral_amount, //cairo Uint256
        0,
        interest_rate, //cairo Uint256
        0,
        rent_time_min,
        rent_time_max,
        timestamp,
      ],
    },
  ];

  return useStarknetExecute({ calls }).execute;
}
