import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import * as dotenv from 'dotenv';

dotenv.config();

export class IPFSService {
  private pinataApiKey: string;
  private pinataSecret: string;
  private pinataJWT: string;

  constructor() {
    this.pinataApiKey = process.env.PINATA_API_KEY || '';
    this.pinataSecret = process.env.PINATA_SECRET_API_KEY || '';
    this.pinataJWT = process.env.PINATA_JWT || '';
    
    if (!this.pinataApiKey || !this.pinataSecret) {
      console.warn('Pinata API keys not found. IPFS functionality will be limited.');
    }
  }

  // Upload file ke IPFS via Pinata
  async uploadFile(filePath: string): Promise<string> {
    try {
      const formData = new FormData();
      const fileStream = fs.createReadStream(filePath);
      
      formData.append('file', fileStream);
      
      const metadata = JSON.stringify({
        name: `ExplorMate-${Date.now()}`,
        keyvalues: {
          app: 'explormate',
          timestamp: Date.now().toString()
        }
      });
      formData.append('pinataMetadata', metadata);
      
      const options = JSON.stringify({
        cidVersion: 0,
      });
      formData.append('pinataOptions', options);

      const response = await axios.post(
        'https://api.pinata.cloud/pinning/pinFileToIPFS',
        formData,
        {
          maxBodyLength: Infinity,
          headers: {
            'Content-Type': `multipart/form-data; boundary=${formData.getBoundary()}`,
            'pinata_api_key': this.pinataApiKey,
            'pinata_secret_api_key': this.pinataSecret,
          },
        }
      );

      console.log('File uploaded to IPFS:', response.data.IpfsHash);
      return response.data.IpfsHash;
    } catch (error) {
      console.error('Error uploading to IPFS:', error);
      throw error;
    }
  }

  // Upload JSON data ke IPFS
  async uploadJSON(data: any): Promise<string> {
    try {
      const response = await axios.post(
        'https://api.pinata.cloud/pinning/pinJSONToIPFS',
        {
          pinataMetadata: {
            name: `ExplorMate-Data-${Date.now()}`,
            keyvalues: {
              app: 'explormate',
              type: 'metadata'
            }
          },
          pinataContent: data
        },
        {
          headers: {
            'pinata_api_key': this.pinataApiKey,
            'pinata_secret_api_key': this.pinataSecret,
          },
        }
      );

      console.log('JSON uploaded to IPFS:', response.data.IpfsHash);
      return response.data.IpfsHash;
    } catch (error) {
      console.error('Error uploading JSON to IPFS:', error);
      throw error;
    }
  }

  // Upload user profile data
  async uploadUserProfile(profileData: {
    name: string;
    email: string;
    bio?: string;
    experience?: string;
    certifications?: string[];
  }): Promise<string> {
    return this.uploadJSON({
      ...profileData,
      timestamp: Date.now(),
      app: 'ExplorMate'
    });
  }

  // Upload chat message dengan media
  async uploadChatMessage(messageData: {
    text: string;
    mediaType?: string;
    location?: { lat: number; lng: number };
    timestamp: number;
  }): Promise<string> {
    return this.uploadJSON({
      ...messageData,
      app: 'ExplorMate',
      version: '1.0'
    });
  }

  // Get data dari IPFS
  async getData(ipfsHash: string): Promise<any> {
    try {
      const response = await axios.get(`https://gateway.pinata.cloud/ipfs/${ipfsHash}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching from IPFS:', error);
      throw error;
    }
  }

  // Test connection to Pinata
  async testAuthentication(): Promise<boolean> {
    try {
      const response = await axios.get(
        'https://api.pinata.cloud/data/testAuthentication',
        {
          headers: {
            'pinata_api_key': this.pinataApiKey,
            'pinata_secret_api_key': this.pinataSecret,
          },
        }
      );
      console.log('Pinata authentication successful');
      return response.status === 200;
    } catch (error) {
      console.error('Pinata authentication failed:', error);
      return false;
    }
  }
}

// Utility function untuk Flutter nanti
export const formatIPFSUrl = (ipfsHash: string): string => {
  return `https://gateway.pinata.cloud/ipfs/${ipfsHash}`;
};

// Alternative public gateways
export const getIPFSGatewayUrl = (ipfsHash: string, gateway: string = 'pinata'): string => {
  const gateways = {
    pinata: `https://gateway.pinata.cloud/ipfs/${ipfsHash}`,
    cloudflare: `https://cloudflare-ipfs.com/ipfs/${ipfsHash}`,
    ipfs: `https://ipfs.io/ipfs/${ipfsHash}`,
    dweb: `https://dweb.link/ipfs/${ipfsHash}`
  };
  return gateways[gateway as keyof typeof gateways] || gateways.pinata;
};