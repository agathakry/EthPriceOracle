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
    // create function takes oracle instance address and attach modifier
    function setOracleInstanceAddress (address _oracleInstanceAddress) public onlyOwner {
    // set oracle address 
    oracleAddress = _oracleInstanceAddress;
    // instantiate EthPriceOracle and sore in oracleInstance 
    oracleInstance = EthPriceOracleInterface(oracleAddress);
    }
}