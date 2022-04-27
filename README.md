# Eth Price Oracle
This project outlines the steps needed to create an oracle that fetches the price of ETH from the Binance API and build a client that interacts with the oracle. Based on [CryptoZombies Lesson 14-16](https://cryptozombies.io/en/lesson/14). 


<p align="center">
<img src=https://github.com/agathakry/EthPriceOracle/blob/main/assets/eth.png width="10%">
</p>

## Requirements 
```
npm
node
truffle
```

## Installation 
Create and initialise the project (create package.json file)

```
mkdir EthPriceOracle
cd EthPriceOracle 
npm init -y
````

Install dependencies

```
npm i truffle openzeppelin-solidity loom-js loom-truffle-provider bn.js axios
````

Create two barebone directories: one for the oracle and one for the caller
```
mkdir oracle && cd oracle && npx truffle init && cd ..
mkdir caller && cd caller && npx truffle init && cd ..
```

## Getting started

Start oracle by running 

```solidity
node EthPriceOracle.js 
```

Start the client 

```solidity
node Client.js
```

## Deploying and Testing with Truffle and Ganache 
```
truffle compile
truffle migrate --network rinkeby 
truffle test --network rinkeby
```

## Security Notice
This project is only an example, do not deploy on mainnet, never share your private keys online.
