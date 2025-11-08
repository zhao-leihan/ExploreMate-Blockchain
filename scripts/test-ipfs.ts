import { IPFSService } from './ipfs-service';

async function testIPFS() {
  const ipfsService = new IPFSService();
  
  console.log('Testing IPFS Service...');
  
  // Test authentication
  const isAuthenticated = await ipfsService.testAuthentication();
  console.log('Authentication:', isAuthenticated ? 'SUCCESS' : 'FAILED');
  
  if (isAuthenticated) {
    // Test upload JSON data
    const testProfile = {
      name: "John Doe Tourist",
      email: "john@explormate.com",
      bio: "Adventure seeker and nature lover",
      languages: ["English", "Indonesian"],
      favoriteDestinations: ["Bali", "Yogyakarta", "Raja Ampat"]
    };
    
    try {
      const ipfsHash = await ipfsService.uploadUserProfile(testProfile);
      console.log('Profile uploaded to IPFS:', ipfsHash);
      
      // Test retrieve data
      const retrievedData = await ipfsService.getData(ipfsHash);
      console.log('Retrieved data:', retrievedData);
      
      // Generate URL untuk Flutter
      const ipfsUrl = `https://gateway.pinata.cloud/ipfs/${ipfsHash}`;
      console.log('IPFS URL:', ipfsUrl);
      
    } catch (error) {
      console.error('IPFS test failed:', error);
    }
  }
}

testIPFS().catch(console.error);