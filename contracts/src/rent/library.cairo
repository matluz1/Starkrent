%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_nn,
    assert_le,
    assert_lt,
    assert_in_range,
    assert_nn_le,
    assert_not_equal,
)
from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, assert_uint256_eq

from openzeppelin.token.erc721.IERC721 import IERC721
// from openzeppelin.token.erc20.IERC20 import IERC20

from src.collection.library import Collection
from src.offer.library import Offer, OfferStruct
from src.utils.SafeERC20 import SafeERC20

// Value in % with 2 decimals 1000 = 10%
const TAX_FEE_MAX = 1000;

//
// Structs
//

struct RentStruct {
    owner: felt,
    offer: OfferStruct,
    timestamp: felt,
    tax_fee: felt,
}

struct IndexedRentStruct {
    index: felt,
    rent: RentStruct,
}

//
// Events
//

@event
func LogRentCreated(rent: RentStruct) {
}

@event
func LogRentRemoved(rent: RentStruct) {
}

@event
func LogRentFinished(caller: felt, rent: RentStruct) {
}

@event
func LogRentReturned(rent: RentStruct) {
}

@event
func LogRentExecuted(rent: RentStruct) {
}

@event
func LogSetRentConfig(config: felt) {
}

@event
func LogRentPauseToggle(status: felt) {
}

//
// Storage
//

@storage_var
func Rent_config() -> (config: felt) {
}

@storage_var
func Rent_paused() -> (is_paused: felt) {
}

@storage_var
func Rent_len() -> (len: felt) {
}

@storage_var
func Rent_map(index: felt) -> (rent: RentStruct) {
}

namespace Rent {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tax_fee: felt
    ) {
        set_rent_config(tax_fee);

        return ();
    }

    //
    // Guards
    //

    func assert_only_rent_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) {
        let (rent) = get(index);
        let (caller) = get_caller_address();
        with_attr error_message("Rent: caller is the zero address") {
            assert_not_zero(caller);
        }
        with_attr error_message("Rent: caller is not the owner") {
            assert caller = rent.owner;
        }

        return ();
    }

    //
    // Mutative
    //

    func set_rent_config{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tax_fee: felt
    ) {
        with_attr error_message("Rent: invalid boundaries parameters.") {
            assert_nn_le(tax_fee, TAX_FEE_MAX);
        }

        Rent_config.write(tax_fee);

        LogSetRentConfig.emit(tax_fee);

        return ();
    }

    func pause_toggle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        res: felt
    ) {
        tempvar new_status;

        let (is_paused) = Rent_paused.read();

        if (is_paused == FALSE) {
            new_status = TRUE;
        } else {
            new_status = FALSE;
        }

        Rent_paused.write(new_status);

        LogRentPauseToggle.emit(new_status);

        return (new_status,);
    }

    func add{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(rent: RentStruct) -> (
        index: felt
    ) {
        alloc_locals;

        with_attr error_message("Rent: owner cannot be zero address.") {
            assert_not_zero(rent.owner);
        }

        with_attr error_message("Rent: tax fee outside boundaries.") {
            assert_in_range(rent.tax_fee, 0, TAX_FEE_MAX + 1);
        }

        let (len) = Rent_len.read();

        Rent_map.write(len, rent);
        Rent_len.write(len + 1);

        LogRentCreated.emit(rent);

        return (len,);
    }

    func remove_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) {
        with_attr error_message("Rent: index cannot be negative.") {
            assert_nn(index);
        }

        let (len) = Rent_len.read();

        with_attr error_message("Rent: nothing to remove.") {
            assert_not_zero(len);
        }

        with_attr error_message("Rent: index need to be lesser than {len}.") {
            assert_lt(index, len);
        }

        let (rent) = Rent_map.read(index);
        let last_index = len - 1;

        Rent_len.write(last_index);

        let zero_as_uint256: Uint256 = Uint256(0, 0);

        let empty_struct: RentStruct = RentStruct(
            owner=0,
            OfferStruct(
            owner=0,
            collection=0,
            tokenId=zero_as_uint256,
            collateral=0,
            collateral_amount=zero_as_uint256,
            interest_rate=zero_as_uint256,
            rent_time_min=0,
            rent_time_max=0,
            timestamp=0
            ),
            timestamp=0,
            tax_fee=0,
        );

        // If is the last index, just remove it
        if (index == last_index) {
            Rent_map.write(index, empty_struct);
            return ();
        }

        // If not, replace removed index with last rent
        let (last_rent) = Rent_map.read(last_index);
        Rent_map.write(index, last_rent);
        Rent_map.write(last_index, empty_struct);

        LogRentRemoved.emit(rent);
        return ();
    }

    func register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt,
        collection: felt,
        tokenId: Uint256,
        collateral: felt,
        collateral_amount: Uint256,
        interest_rate: Uint256,
        rent_time_min: felt,
        rent_time_max: felt,
        timestamp: felt,
    ) -> (rent_id: felt) {
        alloc_locals;

        let (caller) = get_caller_address();
        let (offer) = Offer.get(index);
        let (contract_address) = get_contract_address();

        with_attr error_message("Rent: caller cannot be the offer owner.") {
            assert_not_equal(caller, offer.owner);
        }

        with_attr error_message("Rent: this offer no longer exists.") {
            assert offer = OfferStruct(
                offer.owner,
                collection,
                tokenId,
                collateral,
                collateral_amount,
                interest_rate,
                rent_time_min,
                rent_time_max,
                timestamp,
                );
        }

        let (timestamp) = get_block_timestamp();
        let (tax_fee) = Rent_config.read();

        let rent = RentStruct(
            owner=caller,
            OfferStruct(
            owner=offer.owner,
            collection=collection,
            tokenId=tokenId,
            collateral=collateral,
            collateral_amount=collateral_amount,
            interest_rate=interest_rate,
            rent_time_min=rent_time_min,
            rent_time_max=rent_time_max,
            timestamp=offer.timestamp
            ),
            timestamp=timestamp,
            tax_fee=tax_fee,
        );

        Offer.remove_same(collection, tokenId);

        let (len) = add(rent);

        SafeERC20.safe_transfer_from(
            token=offer.collateral,
            sender=caller,
            recipient=contract_address,
            amount=offer.collateral_amount,
        );

        IERC721.transferFrom(
            contract_address=offer.collection, from_=offer.owner, to=caller, tokenId=offer.tokenId
        );

        return (len,);
    }

    func return_NFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt, collection: felt, tokenId: Uint256
    ) {
        alloc_locals;

        let (rent) = get(index);

        with_attr error_message("Rent: this rent no longer exists.") {
            assert rent.collection = collection;
            assert_uint256_eq(rent.tokenId, tokenId);
        }

        remove_by_index(index);

        return ();
    }

    //
    // View
    //

    func is_paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        res: felt
    ) {
        let (is_paused) = Rent_paused.read();
        return (is_paused,);
    }

    func get{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt) -> (
        res: RentStruct
    ) {
        with_attr error_message("Rent: index cannot be negative.") {
            assert_nn(index);
        }

        let (rent: RentStruct) = Rent_map.read(index);
        return (rent,);
    }

    func get_by_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        collection: felt, tokenId: Uint256
    ) -> (array_len: felt, array: IndexedRentStruct*) {
        alloc_locals;

        with_attr error_message("Rent: token Id is not valid.") {
            uint256_check(tokenId);
        }

        with_attr error_message("Rent: collection not whitelisted.") {
            let (is_whitelisted) = Collection._contains(collection);
            assert TRUE = is_whitelisted;
        }

        let (array: IndexedRentStruct*) = alloc();
        let (len) = Rent_len.read();
        let counter = _get_by_tokenId_recursive(array, 0, collection, tokenId, 0, len);

        return (counter, array);
    }

    func list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        offset: felt, limit: felt, collection: felt, owner: felt, inverse: felt
    ) -> (array_len: felt, array: IndexedRentStruct*) {
        alloc_locals;

        let (len) = Rent_len.read();

        with_attr error_message("Rent: offset cannot be negative.") {
            assert_nn(offset);
        }

        with_attr error_message("Rent: limit cannot be negative.") {
            assert_nn(limit);
        }

        with_attr error_message("Rent: collection not whitelisted.") {
            if (collection != 0) {
                let (is_whitelisted) = Collection._contains(collection);
                assert TRUE = is_whitelisted;
                tempvar syscall_ptr: felt* = syscall_ptr;
                tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                tempvar syscall_ptr: felt* = syscall_ptr;
                tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            }
        }

        let (array: IndexedRentStruct*) = alloc();

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

        let counter = _list_rent_recursive(
            array, start_at, max, collection, owner, inverse, 0, len
        );

        return (counter, array);
    }

    //
    // Internal
    //

    func _list_rent_recursive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        array: IndexedRentStruct*,
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

        let (rent) = Rent_map.read(index);

        if (collection == 0) {
            collection_check = TRUE;
        } else {
            if (collection == rent.offer.collection) {
                collection_check = TRUE;
            } else {
                collection_check = FALSE;
            }
        }

        if (owner == 0) {
            owner_check = TRUE;
        } else {
            if (owner == rent.owner) {
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
                assert [array] = IndexedRentStruct(index, rent);
                return _list_rent_recursive(
                    array + IndexedRentStruct.SIZE,
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

        return _list_rent_recursive(
            array, index + pointer, limit, collection, owner, inverse, counter, len - 1
        );
    }

    func _get_by_tokenId_recursive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        array: IndexedRentStruct*,
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

        let (rent) = Rent_map.read(index);

        if (collection == rent.offer.collection) {
            collection_check = TRUE;
        } else {
            collection_check = FALSE;
        }

        let (is_tokenId_eq) = uint256_eq(tokenId, rent.offer.tokenId);

        if (is_tokenId_eq == TRUE) {
            tokenId_check = TRUE;
        } else {
            tokenId_check = FALSE;
        }

        if (collection_check == TRUE) {
            if (tokenId_check == TRUE) {
                assert [array] = IndexedRentStruct(index, rent);
                return _get_by_tokenId_recursive(
                    array + IndexedRentStruct.SIZE,
                    index + 1,
                    collection,
                    tokenId,
                    counter + 1,
                    len - 1,
                );
            }
        }

        return _get_by_tokenId_recursive(array, index + 1, collection, tokenId, counter, len - 1);
    }
}
