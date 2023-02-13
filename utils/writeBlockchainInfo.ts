import { useStarknetExecute } from '@starknet-react/core';


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
}: ContractOffer) {

  const starkrentContract =
    '0x02a28030a1b1166e5e66bb25abe2bea61b31a21a1be791386210ad4a901c2275'; //testnet contract
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
        timestamp
      ],
    },
  ];

  return useStarknetExecute({ calls }).execute;
}

export function getOfferExecute({
  collection,
  tokenId,
  collateral,
  collateral_amount,
  interest_rate,
  rent_time_min,
  rent_time_max,
}: any) {

  const starkrentContract =
    '0x02a28030a1b1166e5e66bb25abe2bea61b31a21a1be791386210ad4a901c2275'; //testnet contract
  const calls = [
    {
      contractAddress: starkrentContract,
      entrypoint: 'offer',
      calldata: [
        collection,
        tokenId, //cairo Uint256
        0,
        collateral,
        collateral_amount * 0.1, //cairo Uint256
        0,
        interest_rate * 0.1, //cairo Uint256
        0,
        rent_time_min,
        rent_time_max,
      ],
    },
  ];

  return useStarknetExecute({ calls }).execute;
}
