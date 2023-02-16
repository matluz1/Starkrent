export interface OfferContract {
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

export interface RentContract {
  owner: string;
  tax_fee: number;
  offer: OfferContract;
  timestamp: number;
}

export interface IndexedOfferContract extends OfferContract {
  index: number;
}

export interface IndexedRentContract extends RentContract {
  index: number;
}

export interface OfferExecuteArgs {
  collection: string;
  tokenId: string;
  collateral: string;
  collateral_amount: number;
  interest_rate: number;
  rent_time_min: number;
  rent_time_max: number;
}

export interface RentExecuteArgs {
  index: number;
  collection: string;
  tokenId: string;
  collateral: string;
  collateral_amount: number;
  interest_rate: number;
  rent_time_min: number;
  rent_time_max: number;
  timestamp: number;
}
