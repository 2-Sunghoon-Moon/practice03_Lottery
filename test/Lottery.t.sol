// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Lottery.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    uint256 received_msg_value;
    function setUp() public {
       lottery = new Lottery();
       received_msg_value = 0;
       vm.deal(address(this), 100 ether);
       vm.deal(address(1), 100 ether);
       vm.deal(address(2), 100 ether);
       vm.deal(address(3), 100 ether);
    }

    // 0.1 ether 보냈을때 구매할 수 있어야한다. 
    function testGoodBuy() public {
        lottery.buy{value: 0.1 ether}(0);
    }

    // 돈 안보냈을 때 구매할 수 있어야 한다.
    function testInsufficientFunds1() public {
        vm.expectRevert();
        lottery.buy(0);
    }

    // 0.1 ether 안보냈을 때 막아야함
    function testInsufficientFunds2() public {
        vm.expectRevert();
        lottery.buy{value: 0.1 ether - 1}(0);
    }

    // 0.1 ether 안보냈을 때 막아야함
    function testInsufficientFunds3() public {
        vm.expectRevert();
        lottery.buy{value: 0.1 ether + 1}(0);
    }

    // 두번 구매 못하게해야함
    function testNoDuplicate() public {
        lottery.buy{value: 0.1 ether}(0);
        vm.expectRevert();
        lottery.buy{value: 0.1 ether}(0);
    }

    function testSellPhaseFullLength() public {
        // console.log("[+] testSellPhaseFullLength()");

        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours - 1);
        vm.prank(address(1));

        // console.log("[+] testSellPhaseFullLength()");
        lottery.buy{value: 0.1 ether}(0);
    }

    function testNoBuyAfterPhaseEnd() public {
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours);
        vm.expectRevert();
        vm.prank(address(1));
        lottery.buy{value: 0.1 ether}(0);
    }

    function testNoDrawDuringSellPhase() public {
        console.log("[+] testNoDrawDuringSellPhase()");

        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours - 1);
        vm.expectRevert();
        lottery.draw();
    }

    function testNoClaimDuringSellPhase() public {
        console.log("[+] testNoClaimDuringSellPhase()");
        console.log("    ", block.timestamp);

        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours - 1);
        vm.expectRevert();
        lottery.claim();
    }

    function testDraw() public {
        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
    }

    function getNextWinningNumber() private returns (uint16) {
        console.log("[+] getNextWinningNumber()");
        uint256 snapshotId = vm.snapshot();

        lottery.buy{value: 0.1 ether}(0);
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        
        uint16 winningNumber = lottery.winningNumber();
        
        vm.revertTo(snapshotId);
        
        return winningNumber;
    }

    function testClaimOnWin() public {
        // console.log("[+] testClaimOnWin()");
        uint16 winningNumber = getNextWinningNumber();
        // console.log("    winningNumber:", winningNumber);

        lottery.buy{value: 0.1 ether}(winningNumber); 

        vm.warp(block.timestamp + 24 hours);
        
        uint256 expectedPayout = address(lottery).balance;
        // console.log("    expectedPayout:", expectedPayout);
        
        
        lottery.draw();
        // console.log("    lottery.draw()");
        lottery.claim();


        
        // console.log("    received_msg_value:", received_msg_value);
        
        assertEq(received_msg_value, expectedPayout);
    }

    function testNoClaimOnLose() public {
        // console.log("[+] testNoClaimOnLose()");
        // 우승번호 추출
        uint16 winningNumber = getNextWinningNumber();
        console.log("    winningNumber:", winningNumber);

        // 우승번호+1로 베팅하여 0.1 구매
        lottery.buy{value: 0.1 ether}(winningNumber + 1); 
        
        vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        lottery.claim();

        console.log("    received_msg_value:", winningNumber);

        assertEq(received_msg_value, 0);
    }

    function testNoDrawDuringClaimPhase() public {
        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber); vm.warp(block.timestamp + 24 hours);
        lottery.draw();
        lottery.claim();
        vm.expectRevert();
        lottery.draw();
    }

    function testRollover() public {
        console.log("[+] testRollover()");

        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber + 1); vm.warp(block.timestamp + 24 hours);

        console.log("    lottery.draw()");
        lottery.draw();

        console.log("    lottery.claim()");
        lottery.claim();

        winningNumber = getNextWinningNumber();
        console.log("    winningNumber: ", winningNumber);


        lottery.buy{value: 0.1 ether}(winningNumber); vm.warp(block.timestamp + 24 hours);

        console.log("    lottery.draw()");
        lottery.draw();

        console.log("    lottery.claim()");
        lottery.claim();

        console.log("    received_msg_value: ", received_msg_value);
        assertEq(received_msg_value, 0.2 ether);
    }

    function testSplit() public {
        console.log("[+] testSplit()");

        uint16 winningNumber = getNextWinningNumber();
        lottery.buy{value: 0.1 ether}(winningNumber);
        vm.prank(address(1));
        lottery.buy{value: 0.1 ether}(winningNumber);
        vm.deal(address(1), 0);
        vm.warp(block.timestamp + 24 hours);
        
        
        lottery.draw();
        console.log("[+] lottery.draw()");

        
        lottery.claim();
        console.log("[+] lottery.claim()");
        
        assertEq(received_msg_value, 0.1 ether);  // 0.1 받아야함

        console.log("[+] ==========================");

        vm.prank(address(1));
        
        lottery.claim();
        console.log("[+] lottery.claim()");
        
        assertEq(address(1).balance, 0.1 ether);   // 0.1 받아야함
    }

    receive() external payable {
        received_msg_value = msg.value;
    }
}