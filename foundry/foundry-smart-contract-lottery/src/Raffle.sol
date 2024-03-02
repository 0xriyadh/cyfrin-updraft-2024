// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

// NatSpec Format: Solidity contracts can use a special form of comments to provide rich documentation for functions, return variables and more. This special form is named the Ethereum Natural Language Specification Format (NatSpec). [https://docs.soliditylang.org/en/latest/natspec-format.html]
/**
 * @title A Simple Raffle Contract
 * @author Md. Mahadi Hassan Riyadh
 * @notice This contract is for creating a simple raffle system.
 * @dev Implements chainlink VRF for random number generation.
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTimePassed();

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_OF_WORDS = 1;

    uint256 private immutable i_entranceFee;
    // minimum time interval between two raffles in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash; // gas lane
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // as one of the players will be paid, so the addresses need to payable
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /*  
        ###############################
        ########## Events ⏳ ##########
        ###############################
    */
    event EnteredRaffle(address indexed player);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // more gas efficient than require
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    /*  
        1. get a random number
        2. use the random number to pick a winner
        3. be automatically called
    */
    function pickWinner() external {
        // check if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert Raffle__NotEnoughTimePassed();
        }

        /*  
            - Till now all we have been doing was atomic. Everything was happening in one transaction.
            - Now we need to do two transactions when using Chainlink VRF:
                1. Request a random number -> This is a outgoing request transaction to Chainlink VRF
                2. Get the random number (Callback Request) <- This is a incoming recieving transaction coming from Chainlink VRF
        */
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_OF_WORDS
        );
    }

    function fulFillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // Implementation goes here
        // require(s_requests[_requestId].exists, "request not found");
        // s_requests[_requestId].fulfilled = true;
        // s_requests[_requestId].randomWords = _randomWords;
        // emit RequestFulfilled(_requestId, _randomWords);
    }

    /*  
        ###################################
        ####### Getter Functions ✅ #######
        ###################################
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}

/*  
    ####################################################
    ####### Code Layout & Order (Style Guide) 🎨 #######
    ####################################################

    ⭕️ Contract elements should be laid out in the following order:
        - Pragma statements
        - Import statements
        - Events
        - Errors
        - Interfaces
        - Libraries
        - Contracts

    ⭕️ Inside each contract, library or interface, use the following order:
        - Type declarations
        - State variables
        - Events
        - Errors
        - Modifiers
        - Functions

    ⭕️ Layout of Functions:
        - constructor
        - receive function (if exists)
        - fallback function (if exists)
        - external
        - public
        - internal
        - private
        - view & pure functions 
*/
