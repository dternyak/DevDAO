// DevDao.deployed().then(function(instance) { devdao = instance; });

module.exports = function (callback) {
    // perform actions
    var accounts;
    // in web front-end, use an onload listener and similar to this manual flow ... 
    web3.eth.getAccounts(function (err, res) {
        accounts = res;
        for (var i = 3; i < 10; i++) {
            var account = accounts[i];
            var contract;
            DevDao.deployed()
            .then(function (response) {
                contract = response;
                console.log(contract.setCustodianVote('0xe6902f3f0a25458b766bfb2160a9c8330ff9466e', { from: account }));
            });
        }

    });
};      


// web3.eth.getAccounts(function (err, res) { console.log(res)})
