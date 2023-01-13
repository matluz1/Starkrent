// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721MintableBurnable {
    func mint(to: felt, tokenId: Uint256) {
    }
}
