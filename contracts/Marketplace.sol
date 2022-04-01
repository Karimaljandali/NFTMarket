// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Marketplace {

    // Global Variables, Mappings, Structs, and Modifiers.
    // ========================================
    // 1. Listing Struct - DONE
    // 2. Contract to Listing mapping - DONE
    // 3. 

    /// Mapping that tracks an (NFT) address to an owner to a Listing object.
    /// Contract Address => Owner => Listing.
    mapping(address => mapping(address => Listing)) public listings;

    /// @notice A struct that represent a Listing on the marketplace.
    /// @param owner   : address   The owner of the tokens that created the Listing.
    /// @param expires : uint64    Timestamp of when the Listing expires.
    /// @param price   : uint32    Price of the Listing
    /// @param tokenId : uint32    ID of the token being listed.
    struct Listing {
        address owner;
        uint64  expires;
        uint32  price;
        uint32  tokenId;
    }

    // Admin Functions, Events, and Structs
    // ====================================
    // 1. Set Marketplace Fee
    // 2. Blacklist NFT Collection
    // 3. Blacklist NFT Token
    // 4. Pause&Unpause Contract
    // 5. Initialization/Constructor


    // Contract Creator Functions, Events, and Structs
    // ===============================================
    // 1. Update Fee
    // 2. Update Fee Recipient Address


    // User Functions, Events, and Structs
    // ===================================
    // 1. Create Listing - DONE
    // 2. Cancel Listing
    // 3. Buy Item
    // 4. Update Listing

    /// Event that is emitted when a Listing is created for
    event ListingCreated(address _owner, address _nftAddress, uint64 _expires);

    // TODO: Comments for this function.
    function createListing(
        address _nftCollection,
        address _owner,
        uint64 _expires,
        uint32 _tokenId,
        uint32 _price
    ) public {
        // TODO: Check if _NftCollection is a valid ERC-721 contract.
        require(_expires > block.timestamp, "Error: set the expiration to the future.");

        IERC721 nft = IERC721(_nftCollection);
        require(nft.isApprovedForAll(_owner, address(this)), "Error: the marketplace is not approved.");
        require(_owner == nft.ownerOf(_tokenId), "Error: you don't own this token.");
        require(_price > 0, "You can't list for 0.");

        listings[_nftCollection][_owner] = Listing({
            owner: _owner,
            expires: _expires,
            price: _price,
            tokenId: _tokenId
        });
        
        emit ListingCreated(_owner, _nftCollection, _expires);
        
    }   
}