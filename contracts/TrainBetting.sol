// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2021 IEXEC BLOCKCHAIN TECH                                       *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity ^0.6.12;

import "./Oracle.sol";

contract TrainBetting {
    string public status;
    uint256 public updatedate;
    string public OK = "OK";
    string public SCHEDULED = "Scheduled";

    //Departure DateTime Unix format
    uint256 departure = 1652164800;

    uint256 public minimumBet;
    uint256 public totalBetsOnAsPlanned;
    uint256 public totalBetsOnCanceled;
    address[] public players;

    struct Player {
        uint256 amountBet;
        uint16 betSelection;
    }

    // The address of the player and => the user info
    mapping(address => Player) public playerInfo;

    constructor() public {
        minimumBet = 100000000000000;
    }

    function checkPlayerExists(address player) public view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) return true;
        }
        return false;
    }

    function bet(uint8 _betSelection) public payable {
        //The first require is used to check if the player already exist
        require(!checkPlayerExists(msg.sender), "player exist");
        //The second one is used to see if the value sended by the player is
        //Higher than the minimum value
        require(
            msg.value >= minimumBet,
            "Value must be more than the minimum bet"
        );

        //We set the player informations : amount of the bet and selected team
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].betSelection = _betSelection;

        //Then we add the address of the player to the players array
        players.push(msg.sender);

        //At the end, we increment the stakes of the selected bet either bet on onscheduled or on canceled with the player bet
        if (_betSelection == 1) {
            totalBetsOnAsPlanned += msg.value;
        } else {
            totalBetsOnCanceled += msg.value;
        }
    }

    function distributePrizes() public {
        //Getting flight status from the oracle
        getOracleData();
        //Require to check whether the Flight is still scheduled or not
        require(
            !(keccak256(bytes(status)) == keccak256(bytes(SCHEDULED))),
            "Train journey Still Scheduled"    
        );

        uint16 winnerpartselected;
        //We test if the current status is a win for the first selection or the second selection
        // if the status is equal to an empty string it means that the train journey didn't have any delay or issue, this means the train journey went as planned(first selection wins)
        //else the train journey was canceled or diverted(second slection wins).
        if (
            (keccak256(bytes(status)) == keccak256(bytes(OK)))
        ) {
            winnerpartselected = 1;
        } else {
            winnerpartselected = 2;
        }

        address[1000] memory winners;
        uint256 count = 0; // This is the count for the array of winners
        uint256 LoserBet = 0; //This will take the value of all losers bet
        uint256 WinnerBet = 0; //This will take the value of all winners bet
        address playerAddress = address(0);

        //We loop through the player array to check who selected the winner team
        for (uint256 i = 0; i < players.length; i++) {
            playerAddress = players[i];

            //If the player selected the winner bet
            //We add his address to the winners array
            if (playerInfo[playerAddress].betSelection == winnerpartselected) {
                winners[count] = playerAddress;
                count++;
            }
        }

        //We define which bet sum is the Loser one and which one is the winner
        if (winnerpartselected == 1) {
            LoserBet = totalBetsOnCanceled;
            WinnerBet = totalBetsOnAsPlanned;
        } else {
            LoserBet = totalBetsOnAsPlanned;
            WinnerBet = totalBetsOnCanceled;
        }

        //We loop through the array of winners, to give RLC to the winners
        for (uint256 j = 0; j < count; j++) {
            if (winners[j] != address(0)) {
                address add = winners[j];
                uint256 Bet = playerInfo[add].amountBet;
                //Transfer the money to the user
                address payable addruser = payable(address(winners[j]));
                addruser.transfer(
                    (Bet * (10000 + ((LoserBet * 10000) / WinnerBet))) / 10000
                );
            }
        }
        // Delete all the players
        for (uint256 i = 0; i < players.length; i++) {
            delete playerInfo[players[i]];
        }
        // Delete all the players array
        players = new address[](0);
        //reinitialize the bets
        LoserBet = 0;
        WinnerBet = 0;
        totalBetsOnAsPlanned = 0;
        totalBetsOnCanceled = 0;
    }

    function getOracleData() public returns (string memory) {
        
        bytes32 oracleId = 0x56fd879bf2f20477ad163cf0b4bb3eb58bfff6af17b04ba5b277af13362547b4;
        address oracleAddress = 0x8ecEDdd1377E52d23A46E2bd3dF0aFE35B526D5F;
        Oracle oracleContract = Oracle(oracleAddress);
        (string memory value, uint256 date) = oracleContract.getString(
            oracleId
        );
        bytes memory converted = bytes(value);
        //Get current DateTime
        uint today = block.timestamp;
        //If we're still before departure date, we set the status to scheduled
        //Else this means that the train leaved as planned
        //!!! this is needed because the sncf api will return an empty string wether the journey
        //is still scheduled or if ti happened as planned!!!!
        if(converted.length == 0){
            if(today <= departure){
                status = SCHEDULED;
            }else{
                status= OK;
            }
        }else{
            status = value;
        }
        updatedate = date;
        return value;
    }

    function getStatus() public view returns (string memory) {
        return status;
    }

    function getAmountBetsOnAsPlanned() public view returns (uint256) {
        return totalBetsOnAsPlanned;
    }

    function getAmountBetsOnCanceled() public view returns (uint256) {
        return totalBetsOnCanceled;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return players.length;
    }
}
