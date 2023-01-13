%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from src.INFTRental import INFTRental

from tests.utils import (
    OWNER,
    GUEST,
    NFT_OWNER,
    THIRD_PARTY_SC,
    COLLATERAL_FAKE,
    COLLECTION_FAKE,
    NFT_1,
    NFT_2,
)
from tests.interfaces.IERC721MintableBurnable import IERC721MintableBurnable

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    local contract_address;
    local collection_address;
    local collateral_address;

    %{
        stop_prank = start_prank(ids.THIRD_PARTY_SC)          
        context.collateral_address = deploy_contract("lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo",
            {
                "name": "Coin Token",
                "symbol": "CTK",
                "decimals": 18,
                "initial_supply": 1000 *10 **18,
                "recipient": ids.THIRD_PARTY_SC
            }
        ).contract_address

        context.collection_address = deploy_contract("lib/cairo_contracts/src/openzeppelin/token/erc721/presets/ERC721MintableBurnable.cairo",
            {
                "name": "Meme NFT",
                "symbol": "MM",
                "owner": ids.THIRD_PARTY_SC
            }
        ).contract_address

        stop_prank()
        stop_prank = start_prank(ids.OWNER)    

        context.contract_address = deploy_contract("src/NFTRental.cairo",
            {
                "limit_rent_min_time": 1,
                "limit_rent_max_time": 30,
                "limit_same_nft_offer": 3,
                "tax_fee": 5,
                "owner": ids.OWNER
            }
        ).contract_address

        ids.contract_address = context.contract_address
        ids.collection_address = context.collection_address 
        ids.collateral_address = context.collateral_address

        stop_prank()
    %}

    %{ stop_prank = start_prank(ids.THIRD_PARTY_SC, context.collection_address) %}
    IERC721MintableBurnable.mint(collection_address, NFT_OWNER, Uint256(NFT_1, 0));
    IERC721MintableBurnable.mint(collection_address, GUEST, Uint256(NFT_2, 0));
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.THIRD_PARTY_SC, context.collateral_address) %}
    IERC20.transfer(collateral_address, GUEST, Uint256(100 * 10 ** 18, 0));
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    let (index) = INFTRental.addCollection(
        contract_address=contract_address, address=collection_address
    );
    let (index) = INFTRental.addCollection(
        contract_address=contract_address, address=COLLECTION_FAKE
    );
    let (index) = INFTRental.addCollateral(
        contract_address=contract_address, address=collateral_address
    );
    let (index) = INFTRental.addCollateral(
        contract_address=contract_address, address=COLLATERAL_FAKE
    );
    %{ stop_prank() %}

    return ();
}

//
// Utils
//

func _bind_address() -> (
    contract_address: felt, collection_address: felt, collateral_address: felt
) {
    alloc_locals;

    local contract_address;
    local collection_address;
    local collateral_address;

    %{
        ids.contract_address = context.contract_address
        ids.collection_address = context.collection_address
        ids.collateral_address = context.collateral_address
    %}

    return (contract_address, collection_address, collateral_address);
}

func _approve_before_offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    ) {
    let (contract_address, collection_address, collateral_address) = _bind_address();

    %{ stop_prank = start_prank(ids.NFT_OWNER, context.collection_address) %}
    IERC721.approve(
        contract_address=collection_address, approved=contract_address, tokenId=Uint256(NFT_1, 0)
    );
    %{ stop_prank() %}

    return ();
}

func _make_an_offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    index: felt
) {
    let (contract_address, collection_address, collateral_address) = _bind_address();
    %{ stop_prank = start_prank(ids.NFT_OWNER, context.contract_address) %}
    let (index) = INFTRental.offer(
        contract_address=contract_address,
        collection=collection_address,
        tokenId=Uint256(NFT_1, 0),
        collateral=collateral_address,
        collateral_amount=Uint256(10 * 10 ** 18, 0),
        interest_rate=Uint256(1 * 10 ** 17, 0),
        rent_time_min=10,
        rent_time_max=30,
    );
    %{ stop_prank() %}

    return (index,);
}

//
// listCollections
//
@external
func test_listCollections{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, collection_address, _) = _bind_address();

    let (len, collections) = INFTRental.listCollections(contract_address=contract_address);

    assert 2 = len;
    assert collections[0] = collection_address;
    assert collections[1] = COLLECTION_FAKE;

    return ();
}

//
// listCollaterals
//
@external
func test_listCollaterals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, _, collateral_address) = _bind_address();

    let (len, collaterals) = INFTRental.listCollaterals(contract_address=contract_address);

    assert 2 = len;
    assert collaterals[0] = collateral_address;
    assert collaterals[1] = COLLATERAL_FAKE;

    return ();
}

//
// listOffers
//
@external
func test_listOffers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, _, collateral_address) = _bind_address();

    _approve_before_offer();
    _make_an_offer();
    _make_an_offer();
    _make_an_offer();

    let (len, offers) = INFTRental.listOffers(
        contract_address=contract_address,
        offset=0,
        limit=10,
        filter_by_collection=0,
        filter_by_owner=0,
        inverse_order=0,
    );

    assert 3 = len;

    return ();
}

//
// getOffer
//
@external
func test_getOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, _, _) = _bind_address();

    _approve_before_offer();

    let (index) = _make_an_offer();
    let (offer) = INFTRental.getOffer(contract_address=contract_address, index=index);

    assert_uint256_eq(offer.tokenId, Uint256(NFT_1, 0));

    return ();
}

//
// getOffersByTokenId
//
@external
func test_getOffersByTokenId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, collection_address, _) = _bind_address();

    _approve_before_offer();

    _make_an_offer();
    _make_an_offer();

    let (len, offers) = INFTRental.getOffersByTokenId(
        contract_address=contract_address, collection=collection_address, tokenId=Uint256(NFT_1, 0)
    );
    assert 2 = len;

    %{ expect_revert("TRANSACTION_FAILED", "Collection: address is not whitelisted.") %}
    let (len2, offers2) = INFTRental.getOffersByTokenId(
        contract_address=contract_address, collection=0x000, tokenId=Uint256(NFT_1, 0)
    );

    return ();
}

//
// addCollection
//
@external
func test_addCollection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    index: felt
) {
    let (contract_address, _, _) = _bind_address();

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    let (index) = INFTRental.addCollection(contract_address=contract_address, address=0x1);
    %{ stop_prank() %}

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner")
    %}
    let (index) = INFTRental.addCollection(contract_address=contract_address, address=0x1);
    %{ stop_prank() %}

    return (index,);
}

//
// addCollateral
//
@external
func test_addCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    index: felt
) {
    let (contract_address, _, _) = _bind_address();

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    let (index) = INFTRental.addCollateral(contract_address=contract_address, address=0x1);
    %{ stop_prank() %}

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner")
    %}
    let (index) = INFTRental.addCollateral(contract_address=contract_address, address=0x1);
    %{ stop_prank() %}

    return (index,);
}

//
// removeCollection
//
@external
func test_removeCollection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (contract_address, _, _) = _bind_address();

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    INFTRental.removeCollection(contract_address=contract_address, index=0);
    %{ stop_prank() %}

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner")
    %}
    INFTRental.removeCollection(contract_address=contract_address, index=0);
    %{ stop_prank() %}

    return ();
}

//
// removeCollateral
//
@external
func test_removeCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (contract_address, _, _) = _bind_address();

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    INFTRental.removeCollateral(contract_address=contract_address, index=0);
    %{ stop_prank() %}

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner")
    %}
    INFTRental.removeCollateral(contract_address=contract_address, index=0);
    %{ stop_prank() %}

    return ();
}

//
// configOffer
//
@external
func test_configOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (contract_address, _, _) = _bind_address();

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    INFTRental.configOffer(
        contract_address=contract_address,
        limit_rent_time_min=1,
        limit_rent_time_max=15,
        limit_same_nft_offer=10,
    );
    %{ stop_prank() %}

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner")
    %}
    INFTRental.configOffer(
        contract_address=contract_address,
        limit_rent_time_min=1,
        limit_rent_time_max=15,
        limit_same_nft_offer=10,
    );
    %{ stop_prank() %}
    return ();
}

//
// pauseUnpauseOffer
//
@external
func test_pauseUnpauseOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, _, _) = _bind_address();

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    let (status) = INFTRental.pauseUnpauseOffer(contract_address=contract_address);
    assert 1 = status;
    %{ stop_prank() %}

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner")
    %}
    let (status) = INFTRental.pauseUnpauseOffer(contract_address=contract_address);
    %{ stop_prank() %}

    return ();
}

//
// offer
//
@external
func test_offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, collection_address, collateral_address) = _bind_address();

    _approve_before_offer();

    let (index) = _make_an_offer();

    assert 0 = index;

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Offer: token not belongs to caller.")
    %}
    let (index) = INFTRental.offer(
        contract_address=contract_address,
        collection=collection_address,
        tokenId=Uint256(NFT_1, 0),
        collateral=collateral_address,
        collateral_amount=Uint256(10 * 10 ** 18, 0),
        interest_rate=Uint256(1 * 10 ** 17, 0),
        rent_time_min=10,
        rent_time_max=30,
    );

    %{ stop_prank() %}

    return ();
}

//
// cancelOffer
//
@external
func test_cancelOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, collection_address, _) = _bind_address();

    _approve_before_offer();

    let (index) = _make_an_offer();
    let (offer) = INFTRental.getOffer(contract_address=contract_address, index=index);
    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Offer: caller is not the offer owner.")
    %}
    INFTRental.cancelOffer(contract_address=contract_address, index=index);
    %{ stop_prank() %}

    //
    // As Owner
    //
    %{ stop_prank = start_prank(ids.NFT_OWNER, context.contract_address) %}
    INFTRental.cancelOffer(contract_address=contract_address, index=index);
    let (owner_as_zero) = IERC721.ownerOf(collection_address, offer.tokenId);
    %{ stop_prank() %}

    assert 0 = owner_as_zero;

    return ();
}

//
// cancelOffers
//
@external
func test_cancelOffers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, _, _) = _bind_address();

    _approve_before_offer();
    _make_an_offer();
    _make_an_offer();
    _make_an_offer();

    //
    // As Guest
    //
    %{ expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner") %}
    let (cancelled) = INFTRental.cancelOffers(
        contract_address=contract_address, filter_by_collection=0, filter_by_owner=0
    );

    //
    // As Owner
    //
    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    let (cancelled) = INFTRental.cancelOffers(
        contract_address=contract_address, filter_by_collection=0, filter_by_owner=0
    );
    %{ stop_prank() %}

    assert 3 = cancelled;

    return ();
}

//
// pauseUnpauseRent
//
@external
func test_pauseUnpauseRent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, _, _) = _bind_address();

    %{ stop_prank = start_prank(ids.OWNER, context.contract_address) %}
    let (status) = INFTRental.pauseUnpauseRent(contract_address=contract_address);
    assert 1 = status;
    %{ stop_prank() %}

    //
    // As Guest
    //
    %{
        stop_prank = start_prank(ids.GUEST, context.contract_address)
        expect_revert("TRANSACTION_FAILED", "Ownable: caller is not the owner")
    %}
    let (status) = INFTRental.pauseUnpauseRent(contract_address=contract_address);
    %{ stop_prank() %}

    return ();
}

//
// rent
//
@external
func test_rent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (contract_address, collection_address, collateral_address) = _bind_address();

    // NFT_OWNER
    _approve_before_offer();

    let (index) = _make_an_offer();
    let (offer) = INFTRental.getOffer(contract_address, index);

    // RENTER
    %{ stop_prank = start_prank(ids.GUEST, context.collateral_address) %}
    let (approved) = IERC20.approve(
        contract_address=collateral_address,
        spender=contract_address,
        amount=offer.collateral_amount,
    );
    assert TRUE = approved;
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.GUEST, context.contract_address) %}
    %{ expect_events({"name": "Transfer", "data": [ids.GUEST, ids.contract_address, 10 *10 **18, 0]}) %}
    INFTRental.rent(
        contract_address=contract_address,
        index=index,
        collection=offer.collection,
        tokenId=offer.tokenId,
        collateral=offer.collateral,
        collateral_amount=offer.collateral_amount,
        interest_rate=offer.interest_rate,
        rent_time_min=offer.rent_time_min,
        rent_time_max=offer.rent_time_max,
        timestamp=offer.timestamp,
    );
    %{ stop_prank() %}

    let (balance: Uint256) = IERC20.balanceOf(
        contract_address=collateral_address, account=contract_address
    );

    assert offer.collateral_amount = balance;

    let (nft_owner) = IERC721.ownerOf(contract_address=collection_address, tokenId=offer.tokenId);

    assert GUEST = nft_owner;

    return ();
}
