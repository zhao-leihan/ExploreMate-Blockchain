import { expect } from "chai";
import { ethers } from "hardhat";
import { ExplorMate } from "../typechain-types";

describe("ExplorMate", function () {
  let explorMate: ExplorMate;
  let owner: any, tourist: any, guide: any, other: any;

  beforeEach(async function () {
    [owner, tourist, guide, other] = await ethers.getSigners();
    
    const ExplorMateFactory = await ethers.getContractFactory("ExplorMate");
    explorMate = await ExplorMateFactory.deploy();
  });

  describe("User Registration", function () {
    it("Should register a tourist", async function () {
      await explorMate.connect(tourist).registerUser(
        "John Tourist",
        "john@email.com",
        "ipfs_hash_123",
        0 
      );

      const user = await explorMate.getUserProfile(tourist.address);
      expect(user.name).to.equal("John Tourist");
      expect(user.role).to.equal(0); 
      expect(user.isVerified).to.be.true; 
    });

    it("Should register a guide (needs verification)", async function () {
      await explorMate.connect(guide).registerUser(
        "Alice Guide",
        "alice@email.com",
        "ipfs_hash_456",
        1 
      );

      const user = await explorMate.getUserProfile(guide.address);
      expect(user.name).to.equal("Alice Guide");
      expect(user.role).to.equal(1); 
      expect(user.isVerified).to.be.false; 
    });
  });

  describe("Tour Package Management", function () {
    beforeEach(async function () {
      
      await explorMate.connect(guide).registerUser("Alice Guide", "alice@email.com", "ipfs_hash", 1);
      await explorMate.connect(owner).verifyUser(guide.address);
    });

    it("Should create a tour package", async function () {
      const languages = ["English", "Indonesian"];
      const specialties = ["Nature", "Food"];
      
      await explorMate.connect(guide).createTourPackage(
        "Bali Nature Tour",
        "Amazing nature experience in Bali",
        "Bali, Indonesia",
        languages,
        specialties,
        ethers.parseEther("0.1"), 
        2, 
        8  
      );

      const packages = await explorMate.getAllActivePackages();
      expect(packages.length).to.equal(1);
      expect(packages[0].title).to.equal("Bali Nature Tour");
    });
  });

  describe("Booking System", function () {
    beforeEach(async function () {
      
      await explorMate.connect(tourist).registerUser("John Tourist", "john@email.com", "ipfs_tourist", 0);
      await explorMate.connect(guide).registerUser("Alice Guide", "alice@email.com", "ipfs_guide", 1);
      await explorMate.connect(owner).verifyUser(guide.address);

      
      const languages = ["English"];
      const specialties = ["Nature"];
      await explorMate.connect(guide).createTourPackage(
        "Test Tour",
        "Test Description",
        "Test Location",
        languages,
        specialties,
        ethers.parseEther("0.1"), 
        1,
        8
      );
    });

    it("Should create a booking", async function () {
      const totalPrice = ethers.parseEther("0.2"); 
      const securityDeposit = totalPrice * 10n / 100n; 
      const totalPayment = totalPrice + securityDeposit;

      await explorMate.connect(tourist).createBooking(
        1, 
        Math.floor(Date.now() / 1000) + 3600, 
        2, 
        "Test Meeting Point",
        "No special requests",
        { value: totalPayment }
      );

      const bookings = await explorMate.getUserBookings(tourist.address);
      expect(bookings.length).to.equal(1);
      expect(bookings[0].totalPrice).to.equal(totalPrice);
    });
  });
});