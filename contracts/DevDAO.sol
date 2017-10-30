/*
1. Complete implementation of prototype. 
	1a. killswitches 
  		1. Token holder can force refund with existing funds with super-majority (90%)
      2. Board members can force refund with iff all agree 
  1b. (paused) non-transferable tokens with voting power that doesn't actually result in funds being sent yet
2. White paper with the full final spec and info
3. ReimplemenTation with unit tests first, contract, and web based app
3a. Web app includes support for hardware device signing (OMG VUE2) (probably will want to fork MEW for that)

We want pausable tokens, intially non-transferable --> Use open zepplin contract
*/

pragma solidity ^0.4.15; // 17


contract DevDao {

  //  enum State { 

   // }
        // structs
    address currentCustodian;
    mapping(address => int) private custodianVotes;

    struct BoardMemberSubstitutionVote {
        address currentBoardMember;
        address replacementBoardMember;
    }

    struct BoardMember {
        BoardMemberSubstitutionVote boardMemberSubstitutionVote;
        address votedCustodian; // 
        address migrationAddress;
    }

        // state
    
    // array of board members / key holders
    mapping (address => BoardMember) private boardMembersMap;
    address[] private boardMembersAddresses;
    // sets the max cap that the custodian can direct per day
        // uint private maxPercentWithdrawalPerDay = 1;


    // only used by determineBlahBlah
    mapping (address => mapping(address => uint)) private replacementBoardMemberVotes;


        // getters

    function getBoardMembersAddresses() public returns (address[]) {
        return boardMembersAddresses;
    }

    function getCurrentCustodian() public returns (address) {
        return currentCustodian;
    }


        // modifiers


    // ensure that callers are BoardMembers
    modifier onlyBoardMembers() {
        bool callerIsBoardMember = isCallerBoardMember();
        if (callerIsBoardMember) {
            _;
        } else {
            revert();
        }
    }

    // ensure that caller is Custodian. Computed by consensus (5 of 7) custodian implied by current BoardMembers state
    modifier onlyCustodian() {
        if (msg.sender == currentCustodian) {
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
            for (uint i = 0; i < initialBoardMembers.length; i++) { //Check if this is needed
                BoardMember memory boardMember;
                boardMembersMap[initialBoardMembers[i]] = boardMember;
            }
        } else {
            revert();
        }
    }


    function isCallerBoardMember() public returns (bool) {
        bool addressFound = false;
        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            if (msg.sender == boardMembersAddresses[i]) {
                addressFound = true;
                break;
            }
        }
        return addressFound;
    }

    // return current custodian
    // Note: Could be contract or externally owned account
    function getCustodian() public returns (address) {
        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            // custodian address key does not exist in mapping
            BoardMember storage b = boardMembersMap[boardMembersAddresses[i]];
            if (custodianVotes[b.votedCustodian] == 0) {
                custodianVotes[b.votedCustodian] = 1;
            // custodian address key already exists in mapping
            } else {
                // increment vote by 1
                custodianVotes[b.votedCustodian] += 1;
                // if (at least) 5 board members are voting for this custodian and the caller matches the voted for address, continue
                if (custodianVotes[b.votedCustodian] == 5) {
                    clearCustodianVotes();
                    return b.votedCustodian;
                }
            }
        }
        clearCustodianVotes();
        return address(0);
    }

    function determineIfBoardMemberIsVotedOut(address boardMember) public returns (bool, address) {
        // iterate through boardMembers and determine if there is consensus to replace a boardMember
        address[] memory existingBoardMemberToReplaceArray;
        address[] memory replacementBoardMemberAddressArray;

        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            BoardMemberSubstitutionVote storage curSubVote = boardMembersMap[boardMembersAddresses[i]].boardMemberSubstitutionVote;

            address existingBoardMemberToReplace = curSubVote.currentBoardMember;
            address replacementBoardMemberAddress = curSubVote.replacementBoardMember;

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


    // modify boardMemberConfigurationsMap state with desired custodian.
    function setCustodianVote(address newCustodian) public onlyBoardMembers {
        boardMembersMap[msg.sender].votedCustodian = newCustodian;
        currentCustodian = getCustodian();
    }

    // sets caller state to reflect vote for new board member
    function setReplacementBoardMember(address currentBoardMember, address replacementBoardMember) public onlyBoardMembers {
        // set the board-member (modifier enforced) caller's vote for a replacement board member
        BoardMemberSubstitutionVote memory boardMemberSubstitutionVote;
        boardMemberSubstitutionVote.currentBoardMember = currentBoardMember;
        boardMemberSubstitutionVote.replacementBoardMember = replacementBoardMember;
        boardMembersMap[msg.sender].boardMemberSubstitutionVote = boardMemberSubstitutionVote;
        replaceBoardMember(currentBoardMember);
    }

    // set an escape hatch address for a board member
    function setMigrationAddress(address migrationAddress) public onlyBoardMembers {
        // set the board-member (modifier enforced) caller's escape hatch address
        boardMembersMap[msg.sender].migrationAddress = migrationAddress;
    }

    function sendFunds(address toAddress, uint weiAmount) public onlyCustodian {
        // send locked with maxPercentWithdrawalPerDay of total funds 
        if (toAddress.call.value(weiAmount)()) {
            revert();
        }
    }


    // called by setMigrationAddress
    function executeMigration() public {
        // Check if all board members are voting for a specific address.
        // If so, Send all funds to address
    }


    function clearCustodianVotes() private {
        for (uint i = 0; i < boardMembersAddresses.length; i++) {
            delete custodianVotes[boardMembersAddresses[i]];
        }
    } 

    function clearReplacementBoardMemberVotes(address[] existingBoardMemberToReplaceArray, address[] replacementBoardMemberAddressArray) private {
        for (uint i = 0; i < existingBoardMemberToReplaceArray.length; i++) {
            for (uint e = 0; e < replacementBoardMemberAddressArray.length; e++) {
                address existingAddress = existingBoardMemberToReplaceArray[i];
                address replacementAddress = replacementBoardMemberAddressArray[e];
                delete replacementBoardMemberVotes[existingAddress][replacementAddress];
            }
        }
    } 


    function replaceBoardMemberFromMap(address curBoardMember, address replacementBoardMemberAddress) private {
        // delete and replace existing key/value from map
        delete boardMembersMap[curBoardMember];
        BoardMember memory newBoardMember;
        boardMembersMap[replacementBoardMemberAddress] = newBoardMember; //Check if this is needed
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


    // allow funds to be sent to contract
    function() public payable {}

}


// notes
// Use modifiers for custodian and multisig holders to ensure only they can call functions
// Set index in the modifier for decorated function to use



// 1. When swapping out a multi-sig keyholder, clean up the state of their existing vote
// 2. Use msg.sender instead of tx.from because tx.from inspects the transaction.
