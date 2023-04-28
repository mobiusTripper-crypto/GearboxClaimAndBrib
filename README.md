# periodicRewardsInjector

This contract is meant to be called by chainlink uplink.  It is used in cases where DAOs wish to add extra yields to their Balancer Gaugue emisisons and want more granular control than using the gauge system would allow.


The tests are based on LDO on Arbitrum where a multisig is curerntly doing these operations.

to run tests

```bash
pip3 install brownie
brownie test --network arbitrum-main-fork
```

If you do not have this network and the following lines to the end of your `~/.brownie/netowrk_config-yaml`
```yaml
  - name: Ganache-CLI (Arbitrum-Mainnet Fork)
    id: arbitrum-main-fork
    cmd: ganache-cli
    host: http://127.0.0.1
    timeout: 120
    cmd_settings:
      port: 8545
      gas_limit: 20000000
      accounts: 10
      evm_version: istanbul
      mnemonic: brownie
      fork: arbitrum-main

```

your .env file will require:
```
WEB3_INFURA_PROJECT_ID=
or other arbitrum RPC
```
LDO tokens are sent into the contract and are meant to be stored there.

A list is setup with gauges, amounts, and numbers of epochs.

The ChildChainStreamer has its own sense of epochs, this contract waits until the stream says it is ready, and then asks chainlink to trigger it and send in the alotted number of tokens.
