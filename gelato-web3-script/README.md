# Gearbox Claim and Bribe - Gelato web3 script <!-- omit in toc -->

This is a Gelato script to claim Gearbox rewards and post those rewards as bribe to Aura and Balancer on Hidden Hand

This is a clone of the templat (https://github.com/gelatodigital/web3-functions-template.git)

## Project Setup

1. Install project dependencies

```
npm install
```

2. Configure your local environment:

- Copy `.env.example` to init your own `.env` file

```
cp .env.example .env
```

- Complete your `.env` file with your private settings

```
PROVIDER_URL="" # your provider URL (e.g. https://eth-mainnet.alchemyapi.io/v2/YOUR_ALCHEMY_ID)
PRIVATE_KEY="" # optional: only needed if you wish to create a task from the CLI instead of the UI
```

## Test your web3 function

### Calling your web3 function

- Use `npx w3f test FILENAME` command to test your function

- Options:

  - `--show-logs` Show internal Web3 Function logs
  - `--debug` Show Runtime debug messages
  - `--chain-id=[number]` Specify the chainId to be used for your Web3 Function (default: `5` for Goerli)
  - `--user-args=[key]:[value]` Set your Web3 Function user args

- Example:<br/> `npx w3f test src/web3-functions/GearboxClaimAndBribe/index.ts --show-logs`

- userArgs:

```
multisigClaimAddress: address of the wallet with the GEAR rewards
claimTokenAddress: token address reward token (GEAR)
gaugeToBribeAddress: address of the pool gauge to bribe (bb-g-USD)
```
