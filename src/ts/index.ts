import { TypedDataDomain } from "./types/ethers";

/**
 * Return the Oasis Protocol v1 domain used for signing.
 * @param chainId The EIP-155 chain ID.
 * @param verifyingContract The address of the contract that will verify the
 * signature.
 * @return An EIP-712 compatible typed domain data.
 */
export function domain(
  chainId: number,
  verifyingContract: string,
): TypedDataDomain {
  return {
    name: "Oasis Protocol",
    version: "v1",
    chainId,
    verifyingContract,
  };
}

export * from "./deploy";
export * from "./interaction";
export * from "./order";
export * from "./proxy";
export * from "./reader";
export * from "./settlement";
export * from "./sign";
export * from "./swap";
export * from "./vault";
export * from "./types/ethers";
