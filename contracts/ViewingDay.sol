// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
 * @title Kansong Metaverse Museum First Viewing Day Ticket NFT
 * @author Atomrigs Lab
 **/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

contract ViewingDay is ERC721Enumerable{

    uint256 public maxSupply = 200;
    uint256 private _tokenId;
    address private _owner;
    mapping(address => bool)  private _operators;

    modifier onlyOperators() {
        require(_checkOperators(), "ViewingDay: Not an operator");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "ViewingDay: Not the owner");
        _;
    }

    constructor(address _operator) ERC721("Kansong Metaverse Museum First Viewing Day Ticket NFT", "KMM-ViewingDay") {
        _owner = msg.sender;
        _operators[_operator] = true;
    }

    function _checkOperators() private view returns (bool) {
        if (msg.sender == _owner || _operators[msg.sender]) {
            return true;
        } 
        return false;
    }

    function updateOperator(address newOperator, bool isActive) external onlyOwner() {
        _operators[newOperator] = isActive;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function safeMint(address toAddr, uint256 tokenId) private returns (bool) {
        _safeMint(toAddr, tokenId);
        return true;
    }

    function mint(address toAddr, uint256 count) public onlyOperators {

        require(_tokenId + count <= maxSupply, "ViewingDay: minting count over maxSupply");
        for (uint256 i = 0; i < count; i++) {
            _tokenId++;

            require(
                safeMint(toAddr, _tokenId),
                "ViewingDay-NFT: minting failed"
            );
        }
    }

    function batchMint(address[] calldata toAddrs, uint256[] calldata counts) external onlyOperators {
        for (uint256 i = 0; i < toAddrs.length; i++) {
            mint(toAddrs[i], counts[i]);
        }
    }


    function tokensOf(address _account) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](balanceOf(_account));
        for (uint256 i; i < balanceOf(_account); i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_account, i);
        }
        return tokenIds;
    }

    function getDescription() internal pure returns (string memory) {
        string memory desc = "Kansong Metaverse Museum's First Viewing Day Ticket NFT";
        return desc;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        if (_ownerOf(tokenId) == address(0)) {
          return false;
        }
        return true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ViewingDay: TokenId not minted yet");
        string memory img = "https://moccasin-flexible-flamingo-222.mypinata.cloud/ipfs/Qmdtwqmhh4YkRBnN1gEz6sUYRDDyi3rs3HXaJGU3GEhzr4";
        string memory description = getDescription();
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Kansong Metaverse Museum First Viewing Day NFT #',
                        toString(tokenId),
                        '", "description": "',
                        description,
                        '", "image": "',
                        img,
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

