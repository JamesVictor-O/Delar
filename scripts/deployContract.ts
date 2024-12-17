import { ethers } from 'hardhat';

async function main() {
    const DelarContractFactory = await ethers.getContractFactory('DelarContract');
    
    // Deploy the contract
    const DelarContract = await DelarContractFactory.deploy('0x49aC2AD1785d9577aF52a4Cd1511DcCC3AC42704', '0x134Ae99f229340fAcbe6F68cd21235BAD97670CF');

    // Wait for the deployment to finish
    await DelarContract.waitForDeployment();

    const DelarContractAddress = await DelarContract.getAddress();

    // Log the address where the contract is deployed
    console.log('DelarContract Contract Deployed at:', DelarContractAddress);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});