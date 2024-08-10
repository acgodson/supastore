// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title RatingsResolver
 * @notice A schema resolver that validates ratings based on NFT ownership.
 */
contract RatingsResolver is SchemaResolver {
    IERC721 private immutable _nftContract;

    // Mapping to track if a user has already rated a specific product
    // mapping(address => mapping(uint256 => bool)) private hasRated;

    // event RatingSubmitted(
    //     address indexed user,
    //     uint256 indexed productId,
    //     bool valid
    // );

    event RatingRevoked(address indexed user, uint256 indexed productId);

    constructor(IEAS eas, IERC721 nftContract) SchemaResolver(eas) {
        _nftContract = nftContract;
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal view override returns (bool) {
        uint256 productId = abi.decode(attestation.data, (uint256));
        require(
            _nftContract.ownerOf(productId) == attestation.recipient,
            "User does not own the product"
        );

        // require(
        //     !hasRated[attestation.recipient][productId],
        //     "Product already rated by this user"
        // );

        return true;
    }

    function onRevoke(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal override returns (bool) {
        uint256 productId = abi.decode(attestation.data, (uint256));
        emit RatingRevoked(attestation.recipient, productId);
        return true;
    }
}
