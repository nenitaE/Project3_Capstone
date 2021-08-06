pragma solidity ^0.5.1;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./CarAuction.sol";
//import "@nomiclabs/builder/console.sol";
// take note of the modifiers used in each function
contract CarMarket is ERC721Full, Ownable {
    constructor() ERC721Full("CarMarket", "CBAY") public {}
    using Counters for Counters.Counter;
    Counters.Counter token_ids;
    // define the foundation_address - AKA the benficiary from the CarAuction contract
    address payable foundation_address = msg.sender;
    // keep track of all the car contracts
    // new auction call for every token
    mapping(uint => CarAuction) public auctions;
    // verify if the token_id AKA car exists
    modifier carRegistered(uint token_id) {
        require(_exists(token_id), " not registered!");
        _;
    }
    // deploy the auction for the car and title
    function createAuction(uint token_id) public onlyOwner {
        auctions[token_id] = new CarAuction(foundation_address);
    }
    // create the NFT
    function registerCar(string memory uri) public payable onlyOwner {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id);
     //   console.log(token_id);
    }
    function getCurrentToken() public view returns (uint){
    return token_ids.current();
    }
    // end auction and transfer ownership from Foundation to highest bidder
    function endAuction(uint token_id) public onlyOwner carRegistered(token_id) {
        CarAuction auction = auctions[token_id];
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
    }
    // a get function to see if the auction is ended or not
    // for a sepecific land parcel AKA token_id
    function auctionEnded(uint token_id) public view returns(bool) {
        CarAuction auction = auctions[token_id];
        return auction.ended();
    }
    // a get function to see the highest bidder
    function highestBid(uint token_id) public view carRegistered(token_id) returns(uint) {
        CarAuction auction = auctions[token_id];
        return auction.highestBid();
    }
    // a get function to see any pending returns
    function pendingReturn(uint token_id, address sender) public view carRegistered(token_id) returns(uint) {
        CarAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }
    // make a bid
    // wrapper for the auction contract bid function
    function bid(uint token_id) public payable carRegistered(token_id) {
        token_ids.increment();
        uint token_id = token_ids.current();
        CarAuction auction = auctions[token_id];
        // auction.bid(msg.sender) is what you may expect to see here
        // but that syntaxt will only send the required arg of sender address
        // to also capture the ETH need to interject .value(msg.value)()
        // now both the ETH and Address are being sent
        auction.bid.value(msg.value)(msg.sender);
    }
}