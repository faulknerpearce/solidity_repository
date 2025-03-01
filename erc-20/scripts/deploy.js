async function deployContract(){

    const Contract = await ethers.getContractFactory("Token");

    console.log('\nDeploying Contract.')
    
    const deployedContract = await Contract.deploy(1000); // Set the initial supply when deploying the contract.

    const tx = await deployedContract.deploymentTransaction();
    
    console.log(`contract deployed successfully\n`)
    console.log(`Transaction Hash: ${tx.hash}`)

    const address = await deployedContract.getAddress()

    console.log(`Contract Address ${address}\n`);
}

deployContract();
