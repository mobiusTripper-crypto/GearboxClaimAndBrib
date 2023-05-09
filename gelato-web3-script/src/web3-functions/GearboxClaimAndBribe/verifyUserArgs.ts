import { Web3FunctionUserArgs } from "@gelatonetwork/web3-functions-sdk";
import { ethers } from "ethers";

type userArgsType = {
  multisigClaimAddress: string;
  tokenAddress: string;
  gaugeToBribeAddress: string;
  claimAndBribeContractAddress: string;
  minimumReward: string;
};

export default function verifyUserArgs(
  userArgs: Web3FunctionUserArgs
): userArgsType {
  const multisigClaimAddress = userArgs.multisigClaimAddress as string;
  if (!ethers.utils.isAddress(multisigClaimAddress)) {
    throw "userArgs parameter multisigClaimAddress is not a valid address";
  }

  const tokenAddress = userArgs.tokenAddress as string;
  if (!ethers.utils.isAddress(tokenAddress)) {
    throw "userArgs parameter tokenAddress is not a valid address";
  }

  const gaugeToBribeAddress = userArgs.gaugeToBribeAddress as string;
  if (!ethers.utils.isAddress(gaugeToBribeAddress)) {
    throw "userArgs parameter gaugeToBribeAddress is not a valid address";
  }

  const claimAndBribeContractAddress =
    userArgs.claimAndBribeContractAddress as string;
  if (!ethers.utils.isAddress(claimAndBribeContractAddress)) {
    throw "userArgs parameter claimAndBribeContractAddress is not a valid address";
  }

  const minimumReward = userArgs.minimumReward as string;
  if (!ethers.utils.isAddress(minimumReward)) {
    throw "userArgs parameter minimumReward is not a valid address";
  }

  return {
    multisigClaimAddress,
    tokenAddress,
    gaugeToBribeAddress,
    claimAndBribeContractAddress,
    minimumReward,
  };
}
