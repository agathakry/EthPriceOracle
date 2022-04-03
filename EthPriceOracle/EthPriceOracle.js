// Javascript component of oracle that fetches ETH price from binance API 
// building client that interacts with oracle 

// library for API access to Binance
const axios = require('axios')

// library to overcome 64-bit binary format IEEE 754 value for float numbers 
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

// function to access Binance API
async function retrieveLatestEthPrice () {
    const resp = await axios({
      url: 'https://api.binance.com/api/v3/ticker/price',
      params: {
        symbol: 'ETHUSDT'
      },
      method: 'get'
    })
    return resp.data.price
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
async function processRequest (oracleContract, ownerAddress, id, callerAddress) {
    // use let to declare variable retries
    let retries = 0

    // declare while loop that checks if retries are max
    while (retries < MAX_RETRIES) {
        // failed HTTP request throws an error, have to wrap code into a try/catch 
        try {
            // retrieve latest eth price and call oracle contract to set latest eth price
            const ethPrice = await retrieveLatestEthPrice() // function that talks to binance API

            // call setlatest price 
            await setLatestEthPrice(oracleContract, callerAddress, ownerAddress, ethPrice, id)

            // return 
            return

        } catch (error) {
            // retries variable starts counting with number 0
            // Add if statement comparing retries and MAX_tries -1 with strict comparison ===
            if (retries === MAX_RETRIES - 1) {
                // run setlatestEthprice and pass '0'
                await setLatestEthPrice(oracleContract, callerAddress, ownerAddress, '0', id)

                // if max number of retries reached, just return 
                return 
            }
            // increment retries
            retries++

        }
    }
}

// function to process the latest ETH price 
async function setLatestEthPrice (oracleContract, callerAddress, ownerAddress, ethPrice, id) {
    // ethPrice is actual value returned by Binance API
    // remove the . 
    ethPrice = ethPrice.replace('.', '')

    // create const multiplier to typecast as BN and initialise with 10**10
    const multiplier = new BN(10**10, 10)

    // convert to integer 
    const ethPriceInt = (new BN(parseInt(ethPrice), 10)).mul(multiplier)
    const idInt = new BN(parseInt(id))
    try {
      await oracleContract.methods.setLatestEthPrice(ethPriceInt.toString(), callerAddress, idInt.toString()).send({ from: ownerAddress })
    } catch (error) {
      console.log('Error encountered while calling setLatestEthPrice.')
      // Do some error handling
    }
  }

  // function that returns all values we need from oracle 
  async function init() {
      // run common.loadAccount returning object ownerAddress, web3js and client and unpack them
      const { ownerAddress, web3js, client } = common.loadAccount(PRIVATE_KEY_FILE_NAME)

      // instantiate contract calling getOracle contract and await promise 
      const oracleContract = await getOracleContract(web3js)

      // run the filterEvents 
      filterEvents(oracleContract, web3js)

      // return object containing our infos 
      return { oracleContract, ownerAddress, client }
  }