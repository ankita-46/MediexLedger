// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract medicine {

    uint256 sellerCount;
    uint256 medicineCount;

     // Structure to store seller information
    struct seller{
        uint256 sellerId;
        bytes32 sellerName;
        bytes32 sellerBrand;
        bytes32 sellerCode;
        uint256 sellerNum;
        bytes32 sellerManager;
        bytes32 sellerAddress;
    }
    mapping(uint=>seller) public sellers;

    // Structure to store medicine information
    struct medicineItem{
        uint256 medicineId;
        bytes32 medicineSN;
        bytes32 medicineName;
        bytes32 medicineBrand;
        uint256 medicinePrice;
        bytes32 medicineStatus;
    }

    mapping(uint256=>medicineItem) public medicineItems;
    mapping(bytes32=>uint256) public medicineMap;
    mapping(bytes32=>bytes32) public medicinesManufactured;
    mapping(bytes32=>bytes32) public medicinesForSale;
    mapping(bytes32=>bytes32) public medicinesSold;
    mapping(bytes32=>bytes32[]) public medicinesWithSeller;
    mapping(bytes32=>bytes32[]) public medicinesWithConsumer;
    mapping(bytes32=>bytes32[]) public sellersWithManufacturer;


    //SELLER SECTION

     // Add a new seller
    function addSeller(bytes32 _manufacturerId, bytes32 _sellerName, bytes32 _sellerBrand, bytes32 _sellerCode,
    uint256 _sellerNum, bytes32 _sellerManager, bytes32 _sellerAddress) public{
        sellers[sellerCount] = seller(sellerCount, _sellerName, _sellerBrand, _sellerCode,
        _sellerNum, _sellerManager, _sellerAddress);
        sellerCount++;

        sellersWithManufacturer[_manufacturerId].push(_sellerCode);
    }

     // View all sellers
    function viewSellers () public view returns(uint256[] memory, bytes32[] memory, bytes32[] memory, bytes32[] memory, uint256[] memory, bytes32[] memory, bytes32[] memory) {
        uint256[] memory ids = new uint256[](sellerCount);
        bytes32[] memory snames = new bytes32[](sellerCount);
        bytes32[] memory sbrands = new bytes32[](sellerCount);
        bytes32[] memory scodes = new bytes32[](sellerCount);
        uint256[] memory snums = new uint256[](sellerCount);
        bytes32[] memory smanagers = new bytes32[](sellerCount);
        bytes32[] memory saddress = new bytes32[](sellerCount);
        
        for(uint i=0; i<sellerCount; i++){
            ids[i] = sellers[i].sellerId;
            snames[i] = sellers[i].sellerName;
            sbrands[i] = sellers[i].sellerBrand;
            scodes[i] = sellers[i].sellerCode;
            snums[i] = sellers[i].sellerNum;
            smanagers[i] = sellers[i].sellerManager;
            saddress[i] = sellers[i].sellerAddress;
        }
        return(ids, snames, sbrands, scodes, snums, smanagers, saddress);
    }

    //medicine SECTION

    //add medicine
    function addmedicine(bytes32 _manufactuerID, bytes32 _medicineName, bytes32 _medicineSN, bytes32 _medicineBrand,
    uint256 _medicinePrice) public{
        medicineItems[medicineCount] = medicineItem(medicineCount, _medicineSN, _medicineName, _medicineBrand,
        _medicinePrice, "Available");
        medicineMap[_medicineSN] = medicineCount;
        medicineCount++;
        medicinesManufactured[_medicineSN] = _manufactuerID;
    }
    
    //view all medicines added
    function viewmedicineItems () public view returns(uint256[] memory, bytes32[] memory, bytes32[] memory, bytes32[] memory, uint256[] memory, bytes32[] memory) {
        uint256[] memory pids = new uint256[](medicineCount);
        bytes32[] memory pSNs = new bytes32[](medicineCount);
        bytes32[] memory pnames = new bytes32[](medicineCount);
        bytes32[] memory pbrands = new bytes32[](medicineCount);
        uint256[] memory pprices = new uint256[](medicineCount);
        bytes32[] memory pstatus = new bytes32[](medicineCount);
        
        for(uint i=0; i<medicineCount; i++){
            pids[i] = medicineItems[i].medicineId;
            pSNs[i] = medicineItems[i].medicineSN;
            pnames[i] = medicineItems[i].medicineName;
            pbrands[i] = medicineItems[i].medicineBrand;
            pprices[i] = medicineItems[i].medicinePrice;
            pstatus[i] = medicineItems[i].medicineStatus;
        }
        return(pids, pSNs, pnames, pbrands, pprices, pstatus);
    }

    //SELL medicine

    // Function to record the sale of medicine by a manufacturer
    function manufacturerSellmedicine(bytes32 _medicineSN, bytes32 _sellerCode) public{
        medicinesWithSeller[_sellerCode].push(_medicineSN);
        medicinesForSale[_medicineSN] = _sellerCode;

    }

    // Function to record the sale of medicine by a seller to a consumer
    function sellerSellmedicine(bytes32 _medicineSN, bytes32 _consumerCode) public{   
        bytes32 pStatus;
        uint256 i;
        uint256 j=0;

        if(medicineCount>0) {
            for(i=0;i<medicineCount;i++) {
                if(medicineItems[i].medicineSN == _medicineSN) {
                    j=i;
                }
            }
        }

        pStatus = medicineItems[j].medicineStatus;
        if(pStatus == "Available") {
            medicineItems[j].medicineStatus = "NA";
            medicinesWithConsumer[_consumerCode].push(_medicineSN);
            medicinesSold[_medicineSN] = _consumerCode;
        }


    }

    // Function to query the list of medicines available for sale by a particular seller
    function querymedicinesList(bytes32 _sellerCode) public view returns(uint256[] memory, bytes32[] memory, bytes32[] memory, bytes32[] memory, uint256[] memory, bytes32[] memory){
        bytes32[] memory medicineSNs = medicinesWithSeller[_sellerCode];
        uint256 k=0;

        uint256[] memory pids = new uint256[](medicineCount);
        bytes32[] memory pSNs = new bytes32[](medicineCount);
        bytes32[] memory pnames = new bytes32[](medicineCount);
        bytes32[] memory pbrands = new bytes32[](medicineCount);
        uint256[] memory pprices = new uint256[](medicineCount);
        bytes32[] memory pstatus = new bytes32[](medicineCount);

        
        for(uint i=0; i<medicineCount; i++){
            for(uint j=0; j<medicineSNs.length; j++){
                if(medicineItems[i].medicineSN==medicineSNs[j]){
                    pids[k] = medicineItems[i].medicineId;
                    pSNs[k] = medicineItems[i].medicineSN;
                    pnames[k] = medicineItems[i].medicineName;
                    pbrands[k] = medicineItems[i].medicineBrand;
                    pprices[k] = medicineItems[i].medicinePrice;
                    pstatus[k] = medicineItems[i].medicineStatus;
                    k++;
                }
            }
        }
        return(pids, pSNs, pnames, pbrands, pprices, pstatus);
    }

    // Function to query the list of sellers associated with a specific manufacturer
    function querySellersList (bytes32 _manufacturerCode) public view returns(uint256[] memory, bytes32[] memory, bytes32[] memory, bytes32[] memory, uint256[] memory, bytes32[] memory, bytes32[] memory) {
        bytes32[] memory sellerCodes = sellersWithManufacturer[_manufacturerCode];
        uint256 k=0;
        uint256[] memory ids = new uint256[](sellerCount);
        bytes32[] memory snames = new bytes32[](sellerCount);
        bytes32[] memory sbrands = new bytes32[](sellerCount);
        bytes32[] memory scodes = new bytes32[](sellerCount);
        uint256[] memory snums = new uint256[](sellerCount);
        bytes32[] memory smanagers = new bytes32[](sellerCount);
        bytes32[] memory saddress = new bytes32[](sellerCount);
        
        for(uint i=0; i<sellerCount; i++){
            for(uint j=0; j<sellerCodes.length; j++){
                if(sellers[i].sellerCode==sellerCodes[j]){
                    ids[k] = sellers[i].sellerId;
                    snames[k] = sellers[i].sellerName;
                    sbrands[k] = sellers[i].sellerBrand;
                    scodes[k] = sellers[i].sellerCode;
                    snums[k] = sellers[i].sellerNum;
                    smanagers[k] = sellers[i].sellerManager;
                    saddress[k] = sellers[i].sellerAddress;
                    k++;
                    break;
               }
            }
        }

        return(ids, snames, sbrands, scodes, snums, smanagers, saddress);
    }
    
    //to get purchase history of any particular consumer 
    function getPurchaseHistory(bytes32 _consumerCode) public view returns (bytes32[] memory, bytes32[] memory, bytes32[] memory){
        bytes32[] memory medicineSNs = medicinesWithConsumer[_consumerCode];
        bytes32[] memory sellerCodes = new bytes32[](medicineSNs.length);
        bytes32[] memory manufacturerCodes = new bytes32[](medicineSNs.length);
        for(uint i=0; i<medicineSNs.length; i++){
            sellerCodes[i] = medicinesForSale[medicineSNs[i]];
            manufacturerCodes[i] = medicinesManufactured[medicineSNs[i]];
        }
        return (medicineSNs, sellerCodes, manufacturerCodes);
    }


    //Verify whether medicine is genuine or not

    function verifymedicine(bytes32 _medicineSN, bytes32 _consumerCode) public view returns(bool){
        if(medicinesSold[_medicineSN] == _consumerCode){
            return true;
        }
        else{
            return false;
        }
    }
}