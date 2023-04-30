# GearboxClaimAndBrib

This contract is meant to be called by a web3 function in order to pay bribs.  It uses it's internal balance and settings around an amount  per round and a market split to decide how much to brib and where.

It is ownable, giving the owner the ability to sweep and do more brib ops.

The contract can be used to brib the entire balance each round and/or a specified amount.  On deployment all keeper bribs are disabled.  Set the amount per brib to allow bribs of fixed amounts each call, and set the enableBribAll to enable that.


More tests are still needed.  The OnlyOwner functions other than sweep and pause have not been well tested.  That being said owner can clear the contract of coinz with sweep, and the other functions just help the owner do stuff with coinz in the contract that can be done otherwise.  Should think about writing more tests or deleting these.