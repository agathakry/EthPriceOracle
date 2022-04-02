pragma solidity 0.5.0;
// declare and import interface for calling on other contract 
import "./EthPriceOracleInterface.sol";
// import Ownable contract
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

// make contract ownable
contract CallerContract is Ownable {
    // declare Ethprive variable 
    EthPriceOracleInterface private oracleInstance;

    // declare address named oracleaddress and make it private 
    address private oracleAddress; 

    // keep track of requests to oracle with a mapping 
    mapping(uint256 => bool) myRequests;

    // fire event front end notified oracle address got changed 
    event newOracleAddressEvent(address oracleAddress);

    // even tracking if request received
    event ReceivedNewRequestIdEvent(uint256 id);

    // create function takes oracle instance address and attach modifier
    function setOracleInstanceAddress (address _oracleInstanceAddress) public onlyOwner {
        // set oracle address 
        oracleAddress = _oracleInstanceAddress;
        // instantiate EthPriceOracle and sore in oracleInstance 
        oracleInstance = EthPriceOracleInterface(oracleAddress);

        // emit neworacle address 
        emit newOracleAddressEvent(oracleAddress);
    }
    // Define function update EthPrice 
    function updateEthPrice () public {
        // call oracle instance and store returned value 
        uint256 id = oracleInstance.getLatestEthPrice();

        // set myrequest parameter to true 
        myRequests[id] = true;

        // fire event recevied new request 
        emit ReceivedNewRequestIdEvent(id);

    }
}