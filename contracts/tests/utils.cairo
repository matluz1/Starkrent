%lang starknet

from starkware.cairo.common.uint256 import Uint256

from src.offer.library import OfferStruct

const OWNER = 1;
const NFT_OWNER = 2;
const THIRD_PARTY_SC = 3;
const GUEST = 99;

const COLLECTION_FAKE = 0x111;
const COLLECTION_FAKE_2 = 0x888;

const COLLATERAL_FAKE = 0x333;

const NFT_1 = 1;
const NFT_2 = 2;

const RENT_TIME_MIN = 5;
const RENT_TIME_MAX = 20;

// 1 ETH
const COLLATERAL_AMOUNT = 1 * 10 ** 18;

// 0.01 ETH
const INTEREST_RATE = 1 * 10 ** 16;

namespace Utils {
    func _get_mocked_offer{syscall_ptr: felt*}() -> OfferStruct {
        let offer_struct = OfferStruct(
            owner=NFT_OWNER,
            collection=COLLECTION_FAKE,
            tokenId=Uint256(NFT_1, 0),
            collateral=COLLATERAL_FAKE,
            collateral_amount=Uint256(COLLATERAL_AMOUNT, 0),
            interest_rate=Uint256(INTEREST_RATE, 0),
            rent_time_min=RENT_TIME_MIN,
            rent_time_max=RENT_TIME_MAX,
            timestamp=0,
        );

        return offer_struct;
    }
}
