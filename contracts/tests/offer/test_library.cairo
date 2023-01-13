%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_lt
from starkware.cairo.common.uint256 import Uint256, uint256_check, assert_uint256_eq

from openzeppelin.access.ownable.library import Ownable_owner

from src.collateral.library import Collateral
from src.collection.library import Collection
from src.offer.library import (
    COLLATERAL_AMOUNT_MAX,
    Offer,
    Offer_len,
    Offer_paused,
    Offer_config,
    OfferConfigStruct,
    OfferStruct,
)

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
    RENT_TIME_MIN,
    RENT_TIME_MAX,
    INTEREST_RATE,
    Utils,
)

const LIMIT_SAME_NFT_OFFER = 3;

func _add_mocked_offers{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    len: felt
) {
    if (len == 0) {
        return ();
    }

    let mock = Utils._get_mocked_offer();
    Offer.add(mock);

    return _add_mocked_offers(len - 1);
}

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    Collection.add(COLLECTION_FAKE);
    Collection.add(COLLECTION_FAKE_2);
    Collateral.add(COLLATERAL_FAKE);
    Offer.set_offer_config(RENT_TIME_MIN, RENT_TIME_MAX, LIMIT_SAME_NFT_OFFER);

    return ();
}

//
// set_offer_config
//
@external
func test_Offer_set_offer_config{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    alloc_locals;

    // Act
    %{ expect_events({"name": "LogOfferConfig", "data": [1,20,3]}) %}
    Offer.set_offer_config(1, 20, 3);

    // Assert
    let (config: OfferConfigStruct) = Offer_config.read();
    assert config = OfferConfigStruct(1, 20, 3);

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Offer: invalid boundaries parameters.") %}
    Offer.set_offer_config(-10, -20, 0);

    // Act
    Offer.set_offer_config(5, 5, 3);

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Offer: invalid boundaries parameters.") %}
    Offer.set_offer_config(10, 5, 3);

    return ();
}

//
// pause_toggle
//
@external
func test_Offer_pause_toggle{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local next_status;

    // Prepare
    let (is_paused) = Offer.is_paused();

    if (is_paused == TRUE) {
        next_status = FALSE;
    } else {
        next_status = TRUE;
    }

    // Act
    %{ expect_events({"name": "LogOfferPauseToggle", "data": [ids.next_status]}) %}
    let (new_status) = Offer.pause_toggle();

    // Assert
    assert_not_equal(is_paused, new_status);

    return ();
}

//
// add
//
@external
func test_Offer_add{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    let (offer_len) = Offer_len.read();
    let mock = Utils._get_mocked_offer();

    // Act
    %{ expect_events({"name": "LogOfferCreated", "data": [ids.NFT_OWNER, ids.COLLECTION_FAKE, ids.NFT_1, 0,ids.COLLATERAL_FAKE, ids.COLLATERAL_AMOUNT, 0, ids.INTEREST_RATE, 0, ids.RENT_TIME_MIN,ids.RENT_TIME_MAX,0]}) %}
    let (offer_id) = Offer.add(mock);
    let (check_offer) = Offer.get(offer_id);
    let (new_offer_len) = Offer_len.read();

    // Assert
    assert offer_len + 1 = new_offer_len;
    assert mock = check_offer;

    return ();
}

//
// register
//
@external
func test_Offer_cant_register_with_collateral_amount_outside_boundaries{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Collateral: amount outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=Uint256(0, 0),
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Collateral: amount outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=Uint256(COLLATERAL_AMOUNT_MAX, 0),
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Collateral: amount outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=Uint256(-100000, 0),
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    return ();
}

@external
func test_Offer_cant_register_with_overflow_tokenId{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    let mock = Utils._get_mocked_offer();

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Offer: token Id is not valid.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=Uint256(2 ** 257, 0),
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    return ();
}

@external
func test_Offer_cant_register_with_invalid_collection{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    let mock = Utils._get_mocked_offer();

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Collection: address is not whitelisted.") %}
    Offer.register(
        collection=0x99999,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    %{ stop_mock() %}

    return ();
}

@external
func test_Offer_cant_register_with_invalid_collateral{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    let mock = Utils._get_mocked_offer();

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Collateral: address is not whitelisted.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=0x99999,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    %{ stop_mock() %}

    return ();
}

@external
func test_Offer_cant_register_with_interest_rate_outside_boundaries{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    alloc_locals;
    let mock = Utils._get_mocked_offer();

    // Act
    %{ stop_mock = mock_call(ids.mock.collection, "ownerOf", [0]) %}
    let (offer1) = Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );
    assert 0 = offer1;

    %{ expect_revert("TRANSACTION_FAILED", "Offer: rent time max exceeds interest rate distribution.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=Uint256(1 * 10 ** 10, 0),
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=20,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Offer: interest rate outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=Uint256(0, 0),
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Offer: interest rate outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=Uint256(2 * 10 ** 18, 0),
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Offer: interest rate outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=Uint256((-2) * 10 ** 17, 0),
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    return ();
}

@external
func test_Offer_cant_register_with_rent_time_outside_boundaries{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;
    // Prepare
    let mock = Utils._get_mocked_offer();

    // Act
    %{ expect_revert("TRANSACTION_FAILED", "Offer: rent time outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=RENT_TIME_MIN - 1,
        rent_time_max=mock.rent_time_max,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Offer: rent time outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=RENT_TIME_MAX + 1,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Offer: rent time outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=-1,
        rent_time_max=RENT_TIME_MAX,
    );

    %{ expect_revert("TRANSACTION_FAILED", "Offer: rent time outside boundaries.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=-1,
    );

    return ();
}

@external
func test_Offer_cant_register_more_times_than_limited_by_tokenId{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    // LIMIT_SAME_NFT_OFFER = 3
    alloc_locals;

    let mock = Utils._get_mocked_offer();
    %{ stop_mock = mock_call(ids.mock.collection, "ownerOf", [0]) %}
    // Act
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    // Assert
    %{ expect_revert("TRANSACTION_FAILED", "Offer: offers of same NFT maxed out.") %}
    Offer.register(
        collection=mock.collection,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=mock.interest_rate,
        rent_time_min=mock.rent_time_min,
        rent_time_max=mock.rent_time_max,
    );

    %{ stop_mock() %}
    return ();
}

//
// remove_by_index
//
@external
func test_Offer_remove_by_index{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;
    let offer = Utils._get_mocked_offer();
    let (offer_id) = Offer.add(offer);

    let diff_offer_struct = OfferStruct(
        owner=GUEST,
        collection=COLLECTION_FAKE,
        tokenId=Uint256(NFT_1, 0),
        collateral=COLLATERAL_FAKE,
        collateral_amount=Uint256(COLLATERAL_AMOUNT, 0),
        interest_rate=Uint256(INTEREST_RATE, 0),
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=123,
    );

    Offer.add(diff_offer_struct);
    let (len) = Offer_len.read();

    // Act & Assert
    %{ expect_revert("TRANSACTION_FAILED", "Offer: index cannot be negative.") %}
    Offer.remove_by_index(-1);

    %{ expect_revert("TRANSACTION_FAILED", "Offer: index cannot be greater than {len}.") %}
    Offer.remove_by_index(len + 1);

    %{ expect_events({"name": "LogOfferRemoved", "data": [ids.NFT_OWNER, ids.COLLECTION_FAKE, ids.NFT_1,0,ids.COLLATERAL_FAKE, ids.COLLATERAL_AMOUNT, 0,ids.INTEREST_RATE, ids.RENT_TIME_MIN,ids.RENT_TIME_MAX,0]}) %}
    Offer.remove_by_index(offer_id);
    let (after_len) = Offer_len.read();
    assert len - 1 = after_len;

    // Checking repositioning
    let (struct_after_rem) = Offer.get(offer_id);

    assert GUEST = struct_after_rem.owner;

    return ();
}

//
// remove_all
//
@external
func test_Offer_remove_all{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;
    let mock = Utils._get_mocked_offer();

    local mock_other_collection: OfferStruct = OfferStruct(
        owner=mock.owner,
        collection=COLLECTION_FAKE_2,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=Uint256(COLLATERAL_AMOUNT - 1, 0),
        interest_rate=mock.interest_rate,
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=mock.timestamp,
        );

    local mock_other_collection_other_owner: OfferStruct = OfferStruct(
        owner=GUEST,
        collection=COLLECTION_FAKE_2,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=Uint256(COLLATERAL_AMOUNT - 2, 0),
        interest_rate=mock.interest_rate,
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=mock.timestamp,
        );

    _add_mocked_offers(len=10);
    Offer.add(mock_other_collection_other_owner);
    Offer.add(mock_other_collection);
    let (len) = Offer_len.read();

    // Act & Assert
    assert 12 = len;

    // Remove other owner
    %{ expect_events({"name": "LogOfferRemoved", "data": [ids.GUEST, ids.COLLECTION_FAKE_2, ids.NFT_1,0,ids.COLLATERAL_FAKE, ids.COLLATERAL_AMOUNT - 2, 0,ids.INTEREST_RATE,0, ids.RENT_TIME_MIN,ids.RENT_TIME_MAX,0]}) %}
    let counter1 = Offer.remove_all(0, GUEST);
    assert 1 = counter1;
    let (len_check, collection_check) = Offer.list(0, len, COLLECTION_FAKE_2, 0, 0);
    assert 1 = len_check;
    assert collection_check.offer.owner = mock.owner;

    // Remove other collection
    let counter2 = Offer.remove_all(COLLECTION_FAKE_2, 0);
    assert 1 = counter2;

    // Remove all
    let counter3 = Offer.remove_all(0, 0);
    assert 10 = counter3;

    return ();
}

//
// _get_length_recursive_by_collection_and_token_id
//
@external
func test_Offer__get_length_recursive_by_collection_and_token_id{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();

    local mock_other_collection: OfferStruct = OfferStruct(
        owner=mock.owner,
        collection=COLLECTION_FAKE_2,
        tokenId=mock.tokenId,
        collateral=mock.collateral,
        collateral_amount=mock.collateral_amount,
        interest_rate=Uint256(INTEREST_RATE, 0),
        rent_time_min=RENT_TIME_MIN,
        rent_time_max=RENT_TIME_MAX,
        timestamp=mock.timestamp,
        );

    // Act
    let (id) = Offer.add(mock);
    Offer.add(mock);
    Offer.add(mock);
    Offer.add(mock_other_collection);

    let (offer_len) = Offer_len.read();

    let len = Offer._get_length_recursive_by_collection_and_token_id(
        mock.collection, mock.tokenId, 0, offer_len, 0
    );

    // Assert
    len = 3;

    return ();
}

//
// list
//
@external
func test_Offer_list{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
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

    local mock_other_collection_other_owner: OfferStruct = OfferStruct(
        owner=GUEST,
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
    _add_mocked_offers(3);
    Offer.add(mock_other_collection);
    Offer.add(mock_other_collection_other_owner);

    let (offer_len) = Offer_len.read();

    // Assert

    // Get all
    let (len, offers) = Offer.list(0, 0, 0, 0, 0);

    assert len = offer_len;
    assert mock = offers[0].offer;

    assert mock_other_collection_other_owner = offers[4].offer;

    // Only collection X
    let (len2, offers2) = Offer.list(0, offer_len, COLLECTION_FAKE_2, 0, 0);

    assert len2 = 2;
    assert mock_other_collection = offers2[0].offer;

    assert mock_other_collection_other_owner = offers2[1].offer;

    // Only collection X and Owner Y
    let (len3, offers3) = Offer.list(0, offer_len, COLLECTION_FAKE_2, GUEST, 0);

    assert len3 = 1;
    assert mock_other_collection_other_owner = offers3[0].offer;

    // All limited by 2
    let (len4, offers4) = Offer.list(0, 2, 0, 0, 0);
    assert len4 = 2;

    // Check limit boundaries
    let (len5, offers5) = Offer.list(0, 10, 0, 0, 0);
    assert len5 = 5;

    // Check boundaries
    %{ expect_revert("TRANSACTION_FAILED", "Offer: limit cannot be negative.") %}
    let (len6, offers6) = Offer.list(0, -1, -1, 0, 0);

    %{ expect_revert("TRANSACTION_FAILED", "Offer: offset cannot be negative.") %}
    let (len7, offers7) = Offer.list(0, -1, -1, 0, 0);

    // Check offset
    let (len8, offers8) = Offer.list(3, 3, 0, 0, 0);
    assert 2 = len8;

    // Check inverse
    let (len9, offers9) = Offer.list(0, 2, 0, 0, 1);
    assert 2 = len9;
    assert mock_other_collection_other_owner = offers9[0].offer;
    assert mock_other_collection = offers9[1].offer;

    return ();
}

//
// list
//
@external
func test_Offer_get_by_tokenId{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    // Prepare
    alloc_locals;

    let mock = Utils._get_mocked_offer();

    local mock_tokenId_1: OfferStruct = OfferStruct(
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

    local mock_tokenId_2: OfferStruct = OfferStruct(
        owner=GUEST,
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
    _add_mocked_offers(30);
    Offer.add(mock_tokenId_1);
    Offer.add(mock_tokenId_2);
    Offer.add(mock_tokenId_2);

    // Assert

    let (len, offers) = Offer.get_by_token_id(COLLECTION_FAKE_2, Uint256(NFT_2, 0));

    assert 2 = len;
    assert mock_tokenId_2 = offers[0].offer;
    assert mock_tokenId_2 = offers[1].offer;

    let (len2, offers2) = Offer.get_by_token_id(COLLECTION_FAKE, Uint256(NFT_1, 0));

    assert 30 = len2;

    return ();
}
