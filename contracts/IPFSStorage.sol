// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IPFSStorage
 * @dev 
 */
contract IPFSStorage {
    
   
    mapping(address => string) public userProfileHashes; 
    mapping(uint256 => string[]) public bookingChatHashes; 
    mapping(uint256 => string) public tourPackageHashes; 
    mapping(uint256 => string) public disputeEvidenceHashes; 
    
    event IPFSHashStored(address indexed user, string hashType, string ipfsHash);
    event ChatMessageStored(uint256 indexed bookingId, address sender, string ipfsHash);
    
    // Store user profile IPFS hash
    function storeUserProfileHash(string memory _ipfsHash) external {
        userProfileHashes[msg.sender] = _ipfsHash;
        emit IPFSHashStored(msg.sender, "profile", _ipfsHash);
    }
    
    // Store tour package details IPFS hash
    function storeTourPackageHash(uint256 _packageId, string memory _ipfsHash) external {
        tourPackageHashes[_packageId] = _ipfsHash;
        emit IPFSHashStored(msg.sender, "package", _ipfsHash);
    }
    
    // Store chat message IPFS hash
    function storeChatMessageHash(uint256 _bookingId, string memory _ipfsHash) external {
        bookingChatHashes[_bookingId].push(_ipfsHash);
        emit ChatMessageStored(_bookingId, msg.sender, _ipfsHash);
    }
    
    // Store dispute evidence IPFS hash
    function storeDisputeEvidence(uint256 _bookingId, string memory _ipfsHash) external {
        disputeEvidenceHashes[_bookingId] = _ipfsHash;
        emit IPFSHashStored(msg.sender, "dispute_evidence", _ipfsHash);
    }
    
    // Get user profile IPFS hash
    function getUserProfileHash(address _user) external view returns (string memory) {
        return userProfileHashes[_user];
    }
    
    // Get chat messages IPFS hashes for a booking
    function getBookingChatHashes(uint256 _bookingId) external view returns (string[] memory) {
        return bookingChatHashes[_bookingId];
    }
    
    // Get tour package IPFS hash
    function getTourPackageHash(uint256 _packageId) external view returns (string memory) {
        return tourPackageHashes[_packageId];
    }
}