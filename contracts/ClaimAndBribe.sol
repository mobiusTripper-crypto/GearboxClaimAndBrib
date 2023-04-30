// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "interfaces/gearbox/IAirdropDistributor.sol";
import "interfaces/hiddenhand/IBribers.sol";


/**
 * @title The Gearbox Claim and Bribe  Contract
 * @author tritium.eth
 * @notice This contract is meant to be called by a web3 function.   It claims rewards from a Gearbox style merkle tree, and then pays out bribs on hidden hands
 * @notice The contract includes the ability to withdraw eth and sweep all ERC20 tokens including the managed token to any address by the owner and admin functionality to change the bribe destination.
 */
contract GearboxClaimAndBrib is ConfirmedOwner, Pausable {
    event gasTokenWithdrawn(uint256 amountWithdrawn, address recipient);
    event KeeperAddressChange(address oldAddress, address newAddress);
    event GearboxTreeAddressChange(address oldAddress, address newAddress);
    event BalBriberAddressChange(address oldAddress, address newAddress);
    event AuraBriberAddressChange(address oldAddress, address newAddress);

    event ERC20Swept(address indexed token, address recipient, uint256 amount);
    event ClaimMade();
    event WrongCaller(address sender, address keeperAddress);
    event PctBalBPSUpdated(uint256 oldBPS, uint256 newBPS);
    event AmtPerRoundUpdated(uint256 oldAmount, uint256 amount);
    event Approve(address token);
    event Unapprove(address token);
    event BribeAllEnabledChanged(bool old, bool changedTo);

    error OnlyKeeper();
    error ZeroAddress();



    address public keeperAddress;
    IAirdropDistributor public gearboxTree;
    address public HHVault;
    IAuraBribe public auraHHBriber;
    IBalancerBribe public balHHBriber;
    bytes32 public last_root;
    uint256 public pct_bal_bps;
    uint256 public amount_per_round;
    bool public brib_all_enabled;



    constructor(address _keeperAddress, IAuraBribe _auraBribe, IBalancerBribe _balBribe, address _HHvault, uint256 balbps)
    ConfirmedOwner(msg.sender) {
        setKeeper(_keeperAddress);
        setAuraBriber(_auraBribe);
        setBalBriber(_balBribe);
        HHVault = _HHvault;
        setPctBalBPS(balbps);
    }


    function claimAndBribeAll (
        uint256 index,
        uint256 totalAmount,
        bytes32[] calldata merkleProof,
        bytes32 auraProp, bytes32 balProp,
        address tokenAddress
    ) external onlyKeeper whenNotPaused {
        claim(index, totalAmount, merkleProof);
        bribAll(auraProp, balProp, tokenAddress);
    }

   /* @notice Bribs entire contract balance of the gvien token to both markets based on the contract defined split
   * @param auraProp The Hidden Hands proposal ID on the Aura market to brib
   * @param balProp The Hidden Hands proposal ID on the Bal market to brib
   * @param token The address to pay bribs in
   */
    function bribAll(
        bytes32 auraProp,
        bytes32 balProp,
        address tokenAddress
    ) public onlyKeeper whenNotPaused {
        require(brib_all_enabled, "brib_all_enabled must be set to true for the keeper to call this function");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) > 0, "No balance of the specified token in the contract to brib ser");
        uint256 amount = token.balanceOf(address(this));
        bribSplit(auraProp, balProp, tokenAddress, amount);
    }

    /* @notice Bribs the both tokens given the specified split and amount.
    * @param auraProp The Hidden Hands proposal ID on the Aura market to brib
    * @param balProp The Hidden Hands proposal ID on the Bal market to brib
    * @param token The address to pay bribs in
    * @param balAmount How much in wei
    * @param auraAmount How much in wei
    */
    function bribBoth(bytes32 auraProp,
        uint256 auraAmount,
        bytes32 balProp,
        uint256 balAmount,
        address tokenAddress
    ) external onlyKeeper whenNotPaused {
        IERC20 token = IERC20(tokenAddress);
        require(amount_per_round >= token.balanceOf(address(this)), "amount_per_round more than balance");
        require(amount_per_round > 0, "amount_per_round is 0, set it or use another function");
        bribSplit(auraProp, balProp, tokenAddress, pct_bal_bps);
    }

    /* @notice Claims coinz from the gear tree the values here must be pulled from offchain
   * @param index The current tree index
   * @param totalAmount The total amount earned by the address
   * @param merkleProof Merkle Proofs
   */
    function claim (
        uint256 index,
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) public  onlyKeeper whenNotPaused {
        gearboxTree.claim(index, address(this), totalAmount, merkleProof);
        emit ClaimMade();
    }



    /* @notice Bribs the specified amount on the bal market
   * @param proposal The Hidden Hands proposal ID to brib
   * @param token The address to pay bribs in
   * @param amount How much in wei
   */
    function bribBal(bytes32 proposal,
        address tokenAddress,
        uint256 amount
    ) public onlyOwner  {
        IERC20 token = IERC20(tokenAddress);
        _bribBal(proposal, token,  amount);
    }


    /* @notice Bribs the specified amount on the aura market
   * @param proposal The Hidden Hands proposal ID to brib
   * @param token The address to pay bribs in
   * @param amount How much in wei
   */
    function bribAura(bytes32 proposal,
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        _bribAura(proposal, token,  amount);
    }

     /* @notice Bribs the specified amount of the given token to the given proposal split between aura and bal markets.
    * @param auraProp The Hidden Hands proposal ID on the Aura market to brib
    * @param balProp The Hidden Hands proposal ID on the Bal market to brib
    * @param token The address to pay bribs in
    * @param balAmount How much in wei
    * @param auraAmount How much in wei
    */
    function bribBothAmounts(bytes32 auraProp,
        uint256 auraAmount,
        bytes32 balProp,
        uint256 balAmount,
        address tokenAddress
    ) public onlyOwner  {
        IERC20 token = IERC20(tokenAddress);
        require(auraAmount + balAmount >= token.balanceOf(address(this)), "Amount more than balance");
        _bribBal(balProp, token, balAmount);
        _bribAura(auraProp, token, auraAmount);
    }


     /* @notice Bribs the specified amount to both markets based on the contract defined split
    * @param auraProp The Hidden Hands proposal ID on the Aura market to brib
    * @param balProp The Hidden Hands proposal ID on the Bal market to brib
    * @param token The address to pay bribs in
    * @param amount How much in wei
    */

    function bribSplit(bytes32 auraProp,
        bytes32 balProp,
        address tokenAddress,
        uint256 amount
    ) private  {
        IERC20 token = IERC20(tokenAddress);
        uint256 balAmount = amount * pct_bal_bps / 10000;
        uint256 auraAmount = amount - balAmount;
        require(auraAmount + balAmount >= token.balanceOf(address(this)), "Amount more than balance");
        _approveToken(tokenAddress, amount);
        _bribAura(auraProp, token, auraAmount);
        _bribBal(balProp, token, balAmount);
    }


    function _bribAura(bytes32 proposal,
        IERC20 token,
        uint256 amount
    ) private  {
        if(amount == 0){return;}
        require(token.balanceOf(address(this)) >= amount, "Contract does not have sufficient balance for the specified brib.");
        auraHHBriber.depositBribeERC20(proposal, address(token), amount);
    }

    function _bribBal(bytes32 proposal,
        IERC20 token,
        uint256 amount
    ) private  {
        if(amount == 0){return;}
        require(token.balanceOf(address(this)) >= amount, "Contract does not have sufficient balance for the specified brib.");
        balHHBriber.depositBribeERC20(proposal, address(token), amount);
    }

     /* @notice Withdraws gas from the contract (contract doesn't use gas(
    * @param amount The amount of eth (in wei) to withdraw
    * @param recipient The address to pay
    */
    function withdrawGasToken(uint256 amount, address payable recipient) public onlyOwner {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }
        emit gasTokenWithdrawn(amount, recipient);
        recipient.transfer(amount);
    }

    /**
     * @notice Sweep the full contract's balance for a given ERC-20 token
   * @param token The ERC-20 token which needs to be swept
   * @param recipient The address to pay
   */
    function sweep(address token, address recipient) public onlyOwner  {
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit ERC20Swept(token, recipient, balance);
        SafeERC20.safeTransfer(IERC20(token), recipient, balance);
    }


    /**
     * @notice Sets the keeper  address
   */
    function setKeeper(address _keeperAddress) public onlyOwner {
        emit KeeperAddressChange(keeperAddress, keeperAddress);
        keeperAddress = _keeperAddress;
    }

    /**
    * @notice Sets the Gearbox tree address
   */
    function setGearboxTree(IAirdropDistributor gearboxTreeAddress) public onlyOwner {
        emit GearboxTreeAddressChange(address(gearboxTree), address(gearboxTreeAddress));
        gearboxTree = gearboxTreeAddress;
    }

    function setAuraBriber(IAuraBribe auraBriberAddress) public onlyOwner {
        emit AuraBriberAddressChange(address(auraHHBriber), address(auraBriberAddress));
        auraHHBriber = auraBriberAddress;
    }

    function setBalBriber(IBalancerBribe balBriberAddress) public onlyOwner {
        emit BalBriberAddressChange(address(balHHBriber), address(balBriberAddress));
        balHHBriber = balBriberAddress;
    }

    /**
    * @notice If set to true, the keeper will be able to call the bribAll function which bribs the entire contract balance.
   */
    function setBribAllEnabled(bool enabled)  public onlyOwner {
        emit BribeAllEnabledChanged(brib_all_enabled, enabled);
        brib_all_enabled = enabled;
    }


    function approveToken(address tokenAddress, uint256 amount) public onlyOwner whenNotPaused {
        _approveToken(tokenAddress, amount);
    }


    function _approveToken(address tokenAddress, uint256 amount) private  whenNotPaused {
        IERC20 token = IERC20(tokenAddress);
        SafeERC20.safeApprove(token, HHVault, amount);
        emit Approve(address(token));
    }


    function unapproveToken(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        SafeERC20.safeApprove(token, HHVault, 0);
        emit Unapprove(address(token));
    }

    /**
     * @notice Sets the bps percent that should go to balancer
   */
    function setPctBalBPS(uint256 bps) public onlyOwner {
        require(bps <= 10000, "Can't have more than 100% brib split ser.");
        emit PctBalBPSUpdated(pct_bal_bps, bps);
        pct_bal_bps = bps;
    }
    /**
     * @notice Sets the amount per round called when the keeper calls bribBoth.  If set to 0 bribBoth is disabled.
   */
    function setAmountPerRound(uint256 amount) public onlyOwner {
        emit AmtPerRoundUpdated(amount_per_round, amount);
        amount_per_round = amount;
    }
    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
   */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
   */
    function unpause() public onlyOwner {
        _unpause();
    }

    modifier onlyKeeper() {
        if (msg.sender != keeperAddress) {
            emit WrongCaller(msg.sender, keeperAddress);
            revert OnlyKeeper();
        }
        _;
    }
}
