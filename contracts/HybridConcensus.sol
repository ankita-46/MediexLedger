// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MediexLedgerHMTC {
    // ========== Data Structures ==========

    // Roles available in the supply chain.
    enum Role {Hospital, Manufacturer, Seller, Distributor, Consumer }

    // Stakeholder struct (each node/address)
    struct Stakeholder {
        Role role;
        uint256 stake;          // PoS: Amount staked (in Wei)
        uint256 votes;          // DPoS: Votes delegated to the node
        bool isAuthority;       // PoA: True if the node represents a regulatory authority (FDA/WHO)
        uint256 powScore;       // PoW: Normalized score (0 to PRECISION)
        uint256 storageUptime;  // PoST: Normalized storage uptime score (0 to PRECISION)
        uint256 burnedTokenRatio; // PoB: Normalized ratio after token burning (0 to PRECISION)
        uint256 randomFactor;     // Random fairness factor (ξ) (0 to PRECISION)
        bool registered;
    }

    // Medicine batch structure for transaction example.
    struct MedicineBatch {
        uint256 batchNumber;
        uint256 expiry;
        address manufacturer;
        string details;
        bool validated;
        uint256 timestamp;
    }

    // ========== State Variables ==========

    // Mapping stakeholder address to its data.
    mapping(address => Stakeholder) public stakeholders;
    address[] public stakeholderList;

    // Global weights for HMTS score (using fixed-point with PRECISION).
    // α·W + β·S + γ·D + δ·A + ε·T + ζ·B + η·ξ = 1
    uint256 public alpha;    // PoW weight
    uint256 public beta;     // PoS weight
    uint256 public gamma;    // DPoS weight
    uint256 public delta;    // PoA weight
    uint256 public epsilon;  // PoST weight
    uint256 public zeta;     // PoB weight
    uint256 public eta;      // Random fairness weight
    uint256 constant PRECISION = 1e18; // Precision factor for normalization

    // Validator selection state.
    uint256 public numValidators;
    address[] public validators;

    // Medicine batch management.
    uint256 public batchCount;
    mapping(uint256 => MedicineBatch) public batches;

    // ========== Events ==========
    event Registered(address stakeholder, Role role);
    event StakeDeposited(address stakeholder, uint256 amount);
    event Delegated(address from, address to, uint256 votes);
    event ValidatorSelected(address[] validators);
    event BlockProposerSelected(address proposer);

    // ========== Constructor ==========
    /// @notice Initialize weight parameters and number of validators.
    /// @dev The weights must sum to PRECISION.
    constructor(
        uint256 _alpha,
        uint256 _beta,
        uint256 _gamma,
        uint256 _delta,
        uint256 _epsilon,
        uint256 _zeta,
        uint256 _eta,
        uint256 _numValidators
    ) {
        require(_alpha + _beta + _gamma + _delta + _epsilon + _zeta + _eta == PRECISION, "Weights must sum to 1");
        alpha = _alpha;
        beta = _beta;
        gamma = _gamma;
        delta = _delta;
        epsilon = _epsilon;
        zeta = _zeta;
        eta = _eta;
        numValidators = _numValidators;
    }

    // ========== Registration and Setup Functions ==========

    /// @notice Registration with initial PoW fee.
    /// @param _role The stakeholder role.
    /// @param _powScore A raw score (assumed 0 - 100) to simulate PoW.
    function register(Role _role, uint256 _powScore) external payable {
        require(!stakeholders[msg.sender].registered, "Already registered");
        // Simulate PoW identity verification fee (e.g., minimum 0.01 ETH)
        require(msg.value >= 0.01 ether, "Insufficient fee for PoW registration");

        Stakeholder storage s = stakeholders[msg.sender];
        s.role = _role;
        s.stake = 0;
        s.votes = 0;
        s.isAuthority = false; // Defaults to false. Authorities set via admin.
        s.powScore = _normalizeScore(_powScore);
        s.storageUptime = 0;
        s.burnedTokenRatio = 0;
        s.randomFactor = _getRandomFactor();
        s.registered = true;

        stakeholderList.push(msg.sender);
        emit Registered(msg.sender, _role);
    }

    /// @notice Set or revoke the authority flag (PoA).
    /// @param _stakeholder The address of the stakeholder.
    /// @param _isAuthority True if granting authority, false to revoke.
    /// @dev In production, restrict this to owner or a multi-sig authority.
    function setAuthority(address _stakeholder, bool _isAuthority) external {
        require(stakeholders[_stakeholder].registered, "Stakeholder not registered");
        stakeholders[_stakeholder].isAuthority = _isAuthority;
    }

    // ========== PoS, PoB, and DPoS Functions ==========

    /// @notice Deposit stake to improve PoS score.
    function depositStake() external payable {
        require(stakeholders[msg.sender].registered, "Not registered");
        stakeholders[msg.sender].stake += msg.value;
        emit StakeDeposited(msg.sender, msg.value);
    }

    /// @notice Simulate token burn to increase validator commitment (PoB).
    /// @param _amount The burn amount.
    function burnTokens(uint256 _amount) external {
        require(stakeholders[msg.sender].registered, "Not registered");
        // Simulation: update burned token ratio
        // Here, we define burned ratio as: burned / (stake + burned).
        Stakeholder storage s = stakeholders[msg.sender];
        uint256 currentStake = s.stake;
        s.burnedTokenRatio = (_amount * PRECISION) / (currentStake + _amount);
    }

    /// @notice Delegate votes to another stakeholder (DPoS).
    /// @param _to The delegatee's address.
    /// @param _votes The number of votes to delegate.
    function delegateVotes(address _to, uint256 _votes) external {
        require(stakeholders[msg.sender].registered, "Delegator not registered");
        require(stakeholders[_to].registered, "Delegatee not registered");
        stakeholders[_to].votes += _votes;
        emit Delegated(msg.sender, _to, _votes);
    }

    // ========== PoST Functions ==========

    /// @notice Update the storage uptime score (simulated PoST).
    /// @param _uptimeScore A normalized value (0 to PRECISION) representing uptime.
    function updateStorageUptime(uint256 _uptimeScore) external {
        require(stakeholders[msg.sender].registered, "Not registered");
        require(_uptimeScore <= PRECISION, "Invalid uptime score");
        stakeholders[msg.sender].storageUptime = _uptimeScore;
    }

    // ========== HMTS Calculation ==========

    /// @notice Compute the HMTS score for a stakeholder.
    /// @param _stakeholder Address of the stakeholder.
    /// @return HMTS score as a normalized value (0 to ~PRECISION).
    function computeHMTS(address _stakeholder) public view returns (uint256) {
        Stakeholder memory s = stakeholders[_stakeholder];
        require(s.registered, "Not registered");

        // Normalize stake and votes.
        uint256 normalizedStake = _normalizeStake(s.stake);
        uint256 normalizedVotes = _normalizeVotes(s.votes);
        uint256 authorityValue = s.isAuthority ? PRECISION : 0; // PoA: 1 if authority

        // Calculate HMTS score using the formula:
        // HMTS = α·W + β·S + γ·D + δ·A + ε·T + ζ·B + η·ξ
        uint256 HMTS =
            (alpha * s.powScore) / PRECISION +
            (beta * normalizedStake) / PRECISION +
            (gamma * normalizedVotes) / PRECISION +
            (delta * authorityValue) / PRECISION +
            (epsilon * s.storageUptime) / PRECISION +
            (zeta * s.burnedTokenRatio) / PRECISION +
            (eta * s.randomFactor) / PRECISION;
        return HMTS;
    }

    // Internal normalization helpers.
    function _normalizeStake(uint256 _stake) internal pure returns (uint256) {
        // Assume maximum stake of 100 ether for normalization.
        uint256 maxStake = 100 ether;
        if (_stake > maxStake) {
            return PRECISION;
        }
        return (_stake * PRECISION) / maxStake;
    }

    function _normalizeVotes(uint256 _votes) internal pure returns (uint256) {
        // Assume maximum votes of 1000.
        uint256 maxVotes = 1000;
        if (_votes > maxVotes) {
            return PRECISION;
        }
        return (_votes * PRECISION) / maxVotes;
    }

    function _normalizeScore(uint256 _score) internal pure returns (uint256) {
        // Assume incoming PoW score is between 0 and 100.
        uint256 maxScore = 100;
        if (_score > maxScore) {
            return PRECISION;
        }
        return (_score * PRECISION) / maxScore;
    }

    // A pseudo-random generator (Note: not secure—use Chainlink VRF or similar for production).
    function _getRandomFactor() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (PRECISION + 1);
    }

    // ========== Validator Selection and Block Proposer ==========

    /// @notice Compute HMTS scores and select the top candidate nodes as validators.
    function selectValidators() public {
        // Clear previous validator list.
        delete validators;
        uint256 len = stakeholderList.length;
        // Copy list for sorting.
        address[] memory candidates = stakeholderList;

        // Simple (inefficient) selection sort by HMTS in descending order.
        for (uint256 i = 0; i < len; i++) {
            for (uint256 j = i + 1; j < len; j++) {
                if (computeHMTS(candidates[j]) > computeHMTS(candidates[i])) {
                    address temp = candidates[i];
                    candidates[i] = candidates[j];
                    candidates[j] = temp;
                }
            }
        }
        // Select top numValidators.
        uint256 count = numValidators < len ? numValidators : len;
        for (uint256 i = 0; i < count; i++) {
            validators.push(candidates[i]);
        }
        emit ValidatorSelected(validators);
    }

    /// @notice Select a block proposer among the validators using round-robin with randomness.
    /// @return The selected proposer’s address.
    function selectBlockProposer() public returns (address) {
        require(validators.length > 0, "No validators available");
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % validators.length;
        address proposer = validators[randomIndex];
        emit BlockProposerSelected(proposer);
        return proposer;
    }

    /// @notice Authority (PoA) override for block proposer selection.
    /// @param _proposer The validator chosen to override as block proposer.
    function overrideBlockProposer(address _proposer) public {
        require(stakeholders[msg.sender].isAuthority, "Only authority can override");
        require(isValidator(_proposer), "Address is not a validator");
        emit BlockProposerSelected(_proposer);
    }

    /// @notice Check if an address is among the current validators.
    function isValidator(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    // ========== Medicine Batch Transaction Flow ==========

    /// @notice Manufacturer submits a medicine batch (simulates paying a PoW fee).
    /// @param _powFee The fee paid (for simulation purposes).
    /// @param _batchNumber A unique batch identifier.
    /// @param _expiry Expiry timestamp.
    /// @param _details Additional batch details.
    function submitBatch(
        uint256 _powFee,
        uint256 _batchNumber,
        uint256 _expiry,
        string calldata _details
    ) external payable {
        require(stakeholders[msg.sender].registered, "Not registered");
        require(stakeholders[msg.sender].role == Role.Manufacturer, "Only manufacturer can submit batch");
        // Ensure the manufacturer pays the required PoW fee.
        require(msg.value >= _powFee, "Insufficient fee for batch submission");
        batches[batchCount] = MedicineBatch({
            batchNumber: _batchNumber,
            expiry: _expiry,
            manufacturer: msg.sender,
            details: _details,
            validated: false,
            timestamp: block.timestamp
        });
        batchCount++;
    }

    /// @notice Validator confirms the medicine batch.
    /// @param _batchId The ID of the medicine batch.
    function validateBatch(uint256 _batchId) external {
        require(isValidator(msg.sender), "Only validators can validate");
        MedicineBatch storage batch = batches[_batchId];
        require(!batch.validated, "Batch already validated");
        batch.validated = true;
        // (Optional) Reward the validator or log additional details.
    }
}
