// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/// @title Voting with delegation.
contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
      
   // index of the voted proposa

  
    

   
    }
    address public  chairperson;
  

    modifier onlyOwner(){
        require(msg.sender == chairperson, "Only Chairperson");
        _;
    }

    uint public yesVotes;
    uint public noVotes;
    bool public votingEnded;

    // This is a type for a single proposal.
    // struct Proposal {
    //     bytes32 name;   // short name (up to 32 bytes)
    //     uint voteCount; // number of accumulated votes
    // }

    

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    event Voted(address indexed  Voter, bool vot);
    event VotingEnded(uint yesVotes, uint noVotes);
    // A dynamically-sized array of `Proposal` structs.
    // Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor() {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
         

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        // for (uint i = 0; i < proposalNames.length; i++) {
        //     // `Proposal({...})` creates a temporary
        //     // Proposal object and `proposals.push(...)`
        //     // appends it to the end of `proposals`.
        //     proposals.push(Proposal({
        //         name: proposalNames[i],
        //         voteCount: 0
        //     }));
        // }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) external onlyOwner {
    
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(bool vot) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        if (vot){
            yesVotes++;
        }
        else {
            noVotes++;
        }
       
        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        // proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function Result() public onlyOwner            
    {
        votingEnded = true;
        emit VotingEnded(yesVotes, noVotes);
    }

   
}