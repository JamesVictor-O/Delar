import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenAddress = "0x0A547dF8b423B1269225Ee7588986F74E2db9423";
const NFTAddress = "0x134Ae99f229340fAcbe6F68cd21235BAD97670CF";

const DelarContractModule = buildModule("DelarContractModule", (m) => {

    const DelarContract = m.contract("DelarContract", [tokenAddress, NFTAddress]);

    return { DelarContract };
});

export default DelarContractModule;
