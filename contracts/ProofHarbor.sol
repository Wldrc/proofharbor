// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal ERC-721 interface: only what ProofHarbor needs to check
///         whether an address holds an Agent ID.
interface IERC721Minimal {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title ProofHarbor
/// @notice A harbor for Agent ID holders: daily check-ins, on-chain proofs of
///         activity and work, and a public guestbook.
///
///         Design constraints (by intention, not omission):
///         - There is NO owner and there are no privileged functions.
///         - There are NO payable functions; this contract can never hold or
///           move funds, and it never asks for token approvals.
///         - There is NO endorsement / cross-confirmation feature.
///         - Every write function is gated on holding an Agent ID
///           (the registry's balanceOf(msg.sender) must be > 0).
contract ProofHarbor {
    /// @notice Proof kinds.
    uint8 public constant KIND_ACTIVITY = 0;
    uint8 public constant KIND_WORK = 1;

    uint256 private constant MAX_NOTE_BYTES = 140;
    uint256 private constant MAX_MESSAGE_BYTES = 280;
    uint256 private constant SECONDS_PER_DAY = 86400;

    /// @notice The Agent ID registry (ERC-721). Set once at deployment.
    IERC721Minimal public immutable agentIdRegistry;

    struct Proof {
        uint8 kind; // KIND_ACTIVITY (0) or KIND_WORK (1)
        bytes32 refHash; // external tx hash for WORK proofs; bytes32(0) for ACTIVITY
        string note; // short note for WORK proofs; empty for ACTIVITY
        uint256 timestamp; // block.timestamp when recorded
        uint256 day; // UTC day index (timestamp / 86400)
        uint256 streak; // holder's streak at recording time
    }

    struct Stats {
        uint256 currentStreak;
        uint256 totalCheckIns;
        uint256 lastCheckInDay;
    }

    mapping(address => Stats) private _stats;
    mapping(address => Proof[]) private _proofs;
    mapping(address => string) private _guestbook;
    mapping(address => uint256) private _guestbookUpdatedAt;
    mapping(address => bool) private _isKnownHolder;
    address[] private _holders;
    uint256 private _proofCountTotal;

    event CheckedIn(address indexed user, uint256 day, uint256 streak);
    event ProofRecorded(
        address indexed user,
        uint256 index,
        uint8 kind,
        bytes32 refHash,
        uint256 day
    );
    event GuestbookSigned(address indexed user);

    constructor(address registry) {
        require(registry != address(0), "ProofHarbor: registry is zero address");
        agentIdRegistry = IERC721Minimal(registry);
    }

    modifier onlyHolder() {
        require(
            agentIdRegistry.balanceOf(msg.sender) > 0,
            "ProofHarbor: not an Agent ID holder"
        );
        _;
    }

    /// @notice Current UTC day index.
    function currentDay() public view returns (uint256) {
        return block.timestamp / SECONDS_PER_DAY;
    }

    /// @notice Daily check-in. At most once per UTC day per holder.
    ///         Maintains the consecutive-day streak and automatically records
    ///         an ACTIVITY proof for the check-in.
    function checkIn() external onlyHolder {
        uint256 today = currentDay();
        Stats storage s = _stats[msg.sender];
        require(s.lastCheckInDay != today, "ProofHarbor: already checked in today");

        if (s.totalCheckIns > 0 && s.lastCheckInDay == today - 1) {
            s.currentStreak += 1;
        } else {
            s.currentStreak = 1;
        }
        s.totalCheckIns += 1;
        s.lastCheckInDay = today;

        _registerHolder(msg.sender);

        _proofs[msg.sender].push(
            Proof({
                kind: KIND_ACTIVITY,
                refHash: bytes32(0),
                note: "",
                timestamp: block.timestamp,
                day: today,
                streak: s.currentStreak
            })
        );
        _proofCountTotal += 1;
        uint256 index = _proofs[msg.sender].length - 1;

        emit CheckedIn(msg.sender, today, s.currentStreak);
        emit ProofRecorded(msg.sender, index, KIND_ACTIVITY, bytes32(0), today);
    }

    /// @notice Submit a WORK proof referencing the hash of a real external
    ///         transaction, with a short note (max 140 bytes).
    function submitProof(bytes32 refHash, string calldata note) external onlyHolder {
        require(bytes(note).length <= MAX_NOTE_BYTES, "ProofHarbor: note too long");
        uint256 today = currentDay();

        _registerHolder(msg.sender);

        _proofs[msg.sender].push(
            Proof({
                kind: KIND_WORK,
                refHash: refHash,
                note: note,
                timestamp: block.timestamp,
                day: today,
                streak: _stats[msg.sender].currentStreak
            })
        );
        _proofCountTotal += 1;
        uint256 index = _proofs[msg.sender].length - 1;

        emit ProofRecorded(msg.sender, index, KIND_WORK, refHash, today);
    }

    /// @notice Sign the public guestbook (max 280 bytes). One entry per holder;
    ///         signing again updates the entry.
    function signGuestbook(string calldata message) external onlyHolder {
        require(
            bytes(message).length <= MAX_MESSAGE_BYTES,
            "ProofHarbor: message too long"
        );

        _registerHolder(msg.sender);

        _guestbook[msg.sender] = message;
        _guestbookUpdatedAt[msg.sender] = block.timestamp;

        emit GuestbookSigned(msg.sender);
    }

    // ------------------------------------------------------------------ views

    /// @notice Number of unique Agent ID holders who have ever interacted.
    function totalHolders() external view returns (uint256) {
        return _holders.length;
    }

    /// @notice Total number of proofs recorded across all holders.
    function proofCountTotal() external view returns (uint256) {
        return _proofCountTotal;
    }

    /// @notice Whether an address has interacted at least once.
    function isKnownHolder(address user) external view returns (bool) {
        return _isKnownHolder[user];
    }

    /// @notice Stats for one holder:
    ///         (currentStreak, totalCheckIns, proofCount, lastCheckInDay).
    function holderStats(
        address user
    )
        external
        view
        returns (
            uint256 currentStreak,
            uint256 totalCheckIns,
            uint256 proofCount,
            uint256 lastCheckInDay
        )
    {
        Stats storage s = _stats[user];
        return (s.currentStreak, s.totalCheckIns, _proofs[user].length, s.lastCheckInDay);
    }

    /// @notice All proof records of a holder.
    function proofsOf(address user) external view returns (Proof[] memory) {
        return _proofs[user];
    }

    /// @notice A page of a holder's proof records.
    function proofsOf(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (Proof[] memory page) {
        Proof[] storage all = _proofs[user];
        if (offset >= all.length || limit == 0) {
            return new Proof[](0);
        }
        uint256 end = offset + limit;
        if (end > all.length) end = all.length;
        page = new Proof[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            page[i - offset] = all[i];
        }
    }

    /// @notice Number of proofs a holder has recorded.
    function proofCountOf(address user) external view returns (uint256) {
        return _proofs[user].length;
    }

    /// @notice Guestbook entry of a holder: (message, updatedAt).
    function guestbookOf(
        address user
    ) external view returns (string memory message, uint256 updatedAt) {
        return (_guestbook[user], _guestbookUpdatedAt[user]);
    }

    /// @notice A page of the unique-holder address list, so a frontend can
    ///         build stats and a leaderboard.
    function holdersPage(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory page) {
        if (offset >= _holders.length || limit == 0) {
            return new address[](0);
        }
        uint256 end = offset + limit;
        if (end > _holders.length) end = _holders.length;
        page = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            page[i - offset] = _holders[i];
        }
    }

    // --------------------------------------------------------------- internal

    function _registerHolder(address user) internal {
        if (!_isKnownHolder[user]) {
            _isKnownHolder[user] = true;
            _holders.push(user);
        }
    }
}
