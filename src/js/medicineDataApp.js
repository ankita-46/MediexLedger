App = {
    web3Provider: null,
    contracts: {},

    init: async function() {
        return await App.initWeb3();
    },

    initWeb3: function() {
        if(window.web3) {
            App.web3Provider=window.web3.currentProvider;
        } else {
            App.web3Provider=new Web3.proviers.HttpProvider('http://localhost:7545');
        }

        web3 = new Web3(App.web3Provider);
        return App.initContract();
    },

    initContract: function() {

        $.getJSON('medicine.json',function(data){

            var medicineArtifact=data;
            App.contracts.medicine=TruffleContract(medicineArtifact);
            App.contracts.medicine.setProvider(App.web3Provider);
        });

        return App.bindEvents();
    },

    bindEvents: function() {

        $(document).on('click','.btn-register',App.getData);
    },

    getData:function(event) {
        event.preventDefault();
        var sellerCode = document.getElementById('sellerCode').value;

        var medicineInstance;
        //window.ethereum.enable();
        web3.eth.getAccounts(function(error,accounts){

            if(error) {
                console.log(error);
            }

            var account=accounts[0];
            // console.log(account);

            App.contracts.medicine.deployed().then(function(instance){

                medicineInstance=instance;
                return medicineInstance.querymedicinesList(web3.fromAscii(sellerCode),{from:account});

            }).then(function(result){
                
                //console.log()
                var medicineIds=[];
                var medicineSNs=[];
                var medicineNames=[];
                var medicineBrands=[];
                var medicinePrices=[];
                var medicineStatus=[];

                // console.log(result);
                
                for(var k=0;k<result[0].length;k++){
                    medicineIds[k]=result[0][k];
                }

                for(var k=0;k<result[1].length;k++){
                    medicineSNs[k]=web3.toAscii(result[1][k]);

                }

                for(var k=0;k<result[2].length;k++){
                    medicineNames[k]=web3.toAscii(result[2][k]);
                }

                for(var k=0;k<result[3].length;k++){
                    medicineBrands[k]=web3.toAscii(result[3][k]);
                }

                for(var k=0;k<result[4].length;k++){
                    medicinePrices[k]=result[4][k];
                }

                for(var k=0;k<result[5].length;k++){
                    medicineStatus[k]=web3.toAscii(result[5][k]);
                }

                var t= "";
                document.getElementById('logdata').innerHTML = t;
                for(var i=0;i<result[0].length;i++) {
                    var temptr = "<td>"+medicinePrices[i]+"</td>";
                    if(temptr === "<td>0</td>"){
                        break;
                    }

                    var tr="<tr>";
                    tr+="<td>"+medicineIds[i]+"</td>";
                    tr+="<td>"+medicineSNs[i]+"</td>";
                    tr+="<td>"+medicineNames[i]+"</td>";
                    tr+="<td>"+medicineBrands[i]+"</td>";
                    tr+="<td>"+medicinePrices[i]+"</td>";
                    tr+="<td>"+medicineStatus[i]+"</td>";
                    tr+="</tr>";
                    t+=tr;

                }
                document.getElementById('logdata').innerHTML += t;
                document.getElementById('add').innerHTML=account;
           }).catch(function(err){
               console.log(err.message);
           })
        })
    }
};

$(function() {
    $(window).load(function() {
        App.init();
    })
})