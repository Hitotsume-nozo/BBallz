// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // Import for uint256 to string conversion

contract Ticket1155 is ERC1155, ERC1155Supply, AccessControl, VRFConsumerBaseV2 {
    using Strings for uint256; // Enable .toString() and .toHexString() on uint256

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;

    uint256 public nextTokenId;
    mapping(uint256 => uint256) public eventIdForToken;
    mapping(uint256 => string) public uriForToken;
    mapping(uint256 => address) public requestToMinter;
    mapping(uint256 => string) public requestToURI;
    mapping(uint256 => uint256) public requestToEventId;
    mapping(uint256 => uint256) public tokenRandomness; // Stores the raw random word for a tokenId

    event RandomNFTMinted(uint256 requestId, uint256 tokenId, address to);

    constructor(
        address vrfCoordinator,
        uint64 _subId,
        bytes32 _keyHash
    ) ERC1155("") VRFConsumerBaseV2(vrfCoordinator) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subId;
        keyHash = _keyHash;
    }

    /**
     * @dev Resolves the multiple inheritance conflict for _beforeTokenTransfer.
     * Ensures logic from ERC1155 and ERC1155Supply is executed correctly.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Requests randomness from Chainlink VRF to mint a new NFT.
     * Only callable by addresses with MINTER_ROLE.
     * @param to The address to mint the NFT to.
     * @param eventId The event ID associated with this NFT.
     * @param uri_ The base URI for the NFT metadata.
     * @return requestId The ID of the Chainlink VRF request.
     */
    function mintWithRandomness(
        address to,
        uint256 eventId,
        string memory uri_
    ) external onlyRole(MINTER_ROLE) returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // Requesting 1 random word for this mint
        );
        requestToMinter[requestId] = to;
        requestToURI[requestId] = uri_;
        requestToEventId[requestId] = eventId;
    }

    /**
     * @dev Callback function from Chainlink VRF after randomness is generated.
     * This function mints the NFT and assigns its random properties.
     * @param requestId The ID of the VRF request.
     * @param randomWords An array of random uint256 numbers.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Ensure at least one random word was received
        require(randomWords.length > 0, "No random words received");

        uint256 tokenId = nextTokenId++; // Assign a sequential tokenId for the type
        address to = requestToMinter[requestId];

        // Store the raw random word for this tokenId (useful for transparency/auditing)
        tokenRandomness[tokenId] = randomWords[0];

        // Use the random word to influence the NFT's URI (metadata)
        // This makes the specific NFT type or its properties random
        string memory baseURI = requestToURI[requestId];
        // Append a part of the random number (as hex string) to the base URI
        // Example: "https://my-event-nfts.com/ticket-data/" + "0x123abc..." + ".json"
        string memory randomSuffix = randomWords[0].toHexString(32); // Convert to 32-byte hex string
        string memory finalURI = string(abi.encodePacked(baseURI, randomSuffix, ".json"));

        _mint(to, tokenId, 1, ""); // Mint 1 token of this new or existing type
        eventIdForToken[tokenId] = requestToEventId[requestId];
        uriForToken[tokenId] = finalURI; // Set the randomly influenced URI

        // Clean up request mappings to save gas and state space
        delete requestToMinter[requestId];
        delete requestToURI[requestId];
        delete requestToEventId[requestId];

        emit RandomNFTMinted(requestId, tokenId, to);
    }

    /**
     * @dev Returns the URI for a given token ID.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return uriForToken[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}