// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Minter.sol";
import "../CollectionMinter.sol";
import "../TokenMinter.sol";
import "../TokenManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title LicensesManager
 * @dev Manages intellectual property licenses as NFTs with specific attributes and rules
 */
contract LicensesManager is Minter, Ownable {
    using Strings for uint256;

    // Structs
    struct License {
        string licenseType;      // Commercial, Non-Commercial, etc.
        uint256 validUntil;      // Timestamp for license expiration
        string jurisdiction;     // Legal jurisdiction
        string terms;           // License terms hash/URI
        bool transferable;      // If the license can be transferred
        uint256 price;          // Price for the license
        bool active;            // Whether the license is active
    }

    // State variables
    mapping(uint256 => License) public licenses;
    mapping(address => uint256[]) public userLicenses;
    mapping(uint256 => bool) public revoked;
    
    // Events
    event LicenseCreated(uint256 indexed tokenId, address indexed creator, string licenseType);
    event LicenseTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event LicenseRevoked(uint256 indexed tokenId, string reason);
    event LicenseRenewed(uint256 indexed tokenId, uint256 newExpiry);

    constructor(
        address _collectionAddress
    ) Minter(_collectionAddress) {
    }

    /**
     * @dev Creates a new license as an NFT
     */
    function mintLicense(
        string memory _licenseType,
        uint256 _validityPeriod,
        string memory _jurisdiction,
        string memory _terms,
        bool _transferable,
        uint256 _price,
        string memory _image
    ) external returns (uint256) {
        Attribute[] memory attributes = new Attribute[](6);
        attributes[0] = Attribute("License Type", _licenseType);
        attributes[1] = Attribute("Valid Until", (block.timestamp + _validityPeriod).toString());
        attributes[2] = Attribute("Jurisdiction", _jurisdiction);
        attributes[3] = Attribute("Terms", _terms);
        attributes[4] = Attribute("Transferable", _transferable ? "Yes" : "No");
        attributes[5] = Attribute("Price", _price.toString());

        // Use the Minter's createToken function
        CrossAddress memory to;
        to.eth = msg.sender;
        uint256 tokenId = _createToken(collectionAddress, _image, attributes, to);

        // Store license details
        licenses[tokenId] = License({
            licenseType: _licenseType,
            validUntil: block.timestamp + _validityPeriod,
            jurisdiction: _jurisdiction,
            terms: _terms,
            transferable: _transferable,
            price: _price,
            active: true
        });

        userLicenses[msg.sender].push(tokenId);
        
        emit LicenseCreated(tokenId, msg.sender, _licenseType);
        return tokenId;
    }

    /**
     * @dev Revokes a license
     */
    function revokeLicense(uint256 _tokenId, string memory _reason) external onlyOwner {
        require(licenses[_tokenId].active, "License not active");
        licenses[_tokenId].active = false;
        revoked[_tokenId] = true;
        emit LicenseRevoked(_tokenId, _reason);
    }

    /**
     * @dev Renews a license for an additional period
     */
    function renewLicense(uint256 _tokenId, uint256 _additionalTime) external {
        require(licenses[_tokenId].active, "License not active");
        require(!revoked[_tokenId], "License has been revoked");
        
        licenses[_tokenId].validUntil += _additionalTime;
        
        // Update the validity attribute
        _setTrait(
            collectionAddress,
            _tokenId, 
            bytes("Valid Until"),
            bytes(licenses[_tokenId].validUntil.toString())
        );
        
        emit LicenseRenewed(_tokenId, licenses[_tokenId].validUntil);
    }

    /**
     * @dev Checks if a license is valid
     */
    function isLicenseValid(uint256 _tokenId) public view returns (bool) {
        License memory license = licenses[_tokenId];
        return license.active && 
               !revoked[_tokenId] && 
               license.validUntil > block.timestamp;
    }

    /**
     * @dev Gets all licenses owned by a user
     */
    function getUserLicenses(address _user) external view returns (uint256[] memory) {
        return userLicenses[_user];
    }

    /**
     * @dev Override transfer to check transferability
     */
    function transferLicense(uint256 _tokenId, address _to) external {
        require(licenses[_tokenId].transferable, "License is not transferable");
        require(isLicenseValid(_tokenId), "License is not valid");
        
        // Handle the transfer logic here
        // You might want to integrate with the NFT transfer functionality
        
        // Update user license mappings
        userLicenses[_to].push(_tokenId);
        
        emit LicenseTransferred(_tokenId, msg.sender, _to);
    }
}