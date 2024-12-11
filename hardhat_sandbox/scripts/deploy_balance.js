async function deployContract(){

    const Test = await ethers.getContractFactory("Test");

    console.log('\nDeploying Contract.')
    
    const TestContract = await Test.deploy(100); // Amount to deploy with the contract.

    const tx = await TestContract.deploymentTransaction();
    
    console.log(`contract deployed successfully`)
    console.log(`Transaction Hash: ${tx.hash}`)

    const address = await TestContract.getAddress()

    console.log(`Contract Address ${address}\n`);
}

deployContract();
