async function deployContract(){

    const Test = await ethers.getContractFactory("Test");

    console.log('\nDeploying Contract.')
    
    const TestContract = await Test.deploy(100);

    const tx = await TestContract.deploymentTransaction();
    
    console.log(`contract deployed succsefully`)
    console.log(`Transaction Hash: ${tx.hash}`)

    const address = await TestContract.getAddress()

    console.log(`Contract Address ${address}\n`);
}

deployContract();
