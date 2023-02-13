%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable.library import Ownable

from src.collateral.library import Collateral
from src.collection.library import Collection
from src.offer.library import Offer, OfferStruct, IndexedOfferStruct
from src.rent.library import Rent

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    limit_rent_min_time: felt,
    limit_rent_max_time: felt,
    limit_same_nft_offer: felt,
    tax_fee: felt,
    owner: felt,
) {
    Ownable.initializer(owner);
    Offer.initializer(limit_rent_min_time, limit_rent_max_time, limit_same_nft_offer);
    Rent.initializer(tax_fee);

    return ();
}

//
// Views
//
@view
func listCollections{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    collections_len: felt, collections: felt*
) {
    let (len, collections) = Collection.list();
    return (len, collections);
}

@view
func listCollaterals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    collaterals_len: felt, collaterals: felt*
) {
    let (len, collaterals) = Collateral.list();
    return (len, collaterals);
}

@view
func listOffers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    offset: felt,
    limit: felt,
    filter_by_collection: felt,
    filter_by_owner: felt,
    inverse_order: felt,
) -> (offers_len: felt, offers: IndexedOfferStruct*) {
    let (len, offers) = Offer.list(
        offset, limit, filter_by_collection, filter_by_owner, inverse_order
    );
    return (len, offers);
}

@view
func getOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt) -> (
    offer: OfferStruct
) {
    let (offer) = Offer.get(index);

    return (offer,);
}

@view
func getOffersByTokenId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt, tokenId: Uint256
) -> (offers_len: felt, offers: IndexedOfferStruct*) {
    let (len, offers) = Offer.get_by_token_id(collection, tokenId);

    return (len, offers);
}

//
// External
//

@external
func addCollection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) -> (index: felt) {
    Ownable.assert_only_owner();
    let (index) = Collection.add(address);

    return (index,);
}

@external
func removeCollection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt
) {
    Ownable.assert_only_owner();
    Collection.remove_by_index(index);

    return ();
}

@external
func addCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) -> (index: felt) {
    Ownable.assert_only_owner();
    let (index) = Collateral.add(address);

    return (index,);
}

@external
func removeCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt
) {
    Ownable.assert_only_owner();
    Collateral.remove_by_index(index);

    return ();
}

@external
func configOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    limit_rent_time_min: felt, limit_rent_time_max: felt, limit_same_nft_offer: felt
) {
    Ownable.assert_only_owner();
    Offer.set_offer_config(limit_rent_time_min, limit_rent_time_max, limit_same_nft_offer);

    return ();
}

@external
func pauseUnpauseOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    status: felt
) {
    Ownable.assert_only_owner();
    Offer.pause_toggle();

    let (status) = Offer.is_paused();

    return (status,);
}

@external
func offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt,
    tokenId: Uint256,
    collateral: felt,
    collateral_amount: Uint256,
    interest_rate: Uint256,
    rent_time_min: felt,
    rent_time_max: felt,
) -> (index: felt) {
    let (is_paused) = Offer.is_paused();

    with_attr error_message("Offer: register is paused.") {
        if (is_paused == TRUE) {
            Ownable.assert_only_owner();
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    }

    let (offer_id) = Offer.register(
        collection,
        tokenId,
        collateral,
        collateral_amount,
        interest_rate,
        rent_time_min,
        rent_time_max,
    );

    return (offer_id,);
}

@external
func cancelOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt) {
    let (caller) = get_caller_address();
    let (contract_owner) = Ownable.owner();

    if (caller != contract_owner) {
        Offer.assert_only_offer_owner(index);
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    Offer.remove_by_index(index);

    return ();
}

@external
func cancelOffers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    filter_by_collection: felt, filter_by_owner: felt
) -> (offersCancelled: felt) {
    Ownable.assert_only_owner();

    let counter = Offer.remove_all(filter_by_collection, filter_by_owner);

    return (counter,);
}

@external
func pauseUnpauseRent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    status: felt
) {
    Ownable.assert_only_owner();
    Rent.pause_toggle();

    let (status) = Rent.is_paused();

    return (status,);
}

@external
func rent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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
    Rent.register(
        index,
        collection,
        tokenId,
        collateral,
        collateral_amount,
        interest_rate,
        rent_time_min,
        rent_time_max,
        timestamp,
    );

    return ();
}

@external
func returnNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt, collection: felt, tokenId: Uint256
) {
    Rent.assert_only_rent_owner(index);

    Rent.return_NFT(index, collection, tokenId);

    return ();
}

// @external
// func returnNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt) {
// }

// @external
// func executeNotReturnedNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
//     len: felt
// ) {
// }
