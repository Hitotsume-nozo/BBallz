// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Ticket1155.sol";
import "../src/EventInstance.sol";
import "../src/DappEventXFactory.sol";

contract DappEventXTest is Test {
    Ticket1155 ticket;
    DappEventXFactory factory;
    address organizer = address(0xBEEF);
    address user = address(0xCAFE);

    function setUp() public {
        // Use mock Chainlink args
        address mockVRF = address(0x1234);
        uint64 mockSubId = 1;
        bytes32 mockKeyHash = bytes32("0xabc");

        // Deploy contracts
        ticket = new Ticket1155(mockVRF, mockSubId, mockKeyHash);
        factory = new DappEventXFactory(address(ticket));

        // Critical: Factory needs admin role on ticket to grant minter role to events
        ticket.grantRole(ticket.DEFAULT_ADMIN_ROLE(), address(factory));
        // Also grant minter role to factory directly
        ticket.grantRole(ticket.MINTER_ROLE(), address(factory));
    }

    function testCreateEvent() public {
        address eventAddr = factory.createEvent(organizer, block.timestamp + 1 days);
        assert(eventAddr != address(0));
    }

    function testAddTierAndBuy() public {
        // Create event
        address eventAddr = factory.createEvent(organizer, block.timestamp + 1 days);
        EventInstance ei = EventInstance(eventAddr);

        // The organizer should have ORGANIZER_ROLE by default from constructor
        // Add tier as organizer
        vm.startPrank(organizer);
        ei.addTier("VIP", 0.1 ether, 50, "ipfs://vip-uri");
        vm.stopPrank();

        // Simulate user buying ticket
        vm.startPrank(user);
        vm.deal(user, 1 ether);
        ei.buy{value: 0.1 ether}("VIP", 1);
        vm.stopPrank();

        // Assertions
        assertEq(address(ei).balance, 0.1 ether);
        assertEq(ticket.balanceOf(user, ei.tierTokenId("VIP")), 1);
    }
}