import pytest
import time
from brownie import (
    interface,
    accounts,
    GearboxClaimAndBribe,
    Contract

)
from dotmap import DotMap
import pytest
from bal_addresses import *


##  Accounts

r = read_addressbook("mainnet")

GEAR = r["tokens/GEAR"]
HH_AURA = r["hidden_hand/aura_briber"]
HH_BAL = r["hidden_hand/balancer_briber"]
HH_VAULT = r["hidden_hand/bribe_vault"]

GEARBOX_MERKLE_URL = "https://raw.githubusercontent.com/Gearbox-protocol/rewards/master/merkle/"
GEARBOX_TREE="0xA7Df60785e556d65292A2c9A077bb3A8fBF048BC"
GEARBOX_MSIG="0x7b065Fcb0760dF0CEA8CFd144e08554F3CeA73D1"
GAUGE_TO_BRIB="0x19A13793af96f534F0027b4b6a3eB699647368e7" ## bb-g-usd
RUN_BLOCK = 17139067





@pytest.fixture(scope="module")
def admin():
    return accounts[4]


@pytest.fixture(scope="module")
def admin():
    return accounts[1]


@pytest.fixture(scope="module")
def tree():
    return Contract(GEARBOX_TREE)


@pytest.fixture(scope="module")
def upkeep_caller():
    return accounts[2]

@pytest.fixture(scope="module")
def deployer():
    return accounts[0]


@pytest.fixture()
def helper(deploy):
    return deploy.helper


@pytest.fixture(scope="module")
def token():
    return interface.IERC20(GEAR)


@pytest.fixture(scope="module")
def deploy(deployer, admin, upkeep_caller, token, tree):
    """
    Deploys, vault and test strategy, mock token and wires them up.
    """
    helper = GearboxClaimAndBribe.deploy(upkeep_caller, HH_AURA, HH_BAL, HH_VAULT, 50, {"from": deployer})
    helper.transferOwnership(admin, {"from": deployer})
    helper.acceptOwnership({"from": admin})
    return DotMap(
        helper=helper,
        token=token,
    )


