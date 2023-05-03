import ky from "ky";
import { HH_API_URL } from "./constants";

type HiddenHandBalancerProposalType = {
  proposal: string;
  proposalHash: string;
  title: string;
  proposalDeadline: number;
  totalvalue: string;
  voteCount: string;
  valuePerVote: string;
  bribes: [];
};

export default async function getBalancerProposalHash(
  gaugeToBribeAddress: string
): Promise<string> {
  const hiddenHandBalancerResponse: any = await ky
    .get(`${HH_API_URL}balancer`)
    .json();

  const hiddenHandBalancerData = hiddenHandBalancerResponse["data"] as [
    HiddenHandBalancerProposalType
  ];

  const balancerProposals = hiddenHandBalancerData.filter(
    (proposal) =>
      proposal.proposal.toLowerCase() === gaugeToBribeAddress.toLowerCase()
  );
  if (balancerProposals.length === 0) {
    throw "Error when getting balancer proposal, proposal not found";
  }
  if (balancerProposals.length !== 1) {
    throw `Error when getting balancer proposal, more than one proposal found for "${gaugeToBribeAddress}"`;
  }
  const balancerProposalHash = balancerProposals[0].proposalHash;

  return balancerProposalHash;
}
