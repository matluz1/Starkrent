%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import assert_uint256_eq

from src.collateral.library import Collateral, Collateral_len, Collateral_map

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    Collateral.add(111);
    Collateral.add(222);
    Collateral.add(333);

    return ();
}

//
// add
//
@external
func test_Collateral_add{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    // Prep
    let address = 0x0123;
    let (initial_collateral_len) = Collateral_len.read();

    // Act
    %{ expect_events({"name": "LogCollateralAdded", "data": [ids.address]}) %}
    Collateral.add(address);

    // Assert
    let (check_collateral_len) = Collateral_len.read();

    assert initial_collateral_len + 1 = check_collateral_len;

    let (last_collateral) = Collateral_map.read(initial_collateral_len);

    assert address = last_collateral;

    return ();
}

@external
func test_Collateral_add_with_zero_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Act & assert
    %{ expect_revert("TRANSACTION_FAILED", "Collateral: address cannot be zero.") %}
    Collateral.add(0x0);

    return ();
}

@external
func test_Collateral_add_with_already_registered{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Act & assert
    %{ expect_revert("TRANSACTION_FAILED", "Collateral: address already registered.") %}
    Collateral.add(111);

    return ();
}

// 
// remove_by_index
// 
@external
func test_Collateral_remove_by_index{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    // Prep
    let (initial_len) = Collateral_len.read();

    let (address_to_check) = Collateral_map.read(initial_len - 1);
    let index_to_remove = initial_len - 2;
    let (address_removed) = Collateral_map.read(index_to_remove);

    // Act
    %{ expect_events({"name": "LogCollateralRemoved", "data": [ids.address_removed]}) %}
    Collateral.remove_by_index(index_to_remove);

    // Assert
    let (len) = Collateral_len.read();
    assert initial_len - 1 = len;

    // Check if last address gonna replace removed index
    let (check_collateral) = Collateral_map.read(index_to_remove);
    assert address_to_check = check_collateral;

    return ();
}

@external
func test_Collateral_remove_by_index_with_negative_index{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Collateral: index cannot be negative.") %}
    Collateral.remove_by_index(-1);

    return ();
}

@external
func test_Collateral_remove_by_index_with_overflow_index{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    let (len) = Collateral_len.read();

    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Collateral: index need to be lesser than {len}.") %}
    Collateral.remove_by_index(len);

    return ();
}

@external
func test_Collateral_remove_by_index_empty{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    Collateral.remove_by_index(0);
    Collateral.remove_by_index(0);
    Collateral.remove_by_index(0);

    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Collateral: nothing to remove.") %}
    Collateral.remove_by_index(0);

    return ();
}

// 
// list
// 
@external
func test_Collateral_list{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    let (check_len) = Collateral_len.read();

    // Act
    let (len, list) = Collateral.list();

    // Assert
    assert check_len = len;
    assert 111 = list[0];
    assert 222 = list[1];
    assert 333 = list[2];

    return ();
}

// 
// _contains
// 
@external
func test_Collateral_contains{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    // Act
    let (check_contains_true) = Collateral._contains(111);
    let (check_contains_true_last) = Collateral._contains(333);
    let (check_contains_false) = Collateral._contains(0x999);

    // Assert
    assert TRUE = check_contains_true;
    assert TRUE = check_contains_true_last;
    assert FALSE = check_contains_false;

    return ();
}
