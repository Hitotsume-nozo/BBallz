// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

// Explicitly define the IERC1155Supply interface
interface IERC1155Supply {
    function totalSupply(uint256 id) external view returns (uint256);
    function exists(uint256 id) external view returns (bool);
}

contract Ticket1155 is ERC1155, AccessControl, ERC1155Supply, VRFConsumerBaseV2 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    
    constructor(
        address vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) ERC1155("") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, "");
    }

    function uri(uint256) public pure override returns (string memory) {
        return "https://example.com/api/ticket/{id}";
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // FINAL CORRECTED supportsInterface
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return 
            ERC1155.supportsInterface(interfaceId) || 
            AccessControl.supportsInterface(interfaceId) ||
            interfaceId == type(IERC1155Supply).interfaceId;
    }

    function fulfillRandomWords(uint256, uint256[] memory) internal override {}
}