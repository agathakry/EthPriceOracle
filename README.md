# oracle-builder
Building an Oracle CryptoZombies Lesson 14

### Installation 
mkdir EthPriceOracle
cd EthPriceOracle
// initialise the project -> creates package.json file
npm init -y
// install dependencies 
npm i truffle openzeppelin-solidity loom-js loom-truffle-provider bn.js axios

// CREATE TWO BAREBONE DIRECTORY, ONE FOR ORACLE    and one for caller 
mkdir oracle && cd oracle && npx truffle init && cd ..
mkdir caller && cd caller && npx truffle init && cd ..

d
//EthPriceOracle.js 
We will create a Javascript component of oracle that fetches ETH price from binance API then build classic client that interacts with the oracle 

Start oracle by running 

```solidity
node EthPriceOracle.js 
```

Start the client 

```solidity
node Client.js
```