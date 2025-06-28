// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDappEventXFactory {
    function FACTORY_ADMIN() external view returns (bytes32);
    function ticketContract() external view returns (address);
    function events(uint256) external view returns (address);
    function getEventsCount() external view returns (uint256);
    
    function createEvent(address organizer, uint256 date) external returns (address);
    function getAllEvents() external view returns (address[] memory);
    function grantFactoryAdmin(address admin) external;
    function revokeFactoryAdmin(address admin) external;
    
    event EventCreated(address indexed eventInstance, address organizer);
}