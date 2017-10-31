import contract = require('truffle-contract');
import Web3 = require('web3');
import {} from 'path';
Web3.providers.HttpProvider.prototype.sendAsync = Web3.providers.HttpProvider.prototype.send; // fix dep mismatch
const provider = new Web3.providers.HttpProvider('http://localhost:8545');
const web3 = new Web3(provider);

const devDaoAbi = require(`${process.cwd()}/build/contracts/DevDao`);

export const main = async () => {
  const accounts = await web3.eth.getAccounts();
  const myContract = await contract(devDaoAbi);
  await myContract.setProvider(provider);
  const currentNetwork = await web3.eth.net.getId();

  myContract.defaults({ from: accounts[0], gas: '2000000' });
  myContract.setNetwork(currentNetwork);

  try {
    const myContractInstance = await myContract.new(accounts.slice(0, 7));
    console.log(await myContractInstance.getCustodian());
  } catch (e) {
    console.log(e);
  }
};
