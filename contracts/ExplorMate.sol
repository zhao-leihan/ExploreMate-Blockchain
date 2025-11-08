// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ExplorMate is Ownable, ReentrancyGuard {
    enum UserRole { Tourist, Guide, Admin }
    enum BookingStatus { 
        Pending,     
        Confirmed,   
        Active,      
        Completed,  
        Cancelled,  
        Disputed    
    }
    
    struct UserProfile {
        address walletAddress;
        string name;
        string email;
        string profileImageHash; 
        UserRole role;
        bool isVerified;
        uint256 createdAt;
        uint256 rating;
        uint256 totalReviews;
    }
    
    struct TourPackage {
        uint256 packageId;
        address guideAddress;
        string title;
        string description;
        string location;
        string[] languages;
        string[] specialties;
        uint256 pricePerHour; 
        uint256 minDuration; 
        uint256 maxDuration; 
        bool isActive;
    }
    
    struct Booking {
        uint256 bookingId;
        address tourist;
        address guide;
        uint256 packageId;
        uint256 startDate;
        uint256 duration; // dalam jam
        uint256 totalPrice;
        uint256 securityDeposit;
        BookingStatus status;
        string meetingPoint;
        string specialRequests;
        uint256 createdAt;
        uint256 completedAt;
        uint256 touristRating;
        string touristReview;
        uint256 guideRating;
        string guideReview;
    }
    
    struct ChatMessage {
        uint256 bookingId;
        address sender;
        string message;
        uint256 timestamp;
        string messageType; // "text", "image", "location"
        string ipfsHash; // untuk file/location data
    }
    
    // Mappings
    mapping(address => UserProfile) public users;
    mapping(uint256 => TourPackage) public tourPackages;
    mapping(uint256 => Booking) public bookings;
    mapping(uint256 => ChatMessage[]) public bookingChats;
    mapping(address => uint256[]) public userBookings; 
    mapping(address => uint256[]) public guidePackages; 
    
    // Events
    event UserRegistered(address indexed userAddress, UserRole role);
    event UserVerified(address indexed userAddress);
    event TourPackageCreated(uint256 indexed packageId, address indexed guide);
    event BookingCreated(uint256 indexed bookingId, address indexed tourist, address indexed guide);
    event BookingStatusChanged(uint256 indexed bookingId, BookingStatus newStatus);
    event PaymentReleased(uint256 indexed bookingId, address guide, uint256 amount);
    event ChatMessageSent(uint256 indexed bookingId, address sender, string messageType);
    event RatingSubmitted(uint256 indexed bookingId, address ratedBy, uint256 rating);
    
    // Counters
    uint256 private nextPackageId = 1;
    uint256 private nextBookingId = 1;
    
    modifier onlyVerifiedUser() {
        require(users[msg.sender].isVerified, "User not verified");
        _;
    }
    
    modifier onlyGuide() {
        require(users[msg.sender].role == UserRole.Guide, "Only guides can perform this action");
        _;
    }
    
    modifier onlyTourist() {
        require(users[msg.sender].role == UserRole.Tourist, "Only tourists can perform this action");
        _;
    }
    
    modifier onlyBookingParty(uint256 _bookingId) {
        require(
            bookings[_bookingId].tourist == msg.sender || 
            bookings[_bookingId].guide == msg.sender,
            "Not a party in this booking"
        );
        _;
    }
    
    constructor() Ownable() {}
    
    // === USER MANAGEMENT ===
    function registerUser(
        string memory _name,
        string memory _email,
        string memory _profileImageHash,
        UserRole _role
    ) external {
        require(users[msg.sender].walletAddress == address(0), "User already registered");
        
        users[msg.sender] = UserProfile({
            walletAddress: msg.sender,
            name: _name,
            email: _email,
            profileImageHash: _profileImageHash,
            role: _role,
            isVerified: _role == UserRole.Tourist, // Tourist auto-verified, Guide butuh verifikasi
            createdAt: block.timestamp,
            rating: 0,
            totalReviews: 0
        });
        
        emit UserRegistered(msg.sender, _role);
    }
    
    function verifyUser(address _userAddress) external onlyOwner {
        users[_userAddress].isVerified = true;
        emit UserVerified(_userAddress);
    }
    
    // === TOUR PACKAGE MANAGEMENT ===
    function createTourPackage(
        string memory _title,
        string memory _description,
        string memory _location,
        string[] memory _languages,
        string[] memory _specialties,
        uint256 _pricePerHour,
        uint256 _minDuration,
        uint256 _maxDuration
    ) external onlyVerifiedUser onlyGuide {
        uint256 packageId = nextPackageId++;
        
        tourPackages[packageId] = TourPackage({
            packageId: packageId,
            guideAddress: msg.sender,
            title: _title,
            description: _description,
            location: _location,
            languages: _languages,
            specialties: _specialties,
            pricePerHour: _pricePerHour,
            minDuration: _minDuration,
            maxDuration: _maxDuration,
            isActive: true
        });
        
        guidePackages[msg.sender].push(packageId);
        emit TourPackageCreated(packageId, msg.sender);
    }
    
    function togglePackageActive(uint256 _packageId) external onlyGuide {
        require(tourPackages[_packageId].guideAddress == msg.sender, "Not package owner");
        tourPackages[_packageId].isActive = !tourPackages[_packageId].isActive;
    }
    
    // === BOOKING SYSTEM ===
    function createBooking(
        uint256 _packageId,
        uint256 _startDate,
        uint256 _duration,
        string memory _meetingPoint,
        string memory _specialRequests
    ) external payable onlyVerifiedUser onlyTourist nonReentrant {
        TourPackage memory package = tourPackages[_packageId];
        require(package.isActive, "Package not available");
        require(_duration >= package.minDuration && _duration <= package.maxDuration, "Invalid duration");
        
        uint256 totalPrice = package.pricePerHour * _duration;
        uint256 securityDeposit = totalPrice * 10 / 100; // 10% deposit
        uint256 totalPayment = totalPrice + securityDeposit;
        
        require(msg.value >= totalPayment, "Insufficient payment");
        
        uint256 bookingId = nextBookingId++;
        
        bookings[bookingId] = Booking({
            bookingId: bookingId,
            tourist: msg.sender,
            guide: package.guideAddress,
            packageId: _packageId,
            startDate: _startDate,
            duration: _duration,
            totalPrice: totalPrice,
            securityDeposit: securityDeposit,
            status: BookingStatus.Pending,
            meetingPoint: _meetingPoint,
            specialRequests: _specialRequests,
            createdAt: block.timestamp,
            completedAt: 0,
            touristRating: 0,
            touristReview: "",
            guideRating: 0,
            guideReview: ""
        });
        
        userBookings[msg.sender].push(bookingId);
        userBookings[package.guideAddress].push(bookingId);
        
        emit BookingCreated(bookingId, msg.sender, package.guideAddress);
    }
    
    function confirmBooking(uint256 _bookingId) external onlyGuide {
        require(bookings[_bookingId].guide == msg.sender, "Not the guide for this booking");
        require(bookings[_bookingId].status == BookingStatus.Pending, "Invalid booking status");
        
        bookings[_bookingId].status = BookingStatus.Confirmed;
        emit BookingStatusChanged(_bookingId, BookingStatus.Confirmed);
    }
    
    function startTour(uint256 _bookingId) external onlyBookingParty(_bookingId) {
        require(bookings[_bookingId].status == BookingStatus.Confirmed, "Booking not confirmed");
        require(block.timestamp >= bookings[_bookingId].startDate, "Tour hasn't started yet");
        
        bookings[_bookingId].status = BookingStatus.Active;
        emit BookingStatusChanged(_bookingId, BookingStatus.Active);
    }
    
    function completeTour(uint256 _bookingId) external onlyBookingParty(_bookingId) {
        require(bookings[_bookingId].status == BookingStatus.Active, "Tour not active");
        
        bookings[_bookingId].status = BookingStatus.Completed;
        bookings[_bookingId].completedAt = block.timestamp;
        
        // Release payment to guide (minus platform fee 5%)
        uint256 platformFee = bookings[_bookingId].totalPrice * 5 / 100;
        uint256 guidePayment = bookings[_bookingId].totalPrice - platformFee;
        
        payable(bookings[_bookingId].guide).transfer(guidePayment);
        payable(owner()).transfer(platformFee); // Platform fee to contract owner
        
        // Return security deposit to tourist
        payable(bookings[_bookingId].tourist).transfer(bookings[_bookingId].securityDeposit);
        
        emit PaymentReleased(_bookingId, bookings[_bookingId].guide, guidePayment);
        emit BookingStatusChanged(_bookingId, BookingStatus.Completed);
    }
    
    // === CHAT SYSTEM ===
    function sendChatMessage(
        uint256 _bookingId,
        string memory _message,
        string memory _messageType,
        string memory _ipfsHash
    ) external onlyBookingParty(_bookingId) {
        require(bookings[_bookingId].status != BookingStatus.Cancelled, "Booking cancelled");
        
        bookingChats[_bookingId].push(ChatMessage({
            bookingId: _bookingId,
            sender: msg.sender,
            message: _message,
            timestamp: block.timestamp,
            messageType: _messageType,
            ipfsHash: _ipfsHash
        }));
        
        emit ChatMessageSent(_bookingId, msg.sender, _messageType);
    }
    

    function submitRating(
        uint256 _bookingId,
        uint256 _rating,
        string memory _review
    ) external onlyBookingParty(_bookingId) {
        require(bookings[_bookingId].status == BookingStatus.Completed, "Booking not completed");
        require(_rating >= 1 && _rating <= 5, "Rating must be 1-5");
        
        Booking storage booking = bookings[_bookingId];
        
        if (msg.sender == booking.tourist) {
            require(booking.touristRating == 0, "Tourist already rated");
            booking.touristRating = _rating;
            booking.touristReview = _review;
            

            UserProfile storage guideProfile = users[booking.guide];
            guideProfile.rating = ((guideProfile.rating * guideProfile.totalReviews) + _rating) / (guideProfile.totalReviews + 1);
            guideProfile.totalReviews++;
        } else {
            require(booking.guideRating == 0, "Guide already rated");
            booking.guideRating = _rating;
            booking.guideReview = _review;
        }
        
        emit RatingSubmitted(_bookingId, msg.sender, _rating);
    }
    

    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return users[_user];
    }
    
    function getAllActivePackages() external view returns (TourPackage[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i < nextPackageId; i++) {
            if (tourPackages[i].isActive) {
                activeCount++;
            }
        }
        
        TourPackage[] memory activePackages = new TourPackage[](activeCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i < nextPackageId; i++) {
            if (tourPackages[i].isActive) {
                activePackages[currentIndex] = tourPackages[i];
                currentIndex++;
            }
        }
        
        return activePackages;
    }
    
    function getUserBookings(address _user) external view returns (Booking[] memory) {
        uint256[] memory userBookingIds = userBookings[_user];
        Booking[] memory userBookingList = new Booking[](userBookingIds.length);
        
        for (uint256 i = 0; i < userBookingIds.length; i++) {
            userBookingList[i] = bookings[userBookingIds[i]];
        }
        
        return userBookingList;
    }
    
    function getBookingChat(uint256 _bookingId) external view returns (ChatMessage[] memory) {
        return bookingChats[_bookingId];
    }
    
    function getGuidePackages(address _guide) external view returns (TourPackage[] memory) {
        uint256[] memory packageIds = guidePackages[_guide];
        TourPackage[] memory guidePackagesList = new TourPackage[](packageIds.length);
        
        for (uint256 i = 0; i < packageIds.length; i++) {
            guidePackagesList[i] = tourPackages[packageIds[i]];
        }
        
        return guidePackagesList;
    }
}