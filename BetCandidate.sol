//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

struct Bet{
    uint amount;
    uint candidate;
    uint timestamp;
    uint claimed;
}

struct Dispute {
    string candidate1;
    string candidate2;
    string image1;
    string image2;
    uint total1;
    uint total2;
    uint totalBets1;
    uint totalBets2;
    uint winner;
}

contract BetCandidate{
    Dispute public dispute;
    mapping(address => Bet) public allBets;
    address immutable  owner;
    uint constant fee = 1000; // 10% na escala de 4 zeros
    uint public netPrize;
    uint public comission;

    constructor(){
        owner = msg.sender;
        dispute = Dispute({
            candidate1: "D. Trump",
            candidate2: "K. Harris",
            image1: "http://bit.ly/3zmSfiA",
            image2: "http://bit.ly/4gF4mYO",
            total1: 0,
            total2: 0,
            totalBets1: 0,
            totalBets2: 0,
            winner: 0
        });
    }

    function bet(uint candidate) external payable{
        require(candidate ==  1 || candidate == 2, "Invalid Candidate");
        require(msg.value > 0, "Invalid Value");
        require(dispute.winner == 0, "Dispute Closed");
        require(block.timestamp < 1727830800 , "Dispute Closed"); //Data limite para apostar
        require(allBets[msg.sender].amount == 0, "User already placed a bet"); // Só aceita se o apostador não fez nenhuma aposta

        Bet memory newBet;
        newBet.amount = msg.value;
        newBet.candidate = candidate;
        newBet.timestamp = block.timestamp;

        allBets[msg.sender] = newBet;
      
        candidate == 1 ? dispute.total1 += msg.value : dispute.total2 += msg.value;
        candidate == 1 ? dispute.totalBets1 += 1 : dispute.totalBets2 += 1;
    }

   
  
    function finish(uint winner) external {
        require(block.timestamp > 1727820000 , "Dispute Closed"); //Data mínima para encerrar
        require(msg.sender == owner, "Invalid Account Owner");
        require(winner == 1 || winner == 2, "Invalid Candidate");
        require(dispute.winner == 0, "Dispute Closed");

        dispute.winner = winner;
        uint grossPrize = dispute.total1 + dispute.total2;
        comission = (grossPrize * fee) / 1e4;
        netPrize = grossPrize - comission;
    }

    function claimComission() external {// Saque da comissão
        require(msg.sender == owner, "Invalid Account Owner");
        require(dispute.winner != 0, "Dispute Opened");

        payable(owner).transfer(comission);
    }

    function claim() external {
        Bet memory userBet = allBets[msg.sender];
        require(dispute.winner > 0 && dispute.winner == userBet.candidate && userBet.claimed == 0, "Invalid Claim");
        uint winnerAmount = dispute.winner == 1 ? dispute.total1 : dispute.total2;
        uint ratio = (userBet.amount * 1e4) / winnerAmount;
        uint individualPrize = (netPrize * ratio) / 1e4;
        allBets[msg.sender].claimed = individualPrize;
        payable(msg.sender).transfer(individualPrize);
    }

}
