// 1. caller/CallerContract.sol
// declare address named oracleaddress and make it private 
address oracleAddress private; 
// create function takes oracle instance address 
function setOracleInstanceAddress (address _oracleInstanceAddress) public {
// set oracle address 
oracleAddress = _oracleInstanceAddress
}