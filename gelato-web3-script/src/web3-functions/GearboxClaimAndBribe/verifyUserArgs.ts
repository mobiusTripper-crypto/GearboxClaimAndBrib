import { Web3FunctionUserArgs } from "@gelatonetwork/web3-functions-sdk";
import { ethers } from "ethers";

type userArgsType = {
  multisigClaimAddress: string;
  claimTokenAddress: string;
  gaugeToBribeAddress: string;
};

export default function verifyUserArgs(
  userArgs: Web3FunctionUserArgs
): userArgsType {
  const multisigClaimAddress = userArgs.multisigClaimAddress as string;
  if (!ethers.utils.isAddress(multisigClaimAddress)) {
    throw "userArgs parameter multisigClaimAddress is not a valid address";
  }

  const claimTokenAddress = userArgs.claimTokenAddress as string;
  if (!ethers.utils.isAddress(claimTokenAddress)) {
    throw "userArgs parameter claimTokenAddress is not a valid address";
  }

  const gaugeToBribeAddress = userArgs.gaugeToBribeAddress as string;
  if (!ethers.utils.isAddress(gaugeToBribeAddress)) {
    throw "userArgs parameter gaugeToBribeAddress is not a valid address";
  }

  return { multisigClaimAddress, claimTokenAddress, gaugeToBribeAddress };
}
