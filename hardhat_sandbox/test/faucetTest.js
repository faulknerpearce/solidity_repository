const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = require('chai');

describe('Faucet', function () {
  async function deployContractAndSetVariables() {
    const Faucet = await ethers.getContractFactory('Faucet');
    const faucet = await Faucet.deploy();

    const [owner, nonOwner] = await ethers.getSigners();

    let withdrawAmount = ethers.parseUnits('1', 'ether');

    console.log('Signer 1 address: ', owner.address);
    return { faucet, owner, nonOwner, withdrawAmount};
  }

  it('should deploy and set the owner correctly', async function () {
    const { faucet, owner } = await loadFixture(deployContractAndSetVariables);

    expect(await faucet.owner()).to.equal(owner.address);
  });

  it('should not allow withdrawals above .1 ETH at a time', async function () {
    const { faucet, withdrawAmount } = await loadFixture(deployContractAndSetVariables);
    
    await expect(faucet.withdraw(withdrawAmount)).to.be.reverted;
  });

  it('should allow only the owner to initiate the self destruct function', async function () {
    const { faucet, owner, nonOwner } = await loadFixture(deployContractAndSetVariables);
  
    await expect(faucet.connect(owner).destroyFaucet()).to.not.be.reverted;
  
    const { faucet: newFaucet } = await loadFixture(deployContractAndSetVariables);

    await expect(newFaucet.connect(nonOwner).destroyFaucet()).to.be.reverted;
  });
});