%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
    assert_in_range,
    assert_le,
    assert_lt,
    assert_nn,
    assert_nn_le,
    assert_not_zero,
)
from starkware.starknet.common.syscalls import get_block_timestamp, get_caller_address
from starkware.cairo.common.uint256 import (
    assert_uint256_le,
    assert_uint256_lt,
    Uint256,
    uint256_check,
    uint256_eq,
    uint256_mul,
)

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from src.collateral.library import Collateral, COLLATERAL_AMOUNT_MAX
from src.collection.library import Collection

//
// Structs
//

struct OfferStruct {
    owner: felt,
    collection: felt,
    tokenId: Uint256,
    collateral: felt,
    collateral_amount: Uint256,
    interest_rate: Uint256,
    rent_time_min: felt,
    rent_time_max: felt,
    timestamp: felt,
}

struct IndexedOfferStruct {
    index: felt,
    offer: OfferStruct,
}

struct OfferConfigStruct {
    limit_rent_time_min: felt,
    limit_rent_time_max: felt,
    limit_same_nft_offer: felt,
}

//
// Events
//

@event
func LogOfferCreated(offer: OfferStruct) {
}

@event
func LogOfferRemoved(offer: OfferStruct) {
}

@event
func LogSetOfferConfig(config: OfferConfigStruct) {
}

@event
func LogOfferPauseToggle(status: felt) {
}

//
// Storage
//

@storage_var
func Offer_config() -> (config: OfferConfigStruct) {
}

@storage_var
func Offer_paused() -> (is_paused: felt) {
}

@storage_var
func Offer_len() -> (len: felt) {
}

@storage_var
func Offer_map(index: felt) -> (offer: OfferStruct) {
}

namespace Offer {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        limit_rent_time_min: felt, limit_rent_time_max: felt, limit_same_nft_offer: felt
    ) {
        set_offer_config(limit_rent_time_min, limit_rent_time_max, limit_same_nft_offer);

        return ();
    }

    //
    // Guards
    //

    func assert_only_offer_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) {
        let (offer) = get(index);
        let (caller) = get_caller_address();
        with_attr error_message("Offer: caller is the zero address.") {
            assert_not_zero(caller);
        }
        with_attr error_message("Offer: caller is not the offer owner.") {
            assert caller = offer.owner;
        }

        return ();
    }

    func assert_tokenId_is_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
    ) {
        with_attr error_message("Offer: token Id is not valid.") {
            uint256_check(tokenId);
        }

        return ();
    }

    //
    // Mutative
    //

    func set_offer_config{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        limit_rent_time_min: felt, limit_rent_time_max: felt, limit_same_nft_offer: felt
    ) {
        with_attr error_message("Offer: invalid boundaries parameters.") {
            assert_not_zero(limit_rent_time_min);
            assert_not_zero(limit_rent_time_max);
            assert_not_zero(limit_same_nft_offer);
            assert_nn(limit_rent_time_min);
            assert_nn(limit_rent_time_max);
            assert_nn(limit_same_nft_offer);
            assert_le(limit_rent_time_min, limit_rent_time_max);
        }

        let config: OfferConfigStruct = OfferConfigStruct(
            limit_rent_time_min, limit_rent_time_max, limit_same_nft_offer
        );

        Offer_config.write(config);

        LogSetOfferConfig.emit(config);

        return ();
    }

    func add{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        offer: OfferStruct
    ) -> (index: felt) {
        let (len) = Offer_len.read();

        Offer_map.write(len, offer);
        Offer_len.write(len + 1);

        LogOfferCreated.emit(offer);

        return (len,);
    }

    func remove_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) {
        with_attr error_message("Offer: index cannot be negative.") {
            assert_nn(index);
        }

        let (len) = Offer_len.read();

        with_attr error_message("Offer: nothing to remove.") {
            assert_not_zero(len);
        }

        with_attr error_message("Offer: index need to be lesser than {len}.") {
            assert_lt(index, len);
        }

        let (offer) = Offer_map.read(index);
        let last_index = len - 1;

        Offer_len.write(last_index);

        let zero_as_uint256 = Uint256(0, 0);

        let empty_struct: OfferStruct = OfferStruct(
            owner=0,
            collection=0,
            tokenId=zero_as_uint256,
            collateral=0,
            collateral_amount=zero_as_uint256,
            interest_rate=zero_as_uint256,
            rent_time_min=0,
            rent_time_max=0,
            timestamp=0,
        );

        // If is the last index, just remove it
        if (index == last_index) {
            Offer_map.write(index, empty_struct);
            return ();
        }

        // If not, replace removed index with last offer
        let (last_offer) = Offer_map.read(last_index);
        Offer_map.write(index, last_offer);
        Offer_map.write(last_index, empty_struct);

        LogOfferRemoved.emit(offer);
        return ();
    }

    func pause_toggle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        res: felt
    ) {
        tempvar new_status;

        let (is_paused) = Offer_paused.read();

        if (is_paused == FALSE) {
            new_status = TRUE;
        } else {
            new_status = FALSE;
        }

        Offer_paused.write(new_status);

        LogOfferPauseToggle.emit(new_status);

        return (new_status,);
    }

    func register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        collection: felt,
        tokenId: Uint256,
        collateral: felt,
        collateral_amount: Uint256,
        interest_rate: Uint256,
        rent_time_min: felt,
        rent_time_max: felt,
    ) -> (offer_id: felt) {
        alloc_locals;

        assert_tokenId_is_valid(tokenId);
        Collection.assert_is_whitelisted(collection);
        Collateral.assert_is_whitelisted(collateral);
        Collateral.assert_amount_is_valid(collateral_amount);
        Collateral.assert_amount_is_valid(interest_rate);

        let config: OfferConfigStruct = Offer_config.read();

        with_attr error_message("Offer: rent time outside boundaries.") {
            assert_le(rent_time_min, rent_time_max);
            assert_in_range(
                rent_time_min, config.limit_rent_time_min, config.limit_rent_time_max + 1
            );
            assert_in_range(
                rent_time_max, config.limit_rent_time_min, config.limit_rent_time_max + 1
            );
        }

        with_attr error_message("Offer: rent time max exceeds interest rate distribution.") {
            let (collateral_rent_total, _) = uint256_mul(interest_rate, Uint256(rent_time_max, 0));
            assert_uint256_le(collateral_rent_total, collateral_amount);
        }

        with_attr error_message("Offer: offers of same NFT maxed out.") {
            let (len) = Offer_len.read();
            let count_already_added = Offer._get_length_recursive_by_collection_and_token_id(
                collection, tokenId, 0, len, 0
            );
            assert_lt(count_already_added, config.limit_same_nft_offer);
        }

        with_attr error_message("Offer: token not belongs to caller.") {
            let (caller) = get_caller_address();
            let (token_owner) = IERC721.ownerOf(collection, tokenId);
            assert token_owner = caller;
        }

        let (timestamp) = get_block_timestamp();
        let offer = OfferStruct(
            owner=caller,
            collection=collection,
            tokenId=tokenId,
            collateral=collateral,
            collateral_amount=collateral_amount,
            interest_rate=interest_rate,
            rent_time_min=rent_time_min,
            rent_time_max=rent_time_max,
            timestamp=timestamp,
        );
        let (new_len) = add(offer);

        return (new_len,);
    }

    func remove{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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
        alloc_locals;

        let (offer) = get(index);

        with_attr error_message("Offer: this offer no longer exists.") {
            assert offer = OfferStruct(collection,
                tokenId,
                collateral,
                collateral_amount,
                interest_rate,
                rent_time_min,
                rent_time_max,
                timestamp
                );
        }

        remove_by_index(index);

        return ();
    }

    func remove_all{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        collection: felt, owner: felt
    ) -> felt {
        let (len) = Offer_len.read();

        let counter = _remove_all_recursive(collection, owner, 0, 0, len);

        return counter;
    }

    func remove_same{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        collection: felt, tokenId: Uint256
    ) {
        let (len, offers) = get_by_token_id(collection, tokenId);

        _remove_recursive(offers, len);

        return ();
    }

    //
    // View
    //

    func is_paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        res: felt
    ) {
        let (is_paused) = Offer_paused.read();
        return (is_paused,);
    }

    func get{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt) -> (
        res: OfferStruct
    ) {
        with_attr error_message("Offer: index is not valid.") {
            let (len) = Offer_len.read();
            assert_nn_le(index, len);
        }

        let (offer: OfferStruct) = Offer_map.read(index);
        return (offer,);
    }

    func get_by_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        collection: felt, tokenId: Uint256
    ) -> (array_len: felt, array: IndexedOfferStruct*) {
        alloc_locals;

        assert_tokenId_is_valid(tokenId);

        Collection.assert_is_whitelisted(collection);

        let (array: IndexedOfferStruct*) = alloc();
        let (len) = Offer_len.read();
        let counter = _get_by_token_id_recursive(array, 0, collection, tokenId, 0, len);

        return (counter, array);
    }

    func list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        offset: felt, limit: felt, collection: felt, owner: felt, inverse: felt
    ) -> (array_len: felt, array: IndexedOfferStruct*) {
        alloc_locals;

        let (len) = Offer_len.read();

        with_attr error_message("Offer: offset cannot be negative.") {
            assert_nn(offset);
        }

        with_attr error_message("Offer: limit cannot be negative.") {
            assert_nn(limit);
        }

        if (collection != 0) {
            Collection.assert_is_whitelisted(collection);
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        let (array: IndexedOfferStruct*) = alloc();

        local start_at;
        if (inverse == TRUE) {
            start_at = len - 1;
        } else {
            start_at = offset;
        }

        local max;
        if (limit == 0) {
            max = len;
        } else {
            max = limit;
        }

        let counter = _list_offer_recursive(
            array, start_at, max, collection, owner, inverse, 0, len
        );

        return (counter, array);
    }

    //
    // Internal
    //

    func _get_length_recursive_by_collection_and_token_id{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(collection: felt, tokenId: Uint256, index: felt, len: felt, counter: felt) -> felt {
        alloc_locals;
        let (offer: OfferStruct) = Offer_map.read(index);

        if (len == 0) {
            return counter;
        }

        if (offer.collection != collection) {
            return _get_length_recursive_by_collection_and_token_id(
                collection, tokenId, index + 1, len - 1, counter
            );
        }

        let (is_equal_tokenId) = uint256_eq(offer.tokenId, tokenId);

        if (is_equal_tokenId == FALSE) {
            return _get_length_recursive_by_collection_and_token_id(
                collection, tokenId, index + 1, len - 1, counter
            );
        }

        return _get_length_recursive_by_collection_and_token_id(
            collection, tokenId, index + 1, len - 1, counter + 1
        );
    }

    func _list_offer_recursive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        array: IndexedOfferStruct*,
        index: felt,
        limit: felt,
        collection: felt,
        owner: felt,
        inverse: felt,
        counter: felt,
        len: felt,
    ) -> felt {
        alloc_locals;
        local collection_check;
        local owner_check;
        local pointer;

        if (len == 0) {
            return counter;
        }

        if (counter == limit) {
            return counter;
        }

        let (offer) = Offer_map.read(index);

        if (collection == 0) {
            collection_check = TRUE;
        } else {
            if (collection == offer.collection) {
                collection_check = TRUE;
            } else {
                collection_check = FALSE;
            }
        }

        if (owner == 0) {
            owner_check = TRUE;
        } else {
            if (owner == offer.owner) {
                owner_check = TRUE;
            } else {
                owner_check = FALSE;
            }
        }

        if (inverse == 1) {
            pointer = -1;
        } else {
            pointer = 1;
        }

        if (collection_check == TRUE) {
            if (owner_check == TRUE) {
                assert [array] = IndexedOfferStruct(index, offer);
                return _list_offer_recursive(
                    array + IndexedOfferStruct.SIZE,
                    index + pointer,
                    limit,
                    collection,
                    owner,
                    inverse,
                    counter + 1,
                    len - 1,
                );
            }
        }

        return _list_offer_recursive(
            array, index + pointer, limit, collection, owner, inverse, counter, len - 1
        );
    }

    func _remove_all_recursive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        collection: felt, owner: felt, index: felt, counter: felt, len: felt
    ) -> felt {
        alloc_locals;
        local collection_check;
        local owner_check;

        if (len == 0) {
            return counter;
        }

        let (offer) = Offer_map.read(index);

        if (collection == 0) {
            collection_check = TRUE;
        } else {
            if (collection == offer.collection) {
                collection_check = TRUE;
            } else {
                collection_check = FALSE;
            }
        }

        if (owner == 0) {
            owner_check = TRUE;
        } else {
            if (owner == offer.owner) {
                owner_check = TRUE;
            } else {
                owner_check = FALSE;
            }
        }

        if (collection_check == TRUE) {
            if (owner_check == TRUE) {
                Offer.remove_by_index(index);
                return _remove_all_recursive(collection, owner, index, counter + 1, len - 1);
            }
        }

        return _remove_all_recursive(collection, owner, index + 1, counter, len - 1);
    }

    func _remove_recursive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        offers: IndexedOfferStruct*, len: felt
    ) {
        if (len == 0) {
            return ();
        }

        let offer = offers[len - 1];

        Offer.remove_by_index(offer.index);

        return _remove_recursive(offers, len - 1);
    }

    func _get_by_token_id_recursive{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        array: IndexedOfferStruct*,
        index: felt,
        collection: felt,
        tokenId: Uint256,
        counter: felt,
        len: felt,
    ) -> felt {
        alloc_locals;
        local collection_check;
        local tokenId_check;

        if (len == 0) {
            return counter;
        }

        let (offer) = Offer_map.read(index);

        if (collection == offer.collection) {
            collection_check = TRUE;
        } else {
            collection_check = FALSE;
        }

        let (is_tokenId_eq) = uint256_eq(tokenId, offer.tokenId);

        if (is_tokenId_eq == TRUE) {
            tokenId_check = TRUE;
        } else {
            tokenId_check = FALSE;
        }

        if (collection_check == TRUE) {
            if (tokenId_check == TRUE) {
                assert [array] = IndexedOfferStruct(index, offer);
                return _get_by_token_id_recursive(
                    array + IndexedOfferStruct.SIZE,
                    index + 1,
                    collection,
                    tokenId,
                    counter + 1,
                    len - 1,
                );
            }
        }

        return _get_by_token_id_recursive(array, index + 1, collection, tokenId, counter, len - 1);
    }
}
