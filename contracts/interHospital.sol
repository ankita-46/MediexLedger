// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MediexLedger {
    struct MedicineRequest {
        string requestingHospital;
        string recipientHospital;
        string medicineName;
        uint256 quantity;
        string status; // pending, accepted, rejected
        address requesterAddress;
    }

    mapping(uint256 => MedicineRequest) public requests;
    uint256 public requestCounter;

    event RequestCreated(
        uint256 requestId,
        string requestingHospital,
        string recipientHospital,
        string medicineName,
        uint256 quantity,
        string status,
        address requesterAddress
    );

    event RequestUpdated(uint256 requestId, string newStatus);

    // Function to create a new medicine request
    function createRequest(
        string memory _requestingHospital,
        string memory _recipientHospital,
        string memory _medicineName,
        uint256 _quantity,
        address _requesterAddress
    ) public {
        require(_quantity > 0, "Quantity must be greater than 0");

        MedicineRequest memory newRequest = MedicineRequest({
            requestingHospital: _requestingHospital,
            recipientHospital: _recipientHospital,
            medicineName: _medicineName,
            quantity: _quantity,
            status: "pending",
            requesterAddress: _requesterAddress
        });

        requests[requestCounter] = newRequest;

        emit RequestCreated(
            requestCounter,
            _requestingHospital,
            _recipientHospital,
            _medicineName,
            _quantity,
            "pending",
            _requesterAddress
        );

        requestCounter++;
    }

    // Function to update the status of a request
    function updateRequestStatus(uint256 _requestId, string memory _newStatus) public {
        require(_requestId < requestCounter, "Invalid request ID");

        MedicineRequest storage request = requests[_requestId];

        // Only the recipient hospital can update the status
        require(
            keccak256(abi.encodePacked(request.recipientHospital)) == keccak256(abi.encodePacked(msg.sender)),
            "Only the recipient hospital can update the request status"
        );

        request.status = _newStatus;

        emit RequestUpdated(_requestId, _newStatus);
    }

    // Function to get details of a specific request
    function getRequest(uint256 _requestId) public view returns (
        string memory,
        string memory,
        string memory,
        uint256,
        string memory,
        address
    ) {
        require(_requestId < requestCounter, "Invalid request ID");

        MedicineRequest memory request = requests[_requestId];
        return (
            request.requestingHospital,
            request.recipientHospital,
            request.medicineName,
            request.quantity,
            request.status,
            request.requesterAddress
        );
    }
}
