const Web3 = require('web3');
const devDaoAbi = require('./build/contracts/DevDao.json');
const src = require('./contracts/string');
const web3 = new Web3('http://localhost:8545');
const devDao = new web3.eth.Contract(devDaoAbi);

let x = devDao.deploy({ data: src, arguments: ['0x90f8cc1998df958c48f4f847ab6cb57605731256'] });
console.log(x);
x.send({
  from: '0x42390f8fbb4c96e418f2a0cfba3fb9c7d912ee03',
  gas: 1500000,
  gasPrice: '30000000000000'
});
/*    
  .on('error', function(error) {
    console.log(error);
  })
  .on('transactionHash', function(transactionHash) {
    console.log(transactionHash);
  })
  .on('receipt', function(receipt) {
    console.log(receipt.contractAddress); // contains the new contract address
  })
  .on('confirmation', function(confirmationNumber, receipt) {
    console.log(confirmationNumber, receipt);
  })
  .then(function(newContractInstance) {
    console.log(newContractInstance.options.address); // instance with the new contract address
  });
*/
