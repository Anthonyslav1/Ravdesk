import { createContext } from "react";
import { Mumbai, FuseSparknet } from "@thirdweb-dev/chains";
const ChainContext = createContext({
    selectedChain: Mumbai,
    setSelectedChain: (chain: string) => {},
});

export default ChainContext;