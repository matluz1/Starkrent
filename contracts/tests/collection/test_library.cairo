%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.collection.library import Collection, Collection_len, Collection_map

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    Collection.add(0x111);
    Collection.add(0x222);
    Collection.add(0x333);

    return ();
}

//
// add
//
@external
func test_Collection_add{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    // Prep
    let address = 0x0123;
    let (initial_collection_len) = Collection_len.read();

    // Act
     %{ expect_events({"name": "LogCollectionAdded", "data": [ids.address]}) %}
    Collection.add(address);

    // Assert
    let (check_collection_len) = Collection_len.read();
    assert initial_collection_len + 1 = check_collection_len;

    let (last_collection) = Collection_map.read(initial_collection_len);
    assert address = last_collection;

    return ();
}

@external
func test_Collection_add_with_zero_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Act & assert
    %{ expect_revert("TRANSACTION_FAILED", "Collection: address cannot be zero.") %}
    Collection.add(0x0);

    return ();
}

@external
func test_Collection_add_with_already_registered{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Act & assert
    %{ expect_revert("TRANSACTION_FAILED", "Collection: address already registered.") %}
    Collection.add(0x111);

    return ();
}

// 
// remove_by_index
// 
@external
func test_Collection_remove_by_index{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    // Prep
    let (initial_len) = Collection_len.read();

    let (address_to_check) = Collection_map.read(initial_len - 1);
    let index_to_remove = initial_len - 2;
    let (address_removed) = Collection_map.read(index_to_remove);

    // Act
    %{ expect_events({"name": "LogCollectionRemoved", "data": [ids.address_removed]}) %}
    Collection.remove_by_index(index_to_remove);

    // Assert
    let (len) = Collection_len.read();
    assert initial_len - 1 = len;
    // Check if last address gonna replace removed index
    let (check_collection) = Collection_map.read(index_to_remove);

    assert address_to_check = check_collection;

    return ();
}

@external
func test_Collection_remove_by_index_with_negative_index{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Collection: index cannot be negative.") %}
    Collection.remove_by_index(-1);

    return ();
}

@external
func test_Collection_remove_by_index_with_overflow_index{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    let (len) = Collection_len.read();

    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Collection: index need to be lesser than {len}.") %}
    Collection.remove_by_index(len);

    return ();
}

@external
func test_Collection_remove_by_index_empty{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    Collection.remove_by_index(0);
    Collection.remove_by_index(0);
    Collection.remove_by_index(0);

    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Collection: nothing to remove.") %}
    Collection.remove_by_index(0);

    return ();
}

// 
// list
// 
@external
func test_Collection_list{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    let (check_len) = Collection_len.read();

    // Act
    let (len, list) = Collection.list();

    // Assert
    assert check_len = len;
    assert 0x111 = list[0];
    assert 0x222 = list[1];
    assert 0x333 = list[2];

    return ();
}

//
// _contains
//
@external
func test_Collection__contains{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    // Act
    let (check_contains_true) = Collection._contains(0x111);
    let (check_contains_true_last) = Collection._contains(0x333);
    let (check_contains_false) = Collection._contains(0x999);

    // Assert
    assert TRUE = check_contains_true;
    assert TRUE = check_contains_true_last;
    assert FALSE = check_contains_false;

    return ();
}
