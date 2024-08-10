// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SupastoreNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Token ID counter
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to content URI
    mapping(uint256 => string) private _tokenURIs;

    // Event emitted when a new product NFT is minted
    event ProductMinted(address indexed owner, uint256 indexed tokenId, string contentUri);

    constructor() ERC721("SupastoreProduct", "SPNFT") {}

    /**
     * @dev Mints a new product NFT.
     * @param to The address that will own the minted NFT.
     * @param contentUri The URI pointing to the product's metadata.
     */
    function mintProduct(address to, string memory contentUri) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, contentUri);

        emit ProductMinted(to, tokenId, contentUri);

        return tokenId;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param tokenId The ID of the token.
     * @return The URI associated with the token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Sets the token URI for a given token ID.
     * @param tokenId The ID of the token.
     * @param _tokenURI The URI to be associated with the token.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId The ID of the token being burned.
     */
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        delete _tokenURIs[tokenId];
    }
}