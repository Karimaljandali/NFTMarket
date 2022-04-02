// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC721.sol";


contract Marketplace {

    // Global Variables, Mappings, Structs, and Modifiers.
    // ========================================
    // 1. Listing Struct - DONE
    // 2. Contract to Listing mapping - DONE
    // 3. 

    /// @notice Mapping that tracks an (NFT) address to an owner to a tokenID to a Listing object.
    /// @dev Contract Address => Owner => tokenID => Listing.
    mapping(address => mapping(address => mapping(uint64 => Listing))) public listings;

    /// @notice A struct that represent a Listing on the marketplace.
    /// @param owner   : address   The owner of the tokens that created the Listing.
    /// @param expires : uint64    Timestamp of when the Listing expires.
    /// @param price   : uint32    Price of the Listing
    struct Listing {
        address owner;
        uint64  expires;
        uint32  price;
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
    // 2. Cancel Listing - DONE
    // 3. Buy Item - DONE
    // 4. Update Listing

    /// @notice Event that is emitted when a Listing is created in the marketplace.
    /// @param _owner         : address  The address of the owner of the NFT
    /// @param _nftAddress    : address  The address of the NFT.
    /// @param _expires       : uint64   The timestamp of the expiration.
    /// @param _tokenId       : uint32   The tokenID of the NFT.
    /// @param _price         : uint32   The price of the Listing.
    event ListingCreated(address _owner, address _nftAddress, uint64 _expires, uint32 _tokenId, uint32 _price);


    /// @notice This function handles the creations of Listings and adds it 
    /// to the listings mapping and emits an event.
    /// @param _nftAddress    : address  The address of the NFT.
    /// @param _expires       : uint64   The timestamp of the expiration.
    /// @param _tokenId       : uint32   The tokenID of the NFT.
    /// @param _price         : uint32   The price of the Listing.
    function createListing(
        address _nftAddress,
        uint64 _expires,
        uint32 _tokenId,
        uint32 _price
    ) public {
        // TODO: Check if _nftAddress is a valid ERC-721 contract.
        require(_expires > block.timestamp, "Error: set the expiration to the future.");

        IERC721 nft = IERC721(_nftAddress);
        require(nft.isApprovedForAll(msg.sender, address(this)), "Error: the marketplace is not approved.");
        require(msg.sender == nft.ownerOf(_tokenId), "Error: you don't own this token.");
        require(_price > 0, "You can't list for 0.");

        listings[_nftAddress][msg.sender][_tokenId] = Listing({
            owner: msg.sender,
            expires: _expires,
            price: _price
        });
        
        emit ListingCreated(msg.sender, _nftAddress, _expires, _tokenId, _price);
        
    }


    /// @notice Event that is emitted when a Listing is cancelled in the Marketplace.
    /// @param _owner         : address  The address of the owner of the NFT
    /// @param _nftAddress    : address  The address of the NFT.
    /// @param _tokenId       : uint32   The tokenID of the NFT.
    event ListingCancelled(address _owner, address _nftAddress, uint32 _tokenId); 

    /// @notice This function cancels an existing Listing from the marketplace.
    /// @param _nftAddress    : address The address of the NFT.
    /// @param _tokenId       : uint64  The tokenID of the NFT.
    function cancelListing(
        address _nftAddress,
        uint32 _tokenId
    ) public {
        IERC721 nft = IERC721(_nftAddress);
        require(msg.sender == nft.ownerOf(_tokenId), "Error: you don't own this token.");
        delete listings[_nftAddress][msg.sender][_tokenId];
        
        emit ListingCancelled(msg.sender, _nftAddress, _tokenId);
    }

    /// @notice Event that a purchase has been made.
    /// @param _originalOwner : address  The address of the seller of the NFT.
    /// @param _newOwner      : address  The address of the new owner of the NFT.
    /// @param _nftAddress    : address  The address of the NFT.
    /// @param _tokenId       : uint32   The tokenID of the NFT.
    event PurchaseMade(address _originalOwner, address _newOwner, address _nftAddress, uint32 _tokenId);

    /// @notice This function handles the purchase of a Listing.
    /// @dev    We do a few security checks before transferring the token to the new owner
    ///         and then transferring 100% of the proceeds to the seller.
    /// @param _nftAddress    : address The address of the NFT.
    /// @param _currentOwner  : address The address of the current holder of the NFT.
    /// @param _tokenId       : uint64  The tokenID of the NFT.

    function buyItem(address _nftAddress, address payable _currentOwner, uint32 _tokenId) 
        external
        payable
    {
        require(msg.sender != _currentOwner, "Error: you already own this token.");
        Listing memory listing = listings[_nftAddress][_currentOwner][_tokenId];
        require(listing.expires >= block.timestamp, "Error: listing expired.");
        require(msg.value >= listing.price, "Error: not enough eth sent.");

        IERC721 nft = IERC721(_nftAddress);
        /// @dev Not sure if this is needed. Need to check if failing transfer of token
        ///      implies that they don't own it anymore and code automatically stops.
        ///      Guess it doesn't hurt to have the extra step here for now.
        require(listing.owner == nft.ownerOf(_tokenId), "Error: listing creator no longer owns this.");

        emit PurchaseMade(_currentOwner, msg.sender, _nftAddress, _tokenId);

        /// Transfer NFT from old owner to new owner.
        nft.safeTransferFrom(_currentOwner, msg.sender, _tokenId);

        /// Transfer ETH to old owner.
        /// For now we won't take a fee for the marketplace. Seller gets 100% of the proceeds.
        _currentOwner.transfer(msg.value);

        delete listings[_nftAddress][_currentOwner][_tokenId];
    }

}