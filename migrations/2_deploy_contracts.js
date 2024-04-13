const Transactions = artifacts.require("Transactions");

module.exports = function(deployer) {
  deployer.deploy(Transactions, "0x67E659a2EA5A27bB3B0cd02c785011e3F5BE670B");
};