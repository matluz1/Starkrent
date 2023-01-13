%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_nn, assert_lt
from starkware.cairo.common.uint256 import (
    Uint256,
    assert_uint256_le,
    assert_uint256_lt,
    uint256_check,
)

from openzeppelin.token.erc20.IERC20 import IERC20

const COLLATERAL_AMOUNT_MAX = 2 ** 128 - 1;

//
// Events
//
@event
func LogCollateralAdded(address: felt) {
}

@event
func LogCollateralRemoved(address: felt) {
}

//
// Storage
//

@storage_var
func Collateral_len() -> (len: felt) {
}

@storage_var
func Collateral_map(index: felt) -> (address: felt) {
}

namespace Collateral {
    //
    // Guards
    //

    func assert_is_whitelisted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        with_attr error_message("Collateral: address is not whitelisted.") {
            let (collateral_is_whitelisted) = _contains(address);
            assert TRUE = collateral_is_whitelisted;
        }

        return ();
    }

    func assert_amount_is_valid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        amount: Uint256
    ) {
        with_attr error_message("Collateral: amount outside boundaries.") {
            uint256_check(amount);
            assert_uint256_le(amount, Uint256(COLLATERAL_AMOUNT_MAX, 0));
            assert_uint256_lt(Uint256(0, 0), amount);
        }

        return ();
    }

    //
    // Mutative
    //

    func add{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (
        index: felt
    ) {
        with_attr error_message("Collateral: address cannot be zero.") {
            assert_not_zero(address);
        }

        with_attr error_message("Collateral: address already registered.") {
            let (registered) = _contains(address);
            assert FALSE = registered;
        }

        let (index) = Collateral_len.read();

        Collateral_map.write(index, address);

        Collateral_len.write(index + 1);

        LogCollateralAdded.emit(address);

        return (index,);
    }

    func remove_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) {
        with_attr error_message("Collateral: index cannot be negative.") {
            assert_nn(index);
        }

        let (len) = Collateral_len.read();

        with_attr error_message("Collateral: nothing to remove.") {
            assert_not_zero(len);
        }

        with_attr error_message("Collateral: index need to be lesser than {len}.") {
            assert_lt(index, len);
        }

        let (address) = Collateral_map.read(index);
        let last_index = len - 1;

        Collateral_len.write(last_index);

        // If is the last index, just remove it
        if (index == last_index) {
            Collateral_map.write(index, 0);
            return ();
        }

        // If not, replace removed index with last collateral
        let (last_collateral) = Collateral_map.read(last_index);
        Collateral_map.write(index, last_collateral);
        Collateral_map.write(last_index, 0);

        LogCollateralRemoved.emit(address);

        return ();
    }

    //
    // View
    //

    func list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        array_len: felt, array: felt*
    ) {
        alloc_locals;
        let (len) = Collateral_len.read();
        let (array: felt*) = alloc();

        _list_collateral_recursive(array, 0, len);

        return (len, array);
    }

    //
    // Internal
    //

    func _contains{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) -> (res: felt) {
        alloc_locals;
        let (len) = Collateral_len.read();

        let has_needle = _check_contains_recursive(address, 0, len);

        return (has_needle,);
    }

    func _list_collateral_recursive{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(array: felt*, index: felt, len: felt) {
        if (len == 0) {
            return ();
        }

        let (address) = Collateral_map.read(index);
        assert [array] = address;

        return _list_collateral_recursive(array + 1, index + 1, len - 1);
    }

    func _check_contains_recursive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        needle: felt, index: felt, len: felt
    ) -> felt {
        if (len == 0) {
            return FALSE;
        }

        let (address) = Collateral_map.read(index);

        if (needle == address) {
            return TRUE;
        }

        return _check_contains_recursive(needle, index + 1, len - 1);
    }
}
