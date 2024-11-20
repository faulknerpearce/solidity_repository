const { getContractInstance } = require("./getContractInstance");
const path = require('path');
const fs = require('fs');

async function setSource() {

  const source = fs.readFileSync(path.resolve(__dirname, 'source.js'), 'utf8');
  
  const contract = getContractInstance();

  console.log(`Setting new source code.` );

  const tx = await contract.setSource(source);
  
  console.log(`New source set. Transaction hash: ${tx.hash}`);
}

setSource().catch(console.error);
