import brownie
import time
from brownie import chain
import pytest

STREAMER_STUCK = 6003155 ## Something that seems stuck in the streamer LDO
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
PROOF_LIST = ['0x11aa8ae448088fdb8a1efda71febbda71c4d73c3378446443ce2820cc2e3c1bc', '0xed730cb542effd1467050d93b99a45185e2b80472d2d686aeebd94e586cd567c', '0xa6ec70ee26cf1e42992785de1123c5de86fff042e997ad3cd5ffe5442d3ea975', '0x89e2a1341fb1ec16397ce79ed6b9d15d071be37d59573288cf50156cc7de0a27', '0xafb078e9689ea8d2ba9a72062e9638b3ad33bba8f56da96ebf78cefd5593667a', '0x950f0a7f2d35d3905b8eb0053d0c4326adeab20043a884df1f3235456b02c86b', '0x4e5ecb9adbeb76c75ab335d4f1cd959411f550c0debef21495941de057e2f8be', '0xb1e0d4d601bc19a8623340c51a286ebcd0711c58c5e2da93272acd66180ef6d6', '0x18560be87047eea6b0ef2dee48b3a6ad0be4180a7d41dc2eaa825338d3e45ab3', '0xccb1394b3b8b5e3467e8a187146479f33dc5ed82b7bb2a472efede792181b71b', '0xa5e9b54cfa42eb1563fb5b9afc62aa4279c7e682fa7e61bcdf95805e88328923', '0xa611a3107b8fab183251911559ba415506549ee1e7ddd9a4d9324904038b8177', '0x1df10ec847722b6888174de07368bb4b2f621a70d940f6ea5ade6878824d459a']
AURA_PROP = "0xaf115a58c45e37d92502eef6fbc55fa5098602a3c96e2507898eedc1b361acf5"
BAL_PROP = "0x4735553b91be8926bebb90d63080bc66942e8b953232f2257272e60476f1d7dd"
RUN_BLOCK = 17139060
def test_bribAll(token, deployer, upkeep_caller, helper, admin, tree):
    chain.sleep(helper.minWaitPeriodSeconds() +1)
    chain.mine()
    token.transfer(helper, 1000*10**token.decimals(), {"from": tree})
    helper.setBribAllEnabled(True, {"from": admin})
    tx = helper.bribAll(AURA_PROP, BAL_PROP, token.address, {"from": upkeep_caller})
    tx.events


def test_bribBoth(token, deployer, upkeep_caller, helper, admin, tree):
    chain.sleep(helper.minWaitPeriodSeconds() +1)
    chain.mine()
    token.transfer(helper, 1000*10**token.decimals(), {"from": tree})
    helper.setAmountPerRound(500*10**token.decimals(), {"from": admin})
    tx = helper.bribBoth(AURA_PROP, BAL_PROP, token.address, {"from": upkeep_caller})
    assert token.balanceOf(helper) == 500*10**token.decimals(), "Unexpected leftover balance in helper"
    tx.events



def test_pause_and_unpause(helper, admin, upkeep_caller, token, tree):
    # Pause the contract
    token.transfer(helper, 1000*10**token.decimals(), {"from": tree})
    helper.setBribAllEnabled(True, {"from": admin})
    helper.pause({"from": admin})
    assert helper.paused({"from": admin}) is True
    with brownie.reverts("Pausable: paused"):
        helper.bribAll(AURA_PROP, BAL_PROP, token.address, {"from": upkeep_caller})
    # Unpause the contract
    helper.unpause({"from": admin})
    assert helper.paused({"from": admin}) is False


def test_sweep(admin, helper, token, tree):
    balance = token.balanceOf(admin)
    token.transfer(helper, token.balanceOf(tree)/10, {"from": tree})
    helper.sweep(token, admin, {"from": admin})
    assert token.balanceOf(admin) > balance
    assert token.balanceOf(helper) == 0


def test_ownable(helper, admin, deployer, token, tree, upkeep_caller):
    token.transfer(helper, 42069, {"from": tree})
    with brownie.reverts():
        tx = helper.bribAll(AURA_PROP, BAL_PROP, token.address, {"from": admin})
    with brownie.reverts():
        helper.sweep(token, admin, {"from": deployer})
    helper.sweep(token, admin, {"from": admin})

def test_double_brib_all(helper, upkeep_caller, tree, token, admin):
    chain.sleep(helper.minWaitPeriodSeconds() +1)
    chain.mine()
    token.transfer(helper, 500*10**token.decimals(), {"from": tree})
    helper.setBribAllEnabled(True, {"from": admin})
    tx = helper.bribAll(AURA_PROP, BAL_PROP, token.address, {"from": upkeep_caller})
    token.transfer(helper, 500*10**token.decimals(), {"from": tree})
    with brownie.reverts():
        tx = helper.bribAll(AURA_PROP, BAL_PROP, token.address, {"from": upkeep_caller})
    chain.sleep(helper.minWaitPeriodSeconds() +1)
    chain.mine()
    tx = helper.bribAll(AURA_PROP, BAL_PROP, token.address, {"from": upkeep_caller})
