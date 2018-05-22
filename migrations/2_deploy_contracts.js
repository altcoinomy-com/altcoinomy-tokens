var winetoken = artifacts.require('./WineToken.sol');

module.exports = function(deployer) {
  deployer.deploy(winetoken);
};
