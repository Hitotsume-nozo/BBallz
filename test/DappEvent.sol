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

    function setUp() public {
        // Use mock Chainlink args
        address mockVRF = address(0x1234);
        uint64 mockSubId = 1;
        bytes32 mockKeyHash = bytes32("0xabc");

        ticket = new Ticket1155(mockVRF, mockSubId, mockKeyHash);
        factory = new DappEventXFactory(address(ticket));

        // Grant role to factory
        ticket.grantRole(ticket.DEFAULT_ADMIN_ROLE(), address(factory));
        factory.grantRole(factory.FACTORY_ADMIN(), address(this));
    }

    function testCreateEvent() public {
        address eventAddr = factory.createEvent(organizer, block.timestamp + 1 days);
        assert(eventAddr != address(0));
    }

    function testAddTierAndBuy() public {
        address eventAddr = factory.createEvent(organizer, block.timestamp + 1 days);
        EventInstance ei = EventInstance(eventAddr);

        // Grant organizer role to test contract for simplicity
        ei.grantRole(ei.ORGANIZER_ROLE(), address(this));

        ei.addTier("VIP", 0.1 ether, 50, "ipfs://vip-uri");

        vm.deal(address(this), 1 ether);
        ei.buy{value: 0.1 ether}("VIP", 1);

        assertEq(address(ei).balance, 0.1 ether);
    }
}
