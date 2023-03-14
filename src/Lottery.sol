pragma solidity ^0.8.13;

import "forge-std/console.sol";


pragma solidity ^0.8.0;

contract Lottery {
    uint256 public constant GAME_INTERVAL = 24 hours;

    uint8 game_state;                                      // 0: 대기 1: 참가진행 2: 결과추출 3: 금액뽑기
    uint256 public start_time;                             // 게임 시작시간을 의미한다.

    address[] public participants;
    mapping(address => bool) public participation_state;   // 게임참가 여부를 저장하는 배열
    mapping(address => uint16) public player_bet_numbers;  // 플레이어가 베잍한 숫자를 기재하기 위함

    uint256 reward;

    uint16 public winningNumber;                           // 당첨 번호        
    address[] public winners;
    uint256 public winner_number = 0;
    uint256 public reward_number = 0;


    mapping(address => bool) reward_state;

    function buy(uint16 betNumber) public payable {
        require(game_state == 0 || game_state == 1);
        require(participation_state[msg.sender] == false);
        require(msg.value == 0.1 ether);

        if(game_state == 1) {
            require(block.timestamp < start_time + GAME_INTERVAL);
        }

        if(game_state == 0) {
            game_state = 1;
            start_time = block.timestamp;
        }

        participants.push(msg.sender);
        participation_state[msg.sender] = true;
        player_bet_numbers[msg.sender] = betNumber;

        reward += msg.value;
    }


    function draw() public {
        console.log("[+] draw()");
        console.log("    block.timestamp: ", block.timestamp);
        console.log("    start_time: ", start_time);
        require(game_state == 1);
        require(start_time + GAME_INTERVAL <= block.timestamp);

        bytes memory randomInput = abi.encode(block.number, msg.sender);
        bytes32 hash = keccak256(randomInput);
        winningNumber = uint16(uint256(hash) % (uint256(1) << 16));


        game_state = 2;

        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i];
            uint16 bet_number = player_bet_numbers[participant];

            if(winningNumber == bet_number) {
                winners.push(participant);

                winner_number += 1;
                reward_number += 1;
            }
        }
    }


    function claim() public {
        require(game_state == 2);
        require(reward_state[msg.sender] == false);

        if(winner_number > 0) {
            require((reward / winner_number) <= address(this).balance);


            payable(msg.sender).call{value: reward / winner_number}(""); 

            reward_state[msg.sender];
            reward_number = reward_number - 1;
        }


        if(reward_number == 0) {
            game_state = 0;                                      // 0: 대기 1: 참가진행 2: 결과추출 3: 금액뽑기

            participants;

            for(uint i=0; i<participants.length; i++) {
                delete participation_state[participants[i]];
                delete player_bet_numbers[participants[i]];
            }

            delete participants;


            winningNumber = 0;                           // 당첨 번호        
            
            winner_number = 0;
            reward_number = 0;


            for(uint i=0; i<winners.length; i++) {
                delete reward_state[winners[i]];
            }

            delete winners;
        }

    }
}