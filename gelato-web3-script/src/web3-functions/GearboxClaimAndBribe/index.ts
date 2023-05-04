import {
  Web3Function,
  Web3FunctionContext,
} from "@gelatonetwork/web3-functions-sdk";
import { Contract, ethers, BigNumber } from "ethers";

import verifyUserArgs from "./verifyUserArgs";
import getGearboxData from "./getGearboxData";
import getAuraProposalHash from "./getAuraProposalHash";

import ClaimAndBribeABI from "../../abis/ClaimAndBribe.json";
import { MINIMUM_REWARD } from "./constants";
import getBalancerProposalHash from "./getBalancerProposalHash";

Web3Function.onRun(async (context: Web3FunctionContext) => {
  const { userArgs, gelatoArgs, provider } = context;

  try {
    const {
      multisigClaimAddress,
      tokenAddress,
      gaugeToBribeAddress,
      claimAndBribeContractAddress,
    } = verifyUserArgs(userArgs);

    const { gearboxMerkleProof, rewardAmount, gearboxIndex } =
      await getGearboxData(
        multisigClaimAddress,
        claimAndBribeContractAddress,
        provider
      );

    if (BigNumber.from(rewardAmount).lt(MINIMUM_REWARD)) {
      return {
        canExec: false,
        message: `Reward amount ${ethers.utils.formatEther(
          rewardAmount
        )} is less than minimum amount`,
      };
    }

    const balancerProposalHash = await getBalancerProposalHash(
      gaugeToBribeAddress
    );
    const auraProposalHash = await getAuraProposalHash(gaugeToBribeAddress);

    const claimAndBribe = new Contract(
      claimAndBribeContractAddress,
      ClaimAndBribeABI,
      provider
    );

    console.log(`claimAndBrib function
    index=${gearboxIndex}
    totalAmount=${rewardAmount}
    merkleProof=${gearboxMerkleProof}
    auraProp=${auraProposalHash}
    balProp=${balancerProposalHash}
    tokenAddress=${tokenAddress}`);

    return {
      canExec: true,
      callData: claimAndBribe.interface.encodeFunctionData("claimAndBribeAll", [
        gearboxIndex,
        rewardAmount,
        gearboxMerkleProof,
        auraProposalHash,
        balancerProposalHash,
        tokenAddress,
      ]),
    };
  } catch (error) {
    return { canExec: false, message: error };
  }
});
