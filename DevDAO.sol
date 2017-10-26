pragma solidity ^0.4.17;

contract DevDao {

        // structs

    struct BoardMemberSubstitutionVote {
        address currentBoardMember;
        address replacementBoardMember;
    }

    struct BoardMember {
        BoardMemberSubstitutionVote boardMemberSubstitutionVote;
        address votedCustodian;
        address escapeHatchAddress;
    }

        // state
    
    // array of board members / key holders
    mapping (address => BoardMember) private boardMembersMap;
    address[] private boardMembersAddresses;
    // sets the max cap that the custodian can direct per day
    uint private maxPercentWithdrawalPerDay = 1;
    // only used by onlyCustodian
    mapping (address => uint) private custodianVotes;
    // only used by determineBlahBlah
    mapping (address => mapping(address => uint)) private replacementBoardMemberVotes;

        // modifiers

    // ensure that callers are BoardMembers
    modifier onlyBoardMembers() {
        bool foundAddress = false;
        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            if (msg.sender == boardMembersAddresses[i]) {
                foundAddress = true;
                break;
            }
        }
        if (foundAddress) {
            _;
        } else {
            revert();
        }
    }

    // ensure that caller is Custodian. Computed by consensus (5 of 7) custodian implied by current BoardMembers state
    modifier onlyCustodian() {
        address computedCustodian = getCustodian();
        if (msg.sender == computedCustodian) {
            _;
        } else {
            revert();
        }
    }

        // functions

    // construct and initialize boardMemberConfigurationsMap and boardMembers
    function DevDao(address[] initialBoardMembers) public {
        if (initialBoardMembers.length == 7) {
            boardMembersAddresses = initialBoardMembers;
            for (uint i = 0; i < initialBoardMembers.length; i++) {
                BoardMember boardMember;
                boardMembersMap[initialBoardMembers[i]] = boardMember;
            }
        } else {
            revert();
        }
    }

    function clearCustodianVotes() private {
        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            delete custodianVotes[boardMembersAddresses[i]];
        }
    } 

    function clearReplacementBoardMemberVotes(address[] existingBoardMemberToReplaceArray, address[] replacementBoardMemberAddressArray) private {
        for (uint i = 0; i < existingBoardMemberToReplaceArray.length; i++) {
            for (uint e = 0; e < replacementBoardMemberAddressArray.length; e++) {
                var existingAddress = existingBoardMemberToReplaceArray[i];
                var replacementAddress = replacementBoardMemberAddressArray[e];
                delete replacementBoardMemberVotes[existingAddress][replacementAddress];
            }
        }
    } 

    // return current custodian
    function getCustodian() public returns (address) {
        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            // custodian address key does not exist in mapping
            var boardMember = boardMembersMap[boardMembersAddresses[i]];
            if (custodianVotes[boardMember.votedCustodian] == 0) {
                custodianVotes[boardMember.votedCustodian] = 1;
            } else { // custodian address key already exists in mapping
                // increment vote by 1
                custodianVotes[boardMember.votedCustodian] += 1;
                // if (at least) 5 board members are voting for this custodian and the caller matches the voted for address, continue
                if (custodianVotes[boardMember.votedCustodian] == 5) {
                    clearCustodianVotes();
                    return boardMember.votedCustodian;
                }
            }
        }
        clearCustodianVotes();
        revert();
    }

    function determineIfBoardMemberIsVotedOut(address boardMember) public returns (bool, address) {
        // iterate through boardMembers and determine if there is consensus to replace a boardMember
        address[] memory existingBoardMemberToReplaceArray;
        address[] memory replacementBoardMemberAddressArray;

        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            var curBoardMember = boardMembersMap[boardMembersAddresses[i]];

            var existingBoardMemberToReplace = curBoardMember.boardMemberSubstitutionVote.currentBoardMember;
            var replacementBoardMemberAddress = curBoardMember.boardMemberSubstitutionVote.replacementBoardMember;
            existingBoardMemberToReplaceArray[i] = existingBoardMemberToReplace;
            replacementBoardMemberAddressArray[i] = replacementBoardMemberAddress;

            if (replacementBoardMemberVotes[existingBoardMemberToReplace][replacementBoardMemberAddress] == 0) {
                replacementBoardMemberVotes[existingBoardMemberToReplace][replacementBoardMemberAddress] = 1;
            } else {
                replacementBoardMemberVotes[existingBoardMemberToReplace][replacementBoardMemberAddress] += 1;
                if (replacementBoardMemberVotes[existingBoardMemberToReplace][replacementBoardMemberAddress] == 5 && existingBoardMemberToReplace == boardMember) {
                    clearReplacementBoardMemberVotes(existingBoardMemberToReplaceArray, replacementBoardMemberAddressArray);
                    return (true, replacementBoardMemberAddress);
                }
            }
        }

        clearReplacementBoardMemberVotes(existingBoardMemberToReplaceArray, replacementBoardMemberAddressArray);
        return (false, address(0x0));
    }

    function replaceBoardMemberFromMap(address curBoardMember, address replacementBoardMemberAddress) private {
        // delete and replace existing key/value from map
        delete boardMembersMap[curBoardMember];
        BoardMember newBoardMember;
        boardMembersMap[replacementBoardMemberAddress] = newBoardMember;
    }

    function replaceBoardMemberFromArray(address curBoardMember, address replacementBoardMemberAddress) private {
        // delete and replace existing address from array
        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            if (boardMembersAddresses[i] == curBoardMember) {
                boardMembersAddresses[i] = replacementBoardMemberAddress;
                break;
            }
        }
    }

    // called by setReplacementBoardMember
    function replaceBoardMember(address boardMember) private {
        var (shouldReplaceBoardMember, replacementBoardMemberAddress) = determineIfBoardMemberIsVotedOut(boardMember);
        if (shouldReplaceBoardMember) {
            replaceBoardMemberFromMap(boardMember, replacementBoardMemberAddress);
            replaceBoardMemberFromArray(boardMember, replacementBoardMemberAddress);
        }
    }

    // modify boardMemberConfigurationsMap state with desired custodian.
    function setCustodianVote(address newCustodian) public onlyBoardMembers {
        boardMembersMap[msg.sender].votedCustodian = newCustodian;
    }

    // sets caller state to reflect vote for new board member
    function setReplacementBoardMember(address currentBoardMember, address replacementBoardMember) public onlyBoardMembers {
        // set the board-member (modifier enforced) caller's vote for a replacement board member
        BoardMemberSubstitutionVote boardMemberSubstitutionVote;
        boardMemberSubstitutionVote.currentBoardMember = currentBoardMember;
        boardMemberSubstitutionVote.replacementBoardMember = replacementBoardMember;
        boardMembersMap[msg.sender].boardMemberSubstitutionVote = boardMemberSubstitutionVote;
        replaceBoardMember(currentBoardMember);
    }

    // set an escape hatch address for a board member
    function setEscapeHatchAddress(address escapeHatchAddress) public onlyBoardMembers {
        // set the board-member (modifier enforced) caller's escape hatch address
        boardMembersMap[msg.sender].escapeHatchAddress = escapeHatchAddress;
    }

    function sendFunds(address toAddress, uint weiAmount) public onlyCustodian {
        // send locked with maxPercentWithdrawalPerDay of total funds 
    }
    
    // called by setEscapeHatchAddress
    function executeEscapeHatch() public {
        // Check if all board members are voting for a specific address.
        // If so, Send all funds to address
    }

    // allow funds to be sent to contract
    function() public payable {}

}


// notes
// Use modifiers for custodian and multisig holders to ensure only they can call functions
// Set index in the modifier for decorated function to use



// 1. When swapping out a multi-sig keyholder, clean up the state of their existing vote
// 2. Use msg.sender instead of tx.from because tx.from inspects the transaction.