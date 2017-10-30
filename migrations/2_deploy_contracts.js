var DevDao = artifacts.require("./DevDao.sol");
module.exports = function (deployer) {
  deployer.deploy(DevDao, ['0x540d506419bca13cb0c7fc17ddcf2205350a837c',
  '0x966bd3c5d57b15d2cd893b41a92f2712bf421e34',
  '0x75d157e9ce14f48efc67253f37b577c703aa63ec',
  '0xfd15ac22a01cc5667b9fe7752e25af2f4c68c0bf',
  '0xceac815bc46645357d730b0f53e1291b8e8685fa',
  '0x3cb0434d6d6b60ccbe900c55ea37d06a1b649f95',
  '0x3c4b8c6ace4685a2ed6709e421c92c18a5afdce1']);
};

