// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DappEventXFactory.sol";
import "../src/Ticket1155.sol";

contract EventXTest is Test {
    Ticket1155 ticket;
    DappEventXFactory factory;

    function setUp() public {
        // Use mock Chainlink args
        address mockVRF = address(0x1234);
        uint64 mockSubId = 1;
        bytes32 mockKeyHash = bytes32("0xabc");

        // Deploy contracts
        ticket = new Ticket1155(mockVRF, mockSubId, mockKeyHash);
        factory = new DappEventXFactory(address(ticket));

        // Setup roles properly
        // Factory needs admin role on ticket to grant minter role to events
        ticket.grantRole(ticket.DEFAULT_ADMIN_ROLE(), address(factory));
        // Also grant minter role to factory directly
        ticket.grantRole(ticket.MINTER_ROLE(), address(factory));
    }

    function testFactoryCreatesEvent() public {
        address org = address(1);
        address eventAddr = factory.createEvent(org, block.timestamp + 1 days);
        assert(eventAddr != address(0));
    }
}