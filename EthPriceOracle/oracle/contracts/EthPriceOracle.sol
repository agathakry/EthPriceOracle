pragma solidity 0.5.0;

// Adding Roles (Lesson 16 Chapter 1) instead of Ownable (Lesson 15)
import "openzeppelin-solidity/contracts/access/Roles.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

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

    // use SafeMath to protect over/underflow 
    using SafeMath for uint256;

    // generate random number for the request id (avoid collusions of oracles)
    uint private randNonce = 0;
    uint private modulus = 1000;

    // initialise number of oracles (to keep track)
    uint private numOracles = 0; 

    // define threshould requests variable after which oracle should calculate price 
    uint private THRESHOLD = 0;

    mapping(uint256=>bool) pendingRequests;

    // define struct response 
    struct Response {
        address oracleAddress;
        address callerAddress;
        uint256 ethPrice;
        }
    // mapping that defines requestIdto response
    mapping (uint256=>Response[]) public requestIdToResponse;

    event GetLatestEthPriceEvent(address callerAddress, uint id);
    event SetLatestEthPriceEvent(uint256 ethPrice, address callerAddress);

    // Lesson 16
    // declare an event addoracleevent 
    event AddOracleEvent(address oracleAddress);

    // declare event that removes oracles
    event RemoveOracleEvent(address oracleAddress);

    // define constructor for ethPriceOracle for defining roles and ownership
    constructor (address _owner) public {
        // add _owner to the list of owners 
        owners.add(_owner);
    }

    // define function addOracle to set up new oracle
    function addOracle(address _oracle) public {
        // add a requre statement to make sure owners contain msg.sender 
        require(owners.has (msg.sender), "Not an owner");

        // add a require to make sure _oracle not already an oracle
        require(!oracles.has(_oracle), "Already an oracle!");

        // call oracle.add function 
        oracles.add(_oracle);

        // increment number of oracles
        numOracles++;

        // fire an event to add oracle
        emit AddOracleEvent(_oracle);
    }

    // define function that removes oracle and keeps track 
    function removeOracle (address _oracle) public {
        require(owners.has(msg.sender), "Not an owner!");
        require(oracles.has(_oracle), "Not an oracle!");
        // 3. Continue here
        // add require stamement numoracles >1 
        require(numOracles>1, "Do not remove the last oracle!");

        // call remove function 
        oracles.remove(_oracle);

        // decrement oraclenum
        numOracles--;

        // fire event 
        emit RemoveOracleEvent(_oracle);
  }
    
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
    // remove onlyOwner for Role instead
    //function setLatestEthPrice(uint256 _ethPrice, address _callerAddress, uint256 _id) public onlyOwner {
    function setLatestEthPrice(uint256 _ethPrice, address _callerAddress, uint256 _id) public {

        // require to make sure oracles has msg.sender 
        require(oracles.has(msg.sender), "Not an oracle!");
    
        // require to check pending request is true 
        require(pendingRequests[_id], "This request is not in my pending list.");

        // declare response variable resp stored in memory
        Response memory resp;

        // initialise the struct
        resp = Response(msg.sender, _callerAddress, _ethPrice);

        // push resp to array stored in requestIdToResponse[_id]
        requestIdToResponse[_id].push(resp);

        // define variable numresponses to check how many so far 
        uint numResponses = requestIdToResponse[_id].length;

        // add an if statement comparing numresponses and threshold 
        if (numResponses == THRESHOLD) {
            // Lesson 16 Chapter 8
            // Write a for loop that iterates through all responses for id and calculates the sum
            // to get average !!! This is not a secure (attackable by oracle manipulation)
            // Initialise uint computedEthPrice
            uint computedEthPrice = 0; 

            // declare for loop and goes through responses
            for (uint f = 0; f < requestIdToResponse[_id].length; f++) {
                // add to the sum and replace with safemath
                computedEthPrice = computedEthPrice.add(requestIdToResponse[_id][f].ethPrice);
            }

            // calculate average by dividing computedEthPrice 
            computedEthPrice =  computedEthPrice.div(numResponses);

            // remove id from the pendingRequests mapping 
            delete pendingRequests[_id];

            // remove id from requestIdtoresponse
            delete requestIdToResponse[_id];
            
            // create caller contract interface 
            CallerContractInterface callerContractInstance;

            // initialise instance with address of caller contract
            callerContractInstance = CallerContractInterface(_callerAddress);

            // run the caller contractInstance.callback function with new computed eth price
            callerContractInstance.callback(computedEthPrice, _id);

            // emit the set latest Eth price 
            emit SetLatestEthPriceEvent(computedEthPrice, _callerAddress);
        }
        


        
    }
}