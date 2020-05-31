// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


/**
 * @title DIDRegistry
 * @dev DID Registry for the Signor DID method.
 * A DID is controlled by their creator address by default, but control can be assigned to any
 * different adddress by their current controller.
 */
contract DIDRegistry {


    struct DID {
        address controller;
        address subject;
        uint256 created;
        uint256 updated;
        Key[] keys;
    }

    enum KeyPurpose { Authentication, Signing, Encryption }

    //public key
    struct Key {
        bytes32 x;
        bytes32 y;
        KeyPurpose purpose;
        string curve;
    }


    mapping(bytes32 => DID) public dids;

    uint256 public nonce = 0;


    event CreatedDID(bytes32 id);
    event DeletedDID(bytes32 id);
    event SetController(bytes32 id, address newController);

    modifier onlyController(bytes32 id) {
        require(dids[id].controller == msg.sender, "transaction sender is not DID controller");
        _;
    }

    /**
     * @dev Register new DID.
     * @param _subject - The DID subject
     */
    function createDID(address _subject)
        public
        returns (bytes32)
    {
        require(_subject != address(0), "subject address cannot be 0");
        bytes32 _id = keccak256(abi.encodePacked(msg.sender, nonce));

        dids[_id].controller = msg.sender;
        dids[_id].subject = _subject;
        dids[_id].created = now;
        dids[_id].updated = now;
        nonce = nonce + 1;

        emit CreatedDID(_id);
        return _id;
    }


    /**
     * @dev Remove DID. Only callable by DID controller.
     * @param id — The identifier (DID) to be deleted
     */
    function deleteDID(bytes32 id)
        public
        onlyController(id)
    {
        delete dids[id];
        emit DeletedDID(id);
    }

    /**
     * @dev Returns corresponding controller for given DID
     * @param id — The identifier (DID) to be resolved to its controller address
     */
    function getController(bytes32 id)
        public
        view
        returns (address)
    {
        return dids[id].controller;
    }


     /**
     * @dev Returns corresponding subject of a given DID
     * @param id — The identifier (DID) to be resolved to its subject address
     */
    function getSubject(bytes32 id)
        public
        view
        returns (address)
    {
        return dids[id].subject;
    }

    /*https://medium.com/coinmonks/solidity-tutorial-returning-structs-from-public-functions-e78e48efb378*/

    function getKeys(bytes32 id) public view returns ( bytes32[] memory, bytes32[] memory, uint[] memory, string[] memory){
        DID memory did = dids[id];
        uint keysLength = did.keys.length;

        bytes32[] memory x;
        bytes32[] memory y;
        uint[] memory purpose;
        string[] memory curve;

        for(uint i = 0; i < keysLength; i++) {
            Key memory key = did.keys[i];
            x[i] = key.x;
            y[i] = key.y;
            purpose[i] = uint(key.purpose);
            curve[i] = key.curve;
        }

        return (x,y,purpose,curve);
    }

    /**
     * @dev Change controller address. Only callable by current DID controller.
     * @param id — The identifier (DID) to be updated
     * @param newController — New controller addresss
     */
    function setController(bytes32 id, address newController)
        public
        onlyController(id)
    {
        dids[id].controller = newController;
        dids[id].updated = now;
        emit SetController(id, newController);
    }


    /*Should ckeck if DID exists before allowing key to be added*/
    function addKey(bytes32 id, bytes32 _x, bytes32 _y, KeyPurpose _purpose, string memory _curve)
        public
        onlyController(id)
    {
        dids[id].keys.push(Key(_x, _y, _purpose, _curve));

    }
}