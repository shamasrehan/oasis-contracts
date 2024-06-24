import { expect } from "chai";
import { Contract } from "ethers";
import { artifacts, ethers, waffle } from "hardhat";

import { SettlementReader, packOrderUidParams } from "../src/ts";

describe("SettlementStorageReader", () => {
  const [deployer, owner, ...traders] = waffle.provider.getWallets();
  let settlement: Contract;
  let reader: Contract;
  let settlementReader: SettlementReader;

  beforeEach(async () => {
    const OPv1AllowListAuthentication = await ethers.getContractFactory(
      "OPv1AllowListAuthentication",
      deployer,
    );
    const authenticator = await OPv1AllowListAuthentication.deploy();
    await authenticator.initializeManager(owner.address);

    const IVault = await artifacts.readArtifact("IVault");
    const vault = await waffle.deployMockContract(deployer, IVault.abi);

    const OPv1Settlement = await ethers.getContractFactory(
      "OPv1SettlementTestInterface",
      deployer,
    );
    settlement = await OPv1Settlement.deploy(
      authenticator.address,
      vault.address,
    );

    const SettlementStorageReader = await ethers.getContractFactory(
      "SettlementStorageReader",
      deployer,
    );
    reader = await SettlementStorageReader.deploy();

    settlementReader = new SettlementReader(settlement, reader);
  });

  describe("filledAmountsForOrders(bytes[] calldata orderUids)", () => {
    it("returns expected filledAmounts", async () => {
      // construct 3 unique order Ids and invalidate the first two.
      const orderUids = [0, 1, 2].map((i) =>
        packOrderUidParams({
          orderDigest: "0x" + "11".repeat(32),
          owner: traders[i].address,
          validTo: 2 ** 32 - 1,
        }),
      );

      await settlement.connect(traders[0]).invalidateOrder(orderUids[0]);
      await settlement.connect(traders[1]).invalidateOrder(orderUids[1]);

      expect(
        await settlementReader.filledAmountsForOrders(orderUids),
      ).to.deep.equal([
        ethers.constants.MaxUint256,
        ethers.constants.MaxUint256,
        ethers.constants.Zero,
      ]);
    });
  });
});
