// Javascript component of oracle that fetches ETH price from binance API 
// building client that interacts with oracle 

// imports
const axios = require('axios')
const BN = require('bn.js')
const common = require('./utils/common.js')
const SLEEP_INTERVAL = process.env.SLEEP_INTERVAL || 2000
const PRIVATE_KEY_FILE_NAME = process.env.PRIVATE_KEY_FILE || './oracle/oracle_private_key'
const CHUNK_SIZE = process.env.CHUNK_SIZE || 3
const MAX_RETRIES = process.env.MAX_RETRIES || 5

// build artifacts stored in ORACLEJSON, bytecode versions of smart contracts ABIs
// ABI: how function can be called and how data is stored in machine readable format
// const to build artifacts live inside JSON file imported 
const OracleJSON = require('./oracle/build/contracts/EthPriceOracle.json')

// empty array to keep track of incoming requests 
var pendingRequests = []

// Create an async function getoraclecontract 
async function getOracleContract (web3js) {
    // store result of getId into const networkId so we can use it
    // async returns a promise and to call it, must prepend await so the code stops until promise resolved
    const networkId = await web3js.eth.net.getId()

    // return an instance of contract, we imported build artifacts and saved in OracleJSOn already
    return new web3js.eth.Contract(OracleJSON.abi, OracleJSON.networks[networkId].address)
}

// Declare function filterEvents to listen for events -> Lesson 15 chapter 2
async function filterEvents (oracleContract, web3js) {
    // listen to events 
    oracleContract.events.GetLatestEthPriceEvent( async (err, event) => {
        if (err) {
          console.error('Error on event', err)
          return
        }
        // Call async function addRequestToQueue 
        await addRequestToQueue(event)
      })
      // listen for latestEthPrice 
      oracleContract.events.SetLatestEthPriceEvent( async (err, event) => {
        if (err) {
          console.error('Error on event', err)
          return
        }
      })
}

// create an async function addequest to queue
async function addRequestToQueue (event) {
    // store the callerAddress and id that comes from parsing event parameter 
    const callerAddress = event.returnValues.callerAddress
    const id = event.returnValues.id

    // form an object and push it to array 
    pendingRequests.push({callerAddress, id})
}

// Make a function that breaks processing array to process easier
async function processQueue (oracleContract, ownerAddress) {
    // first declare variable processedrequests and set to 0 we change value later
    let processedRequests = 0

    // declare a while loop checking pending request in queue and smaller chunk size
    while (pendingRequests.length > 0 && processedRequests < CHUNK_SIZE ) {

        // call shift to remove first element of pending requests and store in req
        const req = pendingRequests.shift()

        // execute processrequest function 
        await processRequest(oracleContract, ownerAddress, req.id, req.callerAddress)

        // increment processedrequest
        processedRequests++

    }
}
// make a function to avoid infinite loops in case of network glitch and lots of requests pending 
