// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

// allows passing and returning structs and arrays in function calls.

contract Transactions {
    
    address Creator;
    
    struct txns {
        bytes32 txnHash;
        address fromAddr;
        address toAddr;
        bytes32 prevTxn;
        string latitude;    
        string longitude;
        uint timestamp;
    }
    
    mapping(uint => txns) public transactions; //mapping of transaction index to transaction structures txns
    //mapping to store all transactions
    uint public txnCount = 0;
    //this var keeps track of total no of transactions in transactions mapping
    
    constructor(address _creator) {
    Creator = _creator;
    //Defines the constructor function, which is executed only once during contract deployment.
    // It takes one parameter _creator, an address representing the creator of the contract,
    // and assigns it to the Creator state variable.
}
    
    event txnCreated(bytes32 _txnHash, address _from, address _to, bytes32 _prev, uint _timestamp, string _latitude, string _longitude);
    //event is like slip like that transaction is done
    //Declares an event named txnCreated that is emitted when a new transaction is created.
    // It logs the transaction hash, sender address, receiver address, previous transaction hash, timestamp,
    // latitude, and longitude.
    function createTxnEntry(bytes32 _txnHash, address _from, address _to, bytes32 _prev, string memory _latitude, string memory _longitude) public {
    uint _timestamp = block.timestamp;
   
    if(txnCount == 0) {
            transactions[txnCount] = txns(_txnHash, _from, _to, _prev, _latitude, _longitude, _timestamp);
        } else {
            require(transactions[txnCount - 1].txnHash == _prev, "Transaction error occurred!");
            transactions[txnCount] = txns(_txnHash, _from, _to, _prev, _latitude, _longitude, _timestamp);
        }
        txnCount += 1;
        emit txnCreated(_txnHash, _from, _to, _prev, _timestamp, _latitude, _longitude);
}
    

    function getAllTransactions() public view returns(txns[] memory) {
        uint len = txnCount;
        txns[] memory ret = new txns[](len);
        for (uint i = 0; i < len; i++) {
            ret[i] = transactions[i];
        }
        return ret;    
    }
    
}