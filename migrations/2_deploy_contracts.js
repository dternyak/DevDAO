var DevDAO = artifacts.require('./DevDAO.sol');

module.exports = function(deployer) {
  deployer.deploy(DevDAO);
};
