// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
import 'base64-sol/base64.sol';



contract Contest {
    struct Contestant {
        uint id;
        string name;
        uint voteCount;
        string party;
        uint age;
        string qualification;
        string partyLogo;
    }

    struct Voter {
        bool hasVoted;
        uint vote;
        bool isRegistered;
    }

    address public admin;
    mapping(uint => Contestant) public contestants; 
    mapping(address => Voter) public voters;
    uint public contestantsCount;
    enum PHASE { reg, voting, done }
    PHASE public state;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier validState(PHASE x) {
        require(state == x, "Invalid state for this action");
        _;
    }
    
    constructor() public{
        admin = msg.sender;
        state = PHASE.reg;
    }

    function changeState(PHASE x) public onlyAdmin {
        require(uint(x) > uint(state), "Invalid state transition");
        state = x;
    }

    function addContestant(
        string memory _name,
        string memory _party,
        uint _age,
        string memory _qualification,
        string memory _partyLogo
    ) public onlyAdmin validState(PHASE.reg) {
        require(bytes(_name).length > 0, "Name cannot be empty");
        for (uint i = 1; i <= contestantsCount; i++) {
            require(
                keccak256(abi.encodePacked(contestants[i].name)) !=
                    keccak256(abi.encodePacked(_name)),
                "Contestant already exists"
            );
        }
        contestantsCount++;
        bytes memory partyLogoBytes = bytes(_partyLogo);
        if (partyLogoBytes.length > 0) {
            string memory partyLogoBase64 = Base64.encode(bytes(_partyLogo));
            contestants[contestantsCount] = Contestant(
                contestantsCount,
                _name,
                0,
                _party,
                _age,
                _qualification,
                partyLogoBase64
            );
        } else {
            contestants[contestantsCount] = Contestant(
                contestantsCount,
                _name,
                0,
                _party,
                _age,
                _qualification,
                ""
            );
        }
    }

    function voterRegistration(address user) public onlyAdmin validState(PHASE.reg) {
        voters[user].isRegistered = true;
    }

    function vote(uint _contestantId) public validState(PHASE.voting) {
        require(voters[msg.sender].isRegistered, "Voter is not registered");
        require(!voters[msg.sender].hasVoted, "Voter has already voted");
        require(_contestantId <= contestantsCount, "Invalid contestant ID");
        
        contestants[_contestantId].voteCount++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].vote = _contestantId;
    }

    function resetPhase() public onlyAdmin validState(PHASE.done) {
        for (uint i = 1; i <= contestantsCount; i++) {
            delete contestants[i];
        }
        contestantsCount = 0;
        state = PHASE.reg;
    }
}
