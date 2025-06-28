// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./Ticket1155.sol";

contract EventInstance is AccessControl, ReentrancyGuard, ERC1155Holder {
    bytes32 public constant ORGANIZER_ROLE = keccak256("ORGANIZER_ROLE");
    
    address public organizer;
    Ticket1155 public ticketNFT;
    uint256 public eventDate;
    
    struct Tier {
        string name;
        uint256 price;
        uint256 maxSupply;
        uint256 minted;
        string uri;
    }
    
    mapping(string => Tier) public tiers;
    mapping(string => uint256) public tierTokenIds;
    uint256 private nextTokenId = 1;
    
    event TierAdded(string indexed tierName, uint256 price, uint256 maxSupply);
    event TicketPurchased(address indexed buyer, string tier, uint256 amount);

    constructor(
        address _organizer,
        address _ticketNFTAddress,
        uint256 _eventDate
    ) {
        organizer = _organizer;
        ticketNFT = Ticket1155(_ticketNFTAddress);
        eventDate = _eventDate;
        
        _setupRole(DEFAULT_ADMIN_ROLE, _organizer);
        _setupRole(ORGANIZER_ROLE, _organizer);
    }

    function addTier(
        string memory name,
        uint256 price,
        uint256 maxSupply,
        string memory tierURI
    ) external onlyRole(ORGANIZER_ROLE) {
        require(tierTokenIds[name] == 0, "Tier already exists");
        
        uint256 tokenId = nextTokenId++;
        tierTokenIds[name] = tokenId;
        tiers[name] = Tier({
            name: name,
            price: price,
            maxSupply: maxSupply,
            minted: 0,
            uri: tierURI
        });
        
        emit TierAdded(name, price, maxSupply);
    }

    function buy(
        string memory tier,
        uint256 amount
    ) external payable nonReentrant {
        Tier storage tierInfo = tiers[tier];
        require(tierInfo.price > 0, "Tier does not exist");
        require(msg.value >= tierInfo.price * amount, "Insufficient payment");
        require(tierInfo.minted + amount <= tierInfo.maxSupply, "Exceeds max supply");
        
        uint256 tokenId = tierTokenIds[tier];
        tierInfo.minted += amount;
        
        // Fixed mint call - add empty data parameter
        ticketNFT.mint(msg.sender, tokenId, amount);
        emit TicketPurchased(msg.sender, tier, amount);
    }

    function tierTokenId(string memory tier) public view returns (uint256) {
        return tierTokenIds[tier];
    }

    // Fixed supportsInterface override
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return 
            ERC1155Receiver.supportsInterface(interfaceId) || 
            AccessControl.supportsInterface(interfaceId);
    }
}