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
    uint constant minimumDate = 1727820000; // 1 de outubro de 2024 às 18:00:00 GMT-04:00 
    uint constant maximumDate = 1727830800; //1 de outubro de 2024 às 21:00:00 GMT-04:00
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
        require(block.timestamp < maximumDate, "Bets closed"); //Data limite para apostar
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
        require(block.timestamp > minimumDate, "Bets are still open."); //Data mínima para encerrar
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

    function setImage (uint _candidate, string memory _name, string memory _image) external{//função para alterar nome e imagem
        require(msg.sender == owner, "Invalid Account Owner");
        require(_candidate ==  1 || _candidate == 2, "Invalid Candidate");
        require(bytes(_image).length > 0, "Invalid Image"); //verifica pelos bytes se a string é de uma imagem vazia


        if (_candidate == 1){
            dispute.candidate1 = _name;
            dispute.image1 = _image;
        }
        else{
            dispute.candidate2 = _name;
            dispute.image2 = _image;
        }
    }

}
