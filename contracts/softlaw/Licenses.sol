// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SoftlawRegistry, CrossAddress} from "./Registry.sol";

contract SoftlawLicenses is SoftlawRegistry {
    struct LicenseOffer {
        uint256 nftId;
        uint256 royaltyRate;
        uint256 licensePrice;
        uint256 paymentStructure;
        CrossAddress tokenOwner;
        bool isAccepted;
    }

    mapping(uint256 => LicenseOffer) public licenseOffers;
    mapping(address => uint256) public pendingWithdrawals;
    uint256 public licenseCounter;

    event LicenseOffered(
        CrossAddress indexed tokenOwner,
        uint256 indexed nftId,
        uint256 royaltyRate,
        uint256 licensePrice,
        uint256 paymentStructure,
        uint256 licenseId
    );

    event LicenseAccepted(address indexed buyer, uint256 indexed licenseId);

    event Withdraw(address indexed owner, uint256 amount);

    mapping(uint256 => address) public s_nftOwner;

    modifier onlyNftOwner(uint256 _nftId) {
        require(msg.sender == s_nftOwner[_nftId], "Not the NFT owner");
        _;
    }

    constructor() payable SoftlawRegistry() {}

    function offerLicense(
        uint256 _nftId,
        uint256 _royaltyRate,
        uint256 _licensePrice,
        uint256 _paymentStructure,
        CrossAddress memory _tokenOwner
    ) external onlyNftOwner(_nftId) returns (uint256) {
        licenseCounter++;
        uint256 licenseId = licenseCounter;

        licenseOffers[licenseId] = LicenseOffer({
            nftId: _nftId,
            royaltyRate: _royaltyRate,
            licensePrice: _licensePrice,
            paymentStructure: _paymentStructure,
            tokenOwner: _tokenOwner,
            isAccepted: false
        });

        emit LicenseOffered(_tokenOwner, _nftId, _royaltyRate, _licensePrice, _paymentStructure, licenseId);
        return licenseId;
    }

    function acceptLicense(uint256 _licenseId) external payable {
        LicenseOffer storage offer = licenseOffers[_licenseId];
        require(!offer.isAccepted, "License already accepted");
        require(msg.value >= offer.licensePrice, "Insufficient payment");

        offer.isAccepted = true;
        pendingWithdrawals[offer.tokenOwner.eth] += msg.value;

        emit LicenseAccepted(msg.sender, _licenseId);
    }

    function withdrawPayments() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");
        pendingWithdrawals[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdraw(msg.sender, amount);
    }
}
