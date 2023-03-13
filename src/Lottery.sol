// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";


pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public players; // 참여자 주소를 담을 배열

    mapping(address => bool) public bets; // 참가여부를 저장하는 배열


    address public manager; // 관리자 주소
    uint16 public winningNumber; // 당첨 번호
    bool public phase; // 게임 진행여부
    bool public isDrawn; // 당첨 번호를 뽑았는지 여부
    

    uint256 public nextDrawTime;
    uint256 public constant DRAW_INTERVAL = 24 hours;


    mapping(address => uint16) public betNumbers;


    uint256 public startTime;


    bool public claimState = false; 

    bool public gameState = true;


    //
    mapping(address => bool) public bettingState;


    uint16[] public answer;


    uint256 sendCount = 0;


    uint256 money = 0;


    constructor() {
        manager = msg.sender; // 컨트랙트 생성자가 호출한 계정을 관리자로 지정
        startTime = block.timestamp;

        console.log("startTime: ", block.timestamp);
    }
    
    function buy(uint16 betNumber) public payable {
        require(msg.value == 0.1 ether, "only 0.1 ether");
        require(block.timestamp < startTime + DRAW_INTERVAL); // 구매하는 시간이 시작 시간보다 24시간 이내여야한다.
        require(bettingState[msg.sender] == false, "only 1 bet");

        bettingState[address(msg.sender)] = true;
        betNumbers[address(msg.sender)] = betNumber;

        money += msg.value;


        answer.push(betNumber);
    }
    
    function claim() public {
        console.log("[+] claim()");
        console.log(block.timestamp);
        console.log(startTime);
        // console.log("    msg.sender: ", msg.sender);
        require(block.timestamp >= startTime + DRAW_INTERVAL, "Time Error");
        
        
        uint256 answerCount = 0;

        for(uint i=0; i<answer.length; i++) {
            if(winningNumber == answer[i]) {
                answerCount = answerCount + 1;
            }
        }


        

        if (betNumbers[address(msg.sender)] == winningNumber) {
            payable(msg.sender).call{value: splitMoney()}(""); //  address(this).balance

            sendCount = sendCount + 1;
        }

        // 초기화
        if(sendCount == answerCount) {
            startTime = block.timestamp;
            sendCount = 0;
        }
        
        bettingState[msg.sender] = false;
        claimState = false;
    }
    

    function splitMoney() public returns (uint256) {
        uint256 answerCount = 0;

        for(uint i=0; i<answer.length; i++) {
            if(winningNumber == answer[i]) {
                answerCount = answerCount + 1;
            }
        }


        return (money / answerCount);

    }


    function draw() public {
        // [1] 정답 추출시 
        require(startTime + DRAW_INTERVAL <= block.timestamp);
        require(claimState == false);
    }
}