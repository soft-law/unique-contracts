// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {UniqueNFT, CrossAddress} from "@unique-nft/solidity-interfaces/contracts/UniqueNFT.sol";
import {Property, CollectionLimitValue, CollectionNestingAndPermission} from "@unique-nft/solidity-interfaces/contracts/CollectionHelpers.sol";
import {CollectionMinter, CollectionMode, TokenPropertyPermission} from "../CollectionMinter.sol";
import {TokenMinter, Attribute} from "../TokenMinter.sol";
import {Converter} from "../libraries/Converter.sol";

/**
 * @title SOFTLAW - INTELLECTUAL PROPERTY TOKENIZER.
 * @notice ❗️DISCLAIMER: This contract is provided as an example and is not production-ready.
 * It is intended for educational and testing purposes only. Use at your own risk.
 *
 * @dev Contract for minting collections and tokens in the Unique Schema V2.
 * It sets sponsoring for each collection to create a gasless experience for end users.
 * Inherits from CollectionMinter and TokenMinter.
 * See the example in tests https://github.com/UniqueNetwork/unique-contracts/blob/main/test/minter.spec.ts
 */
contract Softlaw is CollectionMinter, TokenMinter {
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

    struct LicenseAsset {
        IPType ipType;
        address owner;
        string contentHash;
        uint256 registrationDate;
        bool verified;
        string jurisdiction;
        bool active;
        address collectionAddress;
        string details;
    }

    uint256 tokenRegistry;

    /// @dev track collection owners to restrict minting
    mapping(address collection => address owner) private s_collectionOwner;
    mapping(uint256 => LicenseAsset) public softlawRegistry;

    /// @dev Event emitted when a new collection is created.
    event CollectionCreated(address collectionAddress);

    event IPAssetRegistered(
        uint256 indexed assetId,
        IPType indexed ipType,
        address indexed collectionAddress,
        address owner
    );

    modifier onlyCollectionOwner(address _collectionAddress) {
        require(msg.sender == s_collectionOwner[_collectionAddress]);
        _;
    }

    /**
     * @dev Constructor that sets default property permissions and allows the contract to receive UNQ.
     * This contract sponsors every collection and token minting which is why it should have a balance of UNQ
     * Sets properties as
     * - mutable
     * - collectionAdmin has permissions to change properties.
     * - token owner has no permissions to change properties
     */
    constructor() payable CollectionMinter(true, true, false) {}

    receive() external payable {}

    /**
     * @dev Function to mint a new collection.
     * @param _name Name of the collection.
     * @param _description Description of the collection.
     * @param _symbol Symbol prefix for the tokens in the collection.
     * @param _collectionCover URL of the cover image for the collection.
     * @param _owner Owner of the collection
     * @return Address of the created collection.
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
     * @param _collectionAddress Address of the collection in which to mint the token. The contract should be an admin for the collection
     * @param _image URL of the token image.
     * @param _attributes Array of attributes for the token.
     * @param _tokenOwner Owner of the token
     */
    function mintSoftlawToken(
        address _collectionAddress,
        string memory _image,
        string memory _name,
        string memory _description,
        Attribute[] memory _attributes,
        CrossAddress memory _tokenOwner
    ) external onlyCollectionOwner(_collectionAddress) {
        _createToken(_collectionAddress, _image, _name, _description, _attributes, _tokenOwner);
    }

    /**
     * @dev Function to mint a new IP Asset within a collection.
     * @param _name Name of The License.
     * @param _description Description of the terms and condifions of the license.
     * @param _ipType Type of intellectual property (PATENT, COPYRIGHT, TRADEMARK, LICENSE)
     * @param _contentHash Hash of the Terms and Conditions
     * @param _jurisdiction Jurisdiction of where is it going to execute the terms and conditions.
     * @param _details Jurisdiction of the IP content stored on IPFS or similar system
     * @param _image Jurisdiction of the IP content stored on IPFS or similar system
     * @param _collectionAddress Jurisdiction of the IP content stored on IPFS or similar system
     */
    function mintSoftlawLicense(
        string memory _name,
        string memory _description,
        IPType _ipType,
        string memory _contentHash,
        string memory _jurisdiction,
        string memory _details,
        string memory _image,
        address _collectionAddress
    ) external returns (uint256) {
        uint256 tokenRegistryNew = tokenRegistry + 1;

        Attribute[] memory attributes = _createIPAttributes(_ipType, _jurisdiction, _details);

        // Mint token
        CrossAddress memory owner;
        owner.eth = msg.sender;
        uint256 tokenId = _createToken(_collectionAddress, _image, _name, _description, attributes, owner);

        // Store IP asset
        softlawRegistry[tokenId] = LicenseAsset({
            ipType: _ipType,
            owner: msg.sender,
            contentHash: _contentHash,
            registrationDate: block.timestamp,
            verified: false,
            jurisdiction: _jurisdiction,
            active: true,
            collectionAddress: _collectionAddress,
            details: _details
        });

        emit IPAssetRegistered(tokenId, _ipType, _collectionAddress, msg.sender);

        return tokenRegistry;
    }

    function CompleteLicense(uint256 _licenseId) public view returns (uint256) {
        //todo
        return 1;
    }

    ///// HELPER FUNCTIONS///
    function _getIPTypeString(IPType _type) private pure returns (string memory) {
        if (_type == IPType.PATENT) return "PATENT";
        if (_type == IPType.COPYRIGHT) return "COPYRIGHT";
        if (_type == IPType.TRADEMARK) return "TRADEMARK";
        if (_type == IPType.LICENSE) return "LICENSE";
        return "";
    }

    function _createIPAttributes(
        IPType _type,
        string memory _jurisdiction,
        string memory _details
    ) private view returns (Attribute[] memory) {
        Attribute[] memory attributes = new Attribute[](4);
        attributes[0] = Attribute("IP Type", _getIPTypeString(_type));
        attributes[1] = Attribute("Jurisdiction", _jurisdiction);
        attributes[2] = Attribute("Registration Date", block.timestamp.uint2str());
        attributes[3] = Attribute("Details", _details);
        return attributes;
    }
}
