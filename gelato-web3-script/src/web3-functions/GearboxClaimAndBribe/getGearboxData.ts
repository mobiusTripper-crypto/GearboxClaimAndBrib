import { Contract, ethers } from "ethers";
import ky from "ky";
import GearAirdropDistributorABI from "../../abis/GearAirdropDistributor.json";
import { GEARBOX_TREE_ADDRESS, GEARBOX_MERKLE_BASE_URL } from "./constants";

export default async function getGearboxData(
  multisigClaimAddress: string,
  provider: ethers.providers.StaticJsonRpcProvider
): Promise<{
  gearboxIndex: number;
  gearboxMerkleProof: string;
  rewardAmount: string;
}> {
  const contract = new Contract(
    GEARBOX_TREE_ADDRESS,
    GearAirdropDistributorABI,
    provider
  );
  try {
    const merkleRoot = (await contract.merkleRoot()) as string;

    const gearboxMerkleProofURL = `${GEARBOX_MERKLE_BASE_URL}mainnet_${
      ethers.utils.isHexString(merkleRoot) ? merkleRoot.slice(2) : merkleRoot
    }.json`;

    const gearboxResponse: any = await ky
      .get(gearboxMerkleProofURL, { timeout: 5_000, retry: 0 })
      .json();
    const gearboxData = gearboxResponse["claims"][multisigClaimAddress];

    const gearboxIndex = gearboxData.index as number;
    const gearboxMerkleProof = gearboxData.proof as string;
    const rewardAmount = gearboxData.amount as string;

    return { gearboxIndex, gearboxMerkleProof, rewardAmount };
  } catch (error) {
    throw `error in getGearboxMerkleProof: ${error.message} `;
  }
}
