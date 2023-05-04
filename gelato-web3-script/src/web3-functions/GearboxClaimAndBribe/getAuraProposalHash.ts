import ky from "ky";
import { AURA_GAUGE_CHOICES_URL, HH_API_URL } from "./constants";

type AuraGaugeChoiceType = {
  address: string;
  label: string;
};

type HiddenHandAuraProposalType = {
  proposal: number;
  proposalHash: string;
  title: string;
  proposalDeadline: number;
  totalvalue: string;
  voteCount: string;
  valuePerVote: string;
  bribes: [];
};

export default async function getAuraProposalHash(
  gaugeToBribeAddress: string
): Promise<string> {
  const auraGaugeChoices: any = await ky.get(AURA_GAUGE_CHOICES_URL).json();

  const gaugeLabel = (auraGaugeChoices as [AuraGaugeChoiceType]).find(
    (gaugeChoice) => gaugeChoice.address === gaugeToBribeAddress
  )?.label;
  if (!gaugeLabel) {
    throw "bribe address not found in aura gauge choices";
  }

  const hiddenHandAuraResponse: any = await ky.get(`${HH_API_URL}aura`).json();
  const hiddenHandAuraData = hiddenHandAuraResponse["data"] as [
    HiddenHandAuraProposalType
  ];

  const auraProposals = hiddenHandAuraData.filter(
    (proposal) => proposal.title === gaugeLabel
  );
  if (auraProposals.length === 0) {
    throw "Error when getting aura proposal, proposal not found";
  }
  if (auraProposals.length !== 1) {
    throw `Error when getting aura proposal, more than one proposal found for "${gaugeLabel}"`;
  }
  const auraProposalHash = auraProposals[0].proposalHash;

  return auraProposalHash;
}
