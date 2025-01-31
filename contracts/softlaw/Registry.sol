// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {UniqueNFT, CrossAddress} from "@unique-nft/solidity-interfaces/contracts/UniqueNFT.sol";
import {Property, CollectionLimitValue, CollectionNestingAndPermission} from "@unique-nft/solidity-interfaces/contracts/CollectionHelpers.sol";
import {CollectionMinter, Property, TokenPropertyPermission, CollectionLimitValue, CollectionLimitField, CollectionNestingAndPermission} from "../CollectionMinter.sol";
import {TokenMinter, Attribute} from "../TokenMinter.sol";
import {Converter} from "../libraries/Converter.sol";

/**
 * @title SOFTLAW - INTELLECTUAL PROPERTY TOKENIZER.
 * creations of the mind, such as inventions; literary and artistic works; designs; and symbols, names and images used in commerce.
 *
 * @notice ❗️DISCLAIMER: This contract is provided as an example and is not production-ready.
 * It is intended for educational and testing purposes only. Use at your own risk.
 *
 * @dev Contract for minting collections and tokens in the Unique Schema V2.
 * It sets sponsoring for each collection to create a gasless experience for end users.
 * Inherits from CollectionMinter and TokenMinter.
 * See the example in tests https://github.com/UniqueNetwork/unique-contracts/blob/main/test/minter.spec.ts
 */
contract SoftlawRegistry is CollectionMinter, TokenMinter {
    using Converter for *;

    /// @dev Intellectual Property Collection Types, User can have max 4 collections, one of each one, entra como variable de nombre.
    enum IPType {
        PATENT,
        COPYRIGHT,
        TRADEMARK,
        LICENSE
    }

    struct UserCollections {
        address patent;
        address copyright;
        address trademark;
        address license;
    }

    struct IpAsset {
        IPType ipType;
        CrossAddress owner;
        // string contentHash;
        uint256 registrationDate;
        bool verified;
        string jurisdiction;
        bool active;
        address collectionAddress;
        // string details;
    }

    uint256 tokenRegistry;

    /// @dev track collection owners to restrict minting
    mapping(address collection => address owner) private s_collectionOwner;
    mapping(uint256 => IpAsset) public softlawRegistry;

    /// @dev Event emitted when a new collection is created.
    event CollectionCreated(address collectionAddress);

    event IPAssetRegistered(
        uint256 indexed assetId,
        IPType indexed ipType,
        address indexed collectionAddress,
        CrossAddress owner
    );

    modifier onlyCollectionOwner(address _collectionAddress) {
        require(msg.sender == s_collectionOwner[_collectionAddress]);
        _;
    }

    error IncorrectFee();

    /**
     * @dev Constructor that sets default property permissions and allows the contract to receive UNQ.
     * This contract sponsors every collection and token minting which is why it should have a balance of UNQ
     * Sets properties as
     * - mutable
     * - collectionAdmin has permissions to change properties.
     * - token owner has no permissions to change properties
     */

    constructor() payable CollectionMinter(true, true, true) {
        tokenRegistry = 1;
    }

    receive() external payable {}

    /**
     * @notice Creates a new collection. The collection creation fee must be paid.
     * @param _name The name of the collection.
     * @param _description A brief description of the collection.
     * @param _symbol The symbol or prefix for tokens in the collection.
     * @param _collectionCover A URL pointing to the cover image for the collection.
     */
    function mintSoftlawCollection(
        string memory _name,
        string memory _description,
        string memory _symbol,
        string memory _collectionCover,
        CollectionNestingAndPermission memory nesting_settings,
        CrossAddress memory _owner
    ) external payable returns (address) {
        address collectionAddress = _createCollection(
            _name,
            _description,
            _symbol,
            _collectionCover,
            nesting_settings,
            new CollectionLimitValue[](0),
            new Property[](0),
            new TokenPropertyPermission[](0)
        );

        UniqueNFT collection = UniqueNFT(collectionAddress);

        // Set collection sponsorship to the contract address
        collection.setCollectionSponsorCross(CrossAddress({eth: address(this), sub: 0}));
        // Confirm the collection sponsorship
        collection.confirmCollectionSponsorship();
        // Sponsor every transaction

        // Set this contract as an admin
        // Because the minted collection will be owned by the user this contract
        // has to be set as a collection admin in order to be able to mint NFTs
        collection.addCollectionAdminCross(CrossAddress({eth: address(this), sub: 0}));

        // Transfer ownership of the collection to the contract caller
        collection.changeCollectionOwnerCross(_owner);
        s_collectionOwner[collectionAddress] = msg.sender;

        emit CollectionCreated(collectionAddress);

        return collectionAddress;
    }

    /**
     * @dev Function to mint a new token within a collection.
     * @param _name Name of the Intellectual Property Creation.
     * @param _description Description of the Intellectual Property Creation.
     * @param _imagesHash of the proof of creation.
     * @param _collectionAddress Address of the collection in which to mint the token. The contract should be an admin for the collection
     * @param _ipType URL of the token image.
     * @param _jurisdiction Array of attributes for the token.
     * @param _tokenOwner Owner of the token
     */

    function mintSoftlawToken(
        string memory _name,
        string memory _description,
        string memory _imagesHash,
        IPType _ipType,
        string memory _jurisdiction,
        address _collectionAddress,
        Attribute[] memory _attributes,
        CrossAddress memory _tokenOwner
    ) external onlyCollectionOwner(_collectionAddress) returns (uint256) {
        tokenRegistry += 1;

        // Mint token
        uint256 tokenId = _createToken(_collectionAddress, _imagesHash, _name, _description, _attributes, _tokenOwner);

        // Store IP asset
        softlawRegistry[tokenId] = IpAsset({
            ipType: _ipType,
            owner: _tokenOwner,
            // contentHash: _contentHash,
            registrationDate: block.timestamp,
            verified: false,
            jurisdiction: _jurisdiction,
            active: true,
            collectionAddress: _collectionAddress
            // details: _details
        });

        emit IPAssetRegistered(tokenId, _ipType, _collectionAddress, _tokenOwner);

        return tokenRegistry;
    }

    ///// HELPER FUNCTIONS///
    function _getIPTypeString(IPType _type) private pure returns (string memory) {
        if (_type == IPType.PATENT) return "PATENT";
        if (_type == IPType.COPYRIGHT) return "COPYRIGHT";
        if (_type == IPType.TRADEMARK) return "TRADEMARK";
        if (_type == IPType.LICENSE) return "LICENSE";
        return "";
    }

    // function _createSoftlawTokenAttributes(
    //     IPType _type,
    //     string memory _jurisdiction
    // ) private view returns (Attribute[] memory) {
    //     Attribute[] memory attributes = new Attribute[](4);
    //     attributes[0] = Attribute("IP Type", _getIPTypeString(_type));
    //     attributes[1] = Attribute("Jurisdiction", _jurisdiction);
    //     attributes[2] = Attribute("Registration Date", block.timestamp.uint2str());
    //     return attributes;
    // }
}
