/** This example code is designed to quickly deploy an example contract using Remix.
 *     - Kovan ETH faucet: https://faucet.kovan.network/
 *     - Kovan LINK faucet: https://kovan.chain.link/
 */

pragma solidity ^0.6.0;

import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract APIConsumer is ChainlinkClient {
  
    bool public is_owner;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    bytes32 private in_name;
    bytes32 private out_name;
    
    /**
     * Network: Kovan - Alpha Chain
     * Chainlink - 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b
     * Chainlink - b7285d4859da4b289c7861db971baf0a - Get > Bytes32
     * Fee: 0.1 LINK
     */
    constructor() public {
        setPublicChainlinkToken();
        oracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
        jobId = "b7285d4859da4b289c7861db971baf0a";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target data.
     */
    function validateName(bytes32 _name, bytes32 location) public returns (bytes32 requestId) 
    {
        in_name = _name;
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        string memory base = "https://services1.arcgis.com/zdB7qR0BtYrg0Xpl/arcgis/rest/services/ODC_PROP_PARCELS_A/FeatureServer/245/query?geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&distance=0.0&units=esriSRUnit_Meter&returnGeometry=false&featureEncoding=esriDefault&outSR=4326&returnQueryGeometry=true&f=json&outFields=OWNER_NAME&geometry=";
        string memory loc = bytes32ToString(location);
        string memory url = string(abi.encodePacked(base, loc));
        
        // Set the URL to perform the GET request on
        request.add("get", url);
        request.add("path", "features.0.attributes.OWNER_NAME");
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of bytes32
     */ 
    function fulfill(bytes32 _requestId, bytes32 _name) public recordChainlinkFulfillment(_requestId)
    {
        out_name = _name;
        is_owner = in_name == out_name;
    }
    
    
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /**
     * Withdraw LINK from this contract
     * 
     * NOTE: DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES ONLY.
     */
    function withdrawLink() external {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }
}
