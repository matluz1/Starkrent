%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_nn, assert_lt

//
// Events
//
@event
func LogCollectionAdded(address: felt) {
}

@event
func LogCollectionRemoved(address: felt) {
}

//
// Storage
//

@storage_var
func Collection_len() -> (len: felt) {
}

@storage_var
func Collection_map(index: felt) -> (address: felt) {
}

namespace Collection {
    //
    // Guards
    //

    func assert_is_whitelisted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        with_attr error_message("Collection: address is not whitelisted.") {
            let (collection_is_whitelisted) = _contains(address);
            assert TRUE = collection_is_whitelisted;
        }

        return ();
    }

    //
    // Mutative
    //

    func add{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (
        index: felt
    ) {
        with_attr error_message("Collection: address cannot be zero.") {
            assert_not_zero(address);
        }

        with_attr error_message("Collection: address already registered.") {
            let (registered) = _contains(address);
            assert FALSE = registered;
        }

        let (index) = Collection_len.read();

        Collection_map.write(index, address);

        Collection_len.write(index + 1);

        LogCollectionAdded.emit(address);

        return (index,);
    }

    func remove_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) {
        with_attr error_message("Collection: index cannot be negative.") {
            assert_nn(index);
        }

        let (len) = Collection_len.read();

        with_attr error_message("Collection: nothing to remove.") {
            assert_not_zero(len);
        }

        with_attr error_message("Collection: index need to be lesser than {len}.") {
            assert_lt(index, len);
        }
        let (address) = Collection_map.read(index);
        let last_index = len - 1;

        Collection_len.write(last_index);

        // If is the last index, just remove it
        if (index == last_index) {
            Collection_map.write(index, 0);
            return ();
        }

        // If not, replace removed index with last collection
        let (last_collection) = Collection_map.read(last_index);
        Collection_map.write(index, last_collection);
        Collection_map.write(last_index, 0);

        LogCollectionRemoved.emit(address);

        return ();
    }

    //
    // View
    //

    func list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        array_len: felt, array: felt*
    ) {
        alloc_locals;
        let (len) = Collection_len.read();
        let (array: felt*) = alloc();

        _list_collection_recursive(array, 0, len);

        return (len, array);
    }

    //
    // Internal
    //

    func _contains{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) -> (res: felt) {
        alloc_locals;
        let (len) = Collection_len.read();

        let has_needle = _check_contains_recursive(address, 0, len);

        return (has_needle,);
    }

    func _list_collection_recursive{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(array: felt*, index: felt, len: felt) {
        if (len == 0) {
            return ();
        }

        let (address) = Collection_map.read(index);
        assert [array] = address;

        return _list_collection_recursive(array + 1, index + 1, len - 1);
    }

    func _check_contains_recursive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        needle: felt, index: felt, len: felt
    ) -> felt {
        if (len == 0) {
            return FALSE;
        }

        let (address) = Collection_map.read(index);

        if (needle == address) {
            return TRUE;
        }

        return _check_contains_recursive(needle, index + 1, len - 1);
    }
}
