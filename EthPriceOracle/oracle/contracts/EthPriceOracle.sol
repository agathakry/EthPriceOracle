pragma solidity 0.5.0;

// Adding Roles (Lesson 16 Chapter 1) instead of Ownable (Lesson 15)
import "openzeppelin-solidity/contracts/access/Roles.sol";

//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CallerContractInterface.sol";

// create the ETH price oracle contract ownable 
//contract EthPriceOracle is Ownable {

// Lesson 16: remove Ownable and use roles instead
contract EthPriceOracle {
    // attach roles to the Roles.Role data type
    using Roles for Roles.Role;

    // declare Roles.Role variable private called owners
    Roles.Role private owners;

    // declare Roles.Role variable private called oracles
    Roles.Role private oracles;

    // generate random number for the request id (avoid collusions of oracles)
    uint private randNonce = 0;
    uint private modulus = 1000;
    mapping(uint256=>bool) pendingRequests;
    event GetLatestEthPriceEvent(address callerAddress, uint id);
    event SetLatestEthPriceEvent(uint256 ethPrice, address callerAddress);
    
    // define function that returns ethprice
    function getLatestEthPrice() public returns(uint256) {
        // increment randNonce 
        randNonce++;

        // compute random number between 0 and modulus and store in uint id
        uint id = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % modulus;

        // change pendingrequest mapping for this id to true
        pendingRequests[id] = true;

        // emit GetLatestEthPriceEvent 
        emit GetLatestEthPriceEvent(msg.sender, id);

        // return the id
        return id;
    }
    // create function setLatestEthpruce to retrieve from binance API
    function setLatestEthPrice(uint256 _ethPrice, address _callerAddress, uint256 _id) public onlyOwner {
        // require to check pending request is true 
        require(pendingRequests[_id], "This request is not in my pending list.");
        
        // remove id from the pendingRequests mapping 
        delete pendingRequests[_id];

        // create caller contract interface 
        CallerContractInterface callerContractInstance;

        // initialise instance with address of caller contract
        callerContractInstance = CallerContractInterface(_callerAddress);

        // run the caller contractInstance.callback function 
        callerContractInstance.callback(_ethPrice, _id);

        // emit the set latest Eth price 
        emit SetLatestEthPriceEvent(_ethPrice, _callerAddress);
    }
}