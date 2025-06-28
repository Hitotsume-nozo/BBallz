// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DappEventXFactory.sol";
import "../src/Ticket1155.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        Ticket1155 ticket = new Ticket1155(
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // e.g., Sepolia VRF
            4519,
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
        );

        DappEventXFactory factory = new DappEventXFactory(address(ticket));
        ticket.grantRole(ticket.DEFAULT_ADMIN_ROLE(), address(factory));

        vm.stopBroadcast();
    }
}
