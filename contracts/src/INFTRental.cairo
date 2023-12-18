%lang starknet

from starkware.cairo.common.uint256 import Uint256
from src.offer.library import OfferStruct

@contract_interface
namespace INFTRental {
    func listCollections() -> (collections_len: felt, collections: felt*) {
    }

    func listCollaterals() -> (collaterals_len: felt, collaterals: felt*) {
    }

    func listOffers(
        offset: felt,
        limit: felt,
        filter_by_collection: felt,
        filter_by_owner: felt,
        inverse_order: felt,
    ) -> (offers_len: felt, offers: OfferStruct*) {
    }

    func getOffer(index: felt) -> (offer: OfferStruct) {
    }

    func getOffersByTokenId(collection: felt, tokenId: Uint256) -> (
        offers_len: felt, offers: OfferStruct*
    ) {
    }

    func listRents(
        offset: felt,
        limit: felt,
        filter_by_collection: felt,
        filter_by_owner: felt,
        inverse_order: felt,
    ) -> (rents_len: felt, rents: RentStruct*) {
    }

    func getRent(index: felt) -> (rent: RentStruct) {
    }

    func getRentsByTokenId(collection: felt, tokenId: Uint256) -> (
        rents_len: felt, rents: RentStruct*
    ) {
    }

    func addCollection(address: felt) -> (index: felt) {
    }

    func removeCollection(index: felt) {
    }

    func addCollateral(address: felt) -> (index: felt) {
    }

    func removeCollateral(index: felt) {
    }

    func configOffer(
        limit_rent_time_min: felt, limit_rent_time_max: felt, limit_same_nft_offer: felt
    ) -> () {
    }

    func pauseUnpauseOffer() -> (status: felt) {
    }

    func offer(
        collection: felt,
        tokenId: Uint256,
        collateral: felt,
        collateral_amount: Uint256,
        interest_rate: Uint256,
        rent_time_min: felt,
        rent_time_max: felt,
    ) -> (index: felt) {
    }

    func cancelOffer(index: felt) {
    }

    func cancelOffers(filter_by_collection: felt, filter_by_owner: felt) -> (
        offersCancelled: felt
    ) {
    }

    func pauseUnpauseRent() -> (status: felt) {
    }

    func rent(
        index: felt,
        collection: felt,
        tokenId: Uint256,
        collateral: felt,
        collateral_amount: Uint256,
        interest_rate: Uint256,
        rent_time_min: felt,
        rent_time_max: felt,
        timestamp: felt,
    ) {
    }

    func cancelRent(index: felt, tax_fee: felt, timestamp: felt) {
    }

    func returnNFT(index: felt) {
    }

    func executeNotReturnedNFTs() -> (len: felt) {
    }
}
