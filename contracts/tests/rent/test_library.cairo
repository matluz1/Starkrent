%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_lt
from starkware.cairo.common.uint256 import Uint256, uint256_check, assert_uint256_eq
from starkware.starknet.common.syscalls import get_block_timestamp, get_caller_address
from openzeppelin.access.ownable.library import Ownable_owner
from src.offer.library import Offer, OfferStruct, Offer_len
from src.collection.library import Collection

from src.rent.library import Rent, Rent_len, Rent_paused, Rent_config, TAX_FEE_MAX, RentStruct
from tests.utils import (
    OWNER,
    GUEST,
    NFT_OWNER,
    THIRD_PARTY_SC,
    COLLATERAL_FAKE,
    COLLECTION_FAKE,
    COLLECTION_FAKE_2,
    NFT_1,
    NFT_2,
    COLLATERAL_AMOUNT,
    INTEREST_RATE,
    RENT_TIME_MIN,
    RENT_TIME_MAX,
    Utils,
)

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    Rent.set_rent_config(TAX_FEE_MAX);

    Collection.add(COLLECTION_FAKE);
    Collection.add(COLLECTION_FAKE_2);

    let offer: OfferStruct = Utils._get_mocked_offer();
    Offer.add(offer);
    Offer.add(offer);
    Offer.add(offer);
    Offer.add(offer);
    Offer.add(offer);

    return ();
}

//
// set_rent_config
//
@external
func test_Rent_set_rent_config{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    // Act
    %{ expect_events({"name": "LogRentConfig", "data": [1]}) %}
    Rent.set_rent_config(1);
    let (fee) = Rent_config.read();
    assert 1 = fee;

    %{ expect_revert("TRANSACTION_FAILED", "Rent: invalid boundaries parameters.") %}
    Rent.set_rent_config(-10);

    %{ expect_revert("TRANSACTION_FAILED", "Rent: invalid boundaries parameters.") %}
    Rent.set_rent_config(2000);

    return ();
}

//
// pause_toggle
//
@external
func test_Rent_pause_toggle{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar next_status;

    // Prepare
    let (is_paused) = Rent.is_paused();

    if (is_paused == TRUE) {
        next_status = FALSE;
    } else {
        next_status = TRUE;
    }

    // Act
    %{ expect_events({"name": "LogRentPauseToggle", "data": [1]}) %}
    let (new_status) = Rent.pause_toggle();

    // Assert
    assert_not_equal(is_paused, new_status);

    return ();
}

//
// add
//
@external
func test_Rent_add{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    let (rent_len) = Rent_len.read();
    let (offer) = Offer.get(0);
    local rent: RentStruct = RentStruct(owner=OWNER, offer=offer, timestamp=0, tax_fee=500);

    // Act
    %{
        expect_events({"name": "LogRentCreated", "data": 
            [
               ids.OWNER, 
               ids.NFT_OWNER, 
               ids.COLLECTION_FAKE, 
               ids.NFT_1,0,
               ids.COLLATERAL_FAKE, 
               ids.COLLATERAL_AMOUNT, 0,
               ids.INTEREST_RATE,0, 
               ids.RENT_TIME_MIN,
               ids.RENT_TIME_MAX,
               0,
               0,
               500
            ]
        })
    %}
    let (rent_id) = Rent.add(rent);
    let (check_rent) = Rent.get(rent_id);
    let (new_rent_len) = Rent_len.read();

    // Assert
    assert rent_len + 1 = new_rent_len;

    return ();
}

@external
func test_Rent_cant_add_with_tax_fee_outside_boundaries{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    alloc_locals;
    let (offer) = Offer.get(0);
    local rent_amount_negative: RentStruct = RentStruct(owner=OWNER, offer=offer, timestamp=0, tax_fee=-100);
    local rent_amount_max: RentStruct = RentStruct(owner=OWNER, offer=offer, timestamp=0, tax_fee=600);

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Rent: tax fee outside boundaries.") %}
    Rent.add(rent_amount_negative);

    %{ expect_revert("TRANSACTION_FAILED", "Rent: tax fee outside boundaries.") %}
    Rent.add(rent_amount_max);

    return ();
}

//
// remove_by_index
//
@external
func test_Rent_remove_by_index{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    let (offer) = Offer.get(0);
    local rent: RentStruct = RentStruct(owner=OWNER, offer=offer, timestamp=0, tax_fee=500);
    let (rent_id) = Rent.add(rent);

    let diff_rent_struct = RentStruct(
        owner=GUEST,
        OfferStruct(
        owner=GUEST,
        collection=COLLECTION_FAKE,
        tokenId=Uint256(NFT_1, 0),
        collateral=COLLATERAL_FAKE,
        collateral_amount=Uint256(COLLATERAL_AMOUNT, 0),
        interest_rate=Uint256(INTEREST_RATE, 0),
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=123,
        ),
        timestamp=0,
        tax_fee=1000,
    );

    Rent.add(diff_rent_struct);
    let (len) = Rent_len.read();

    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Rent: index cannot be negative.") %}
    Rent.remove_by_index(-1);

    %{ expect_revert("TRANSACTION_FAILED", "Rent: index cannot be greater than {len}.") %}
    Rent.remove_by_index(len + 1);

    %{ expect_events({"name": "LogRentRemoved", "data": [ids.NFT_OWNER, ids.COLLECTION_FAKE, ids.NFT_1,0,ids.COLLATERAL_FAKE, ids.COLLATERAL_AMOUNT, 0,ids.INTEREST_RATE,0, ids.RENT_TIME_MIN,ids.RENT_TIME_MAX,0]}) %}
    Rent.remove_by_index(rent_id);
    let (after_len) = Rent_len.read();
    assert len - 1 = after_len;

    // Checking repositioning
    let (struct_after_rem) = Rent.get(rent_id);

    assert GUEST = struct_after_rem.owner;

    return ();
}

//
// list
//
@external
func test_Rent_list{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();

    local mock_other_collection: OfferStruct = OfferStruct(
        owner=mock.owner,
        collection=COLLECTION_FAKE_2,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=mock.timestamp,
        );

    // Act
    Rent.add(RentStruct(owner=OWNER, offer=mock_other_collection, timestamp=0, tax_fee=100));
    Rent.add(RentStruct(owner=OWNER, offer=mock, timestamp=0, tax_fee=200));
    Rent.add(RentStruct(owner=GUEST, offer=mock_other_collection, timestamp=0, tax_fee=300));
    Rent.add(RentStruct(owner=OWNER, offer=mock, timestamp=0, tax_fee=400));
    Rent.add(RentStruct(owner=OWNER, offer=mock, timestamp=0, tax_fee=500));

    let (rent_len) = Rent_len.read();

    // Assert

    // Get all
    let (len, rents) = Rent.list(0, 0, 0, 0, 0);

    assert len = rent_len;

    assert OWNER = rents[0].rent.owner;
    assert COLLECTION_FAKE_2 = rents[0].rent.offer.collection;
    assert 100 = rents[0].rent.tax_fee;

    assert OWNER = rents[1].rent.owner;
    assert mock.collection = rents[1].rent.offer.collection;
    assert 200 = rents[1].rent.tax_fee;

    // Only collection X
    let (len2, rents2) = Rent.list(0, rent_len, COLLECTION_FAKE_2, 0, 0);

    assert len2 = 2;
    assert OWNER = rents2[0].rent.owner;
    assert COLLECTION_FAKE_2 = rents2[0].rent.offer.collection;
    assert 100 = rents2[0].rent.tax_fee;

    assert GUEST = rents2[1].rent.owner;
    assert COLLECTION_FAKE_2 = rents2[1].rent.offer.collection;
    assert 300 = rents2[1].rent.tax_fee;

    // Only collection X and Owner Y
    let (len3, rents3) = Rent.list(0, rent_len, COLLECTION_FAKE_2, GUEST, 0);

    assert len3 = 1;
    assert GUEST = rents3[0].rent.owner;
    assert COLLECTION_FAKE_2 = rents3[0].rent.offer.collection;
    assert 300 = rents3[0].rent.tax_fee;

    // All limited by 2
    let (len4, rents4) = Rent.list(0, 2, 0, 0, 0);
    assert len4 = 2;

    // Check limit boundaries
    let (len5, rents5) = Rent.list(0, 100, 0, 0, 0);
    assert len5 = 5;

    // Check boundaries
    %{ expect_revert("TRANSACTION_FAILED", "Rent: limit cannot be negative.") %}
    let (len6, rents6) = Rent.list(0, -1, -1, 0, 0);

    %{ expect_revert("TRANSACTION_FAILED", "Rent: offset cannot be negative.") %}
    let (len7, rents7) = Rent.list(0, -1, -1, 0, 0);

    // Check offset
    let (len8, rents8) = Rent.list(3, 3, 0, 0, 0);
    assert 2 = len8;

    // Check inverse
    let (len9, rents9) = Rent.list(0, 2, 0, 0, 1);
    assert 2 = len9;

    assert 500 = rents9[0].rent.tax_fee;
    assert 400 = rents9[1].rent.tax_fee;

    return ();
}

//
// get_by_tokenId
//
@external
func test_Rent_get_by_tokenId{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();

    local mock_other_collection: OfferStruct = OfferStruct(
        owner=mock.owner,
        collection=COLLECTION_FAKE_2,
        tokenId=Uint256(NFT_2, 0),
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=mock.timestamp,
        );

    // Act
    Rent.add(RentStruct(owner=OWNER, offer=mock_other_collection, timestamp=0, tax_fee=100));
    Rent.add(RentStruct(owner=OWNER, offer=mock, timestamp=0, tax_fee=200));
    Rent.add(RentStruct(owner=GUEST, offer=mock_other_collection, timestamp=0, tax_fee=300));
    Rent.add(RentStruct(owner=OWNER, offer=mock, timestamp=0, tax_fee=400));
    Rent.add(RentStruct(owner=OWNER, offer=mock, timestamp=0, tax_fee=500));

    // Assert

    let (len, rents) = Rent.get_by_token_id(COLLECTION_FAKE_2, Uint256(NFT_2, 0));

    assert 2 = len;
    assert GUEST = rents[1].rent.owner;
    assert mock_other_collection.collection = rents[1].rent.offer.collection;
    assert 300 = rents[1].rent.tax_fee;

    let (len2, rents2) = Rent.get_by_token_id(COLLECTION_FAKE, Uint256(NFT_1, 0));

    assert 3 = len2;

    return ();
}

//
// register
//
@external
func test_Rent_cant_register_when_offer_no_long_exists{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();
    let (offer_id) = Offer.add(mock);

    local mock_other_collection: OfferStruct = OfferStruct(
        owner=mock.owner,
        collection=COLLECTION_FAKE_2,
        tokenId=Uint256(NFT_2, 0),
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=mock.timestamp,
        );

    Offer.add(mock_other_collection);
    Offer.remove_by_index(offer_id);

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Rent: this offer no longer exists.") %}
    Rent.register(
        index=offer_id,
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
        timestamp=mock.timestamp,
    );

    return ();
}

@external
func test_Rent_cant_register_when_caller_is_offer_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();
    let (offer_id) = Offer.add(mock);
    %{
        stop_prank = start_prank(ids.NFT_OWNER) 
        expect_revert("TRANSACTION_FAILED", "Rent: caller cannot be the offer owner.")
    %}
    Rent.register(
        index=offer_id,
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
        timestamp=mock.timestamp,
    );
    %{ stop_prank() %}
    return ();
}

@external
func test_Rent_register{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    local mock: OfferStruct = OfferStruct(
        owner=NFT_OWNER,
        collection=COLLECTION_FAKE,
        tokenId=Uint256(NFT_2, 0),
        collateral=COLLATERAL_FAKE,
        collateral_amount=Uint256(COLLATERAL_AMOUNT, 0),
        interest_rate=Uint256(INTEREST_RATE, 0),
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=0,
        );
    let (offer_id) = Offer.add(mock);
    Offer.add(mock);
    Offer.add(mock);

    let (offer_len) = Offer_len.read();
    let (rent_len) = Rent_len.read();

    // Simulating multiple offers to be removed on rent

    %{
        stop_prank = start_prank(ids.GUEST)
        stop_mock = mock_call(ids.mock.collateral, "transferFrom", [1])
        stop_mock = mock_call(ids.mock.collection, "transferFrom", [0])
        expect_events({"name": "LogRentCreated", "data": 
            [
                ids.GUEST,
                ids.NFT_OWNER, 
                ids.COLLECTION_FAKE, 
                ids.NFT_2,0,
                ids.COLLATERAL_FAKE, 
                ids.COLLATERAL_AMOUNT, 0,
                ids.INTEREST_RATE,0, 
                ids.RENT_TIME_MIN,
                ids.RENT_TIME_MAX,
                0,
                0,
                ids.TAX_FEE_MAX
            ]
        })
    %}
    Rent.register(
        index=offer_id,
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
        timestamp=mock.timestamp,
    );

    let (new_offer_len) = Offer_len.read();
    let (new_rent_len) = Rent_len.read();

    // 3 = Removing all 3 offers
    assert (offer_len - 3) = new_offer_len;
    assert (rent_len + 1) = new_rent_len;

    let (len, offers) = Offer.get_by_token_id(mock.collection, mock.tokenId);
    assert 0 = len;

    %{
        stop_prank() 
        stop_mock()
    %}

    return ();
}

//
// return_NFT
//
@external
func test_Rent_return_NFT{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();
    let (offer_id) = Offer.add(mock);
    let (offer_len) = Offer_len.read();
    let (rent_len) = Rent_len.read();

    %{
        stop_prank = start_prank(ids.GUEST)
        stop_mock = mock_call(ids.mock.collateral, "transferFrom", [1])
        stop_mock = mock_call(ids.mock.collection, "transferFrom", [0])
        expect_events({"name": "LogRentCreated", "data":
            [
                ids.GUEST,
                ids.NFT_OWNER,
                ids.COLLECTION_FAKE,
                ids.NFT_1,0,
                ids.COLLATERAL_FAKE,
                ids.COLLATERAL_AMOUNT, 0,
                ids.INTEREST_RATE,0,
                ids.RENT_TIME_MIN,
                ids.RENT_TIME_MAX,
                0,
                0,
                ids.TAX_FEE_MAX
            ]
        })
    %}
    Rent.register(
        index=offer_id,
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
        timestamp=mock.timestamp,
    );

    let (new_offer_len) = Offer_len.read();
    let (new_rent_len) = Rent_len.read();

    assert (offer_len - 1) = new_offer_len;
    assert (rent_len + 1) = new_rent_len;

    %{
        stop_prank()
        stop_mock()
    %}

    return ();
}
