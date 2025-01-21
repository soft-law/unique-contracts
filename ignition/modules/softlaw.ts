import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Softlaw", (m) => {
  const apollo = m.contract("Softlaw", []);

  //   m.call(apollo, "launch", []);

  return { apollo };
});
