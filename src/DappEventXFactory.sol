// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Ticket1155.sol";
import "./EventInstance.sol";

contract DappEventXFactory is AccessControl {
    bytes32 public constant FACTORY_ADMIN = keccak256("FACTORY_ADMIN");
    
    Ticket1155 public ticketContract;
    address[] public events;

    event EventCreated(address indexed eventInstance, address organizer);

    constructor(address _ticket1155) {
        // Setup role hierarchy
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(FACTORY_ADMIN, DEFAULT_ADMIN_ROLE);
        
        // Grant roles to deployer
        _setupRole(FACTORY_ADMIN, msg.sender);
        
        ticketContract = Ticket1155(_ticket1155);
    }

    function createEvent(address organizer, uint256 date) 
        external 
        onlyRole(FACTORY_ADMIN) 
        returns (address) 
    {
        EventInstance newEvent = new EventInstance(
            organizer,                // _organizer
            address(ticketContract),  // _ticketNFTAddress
            date                      // _eventDate
        );
        
        events.push(address(newEvent));
        ticketContract.grantRole(ticketContract.MINTER_ROLE(), address(newEvent));
        emit EventCreated(address(newEvent), organizer);
        return address(newEvent);
    }
        

    function getAllEvents() external view returns (address[] memory) {
        return events;
    }
    
    function grantFactoryAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(FACTORY_ADMIN, admin);
    }
    
    function revokeFactoryAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(FACTORY_ADMIN, admin);
    }
}