// Creating an interface to call on other contracts 
pragma solidity 0.5.0;

contract EthPriceOracleInterface {

    function getLatestEthPrice() public returns(uint256);
}