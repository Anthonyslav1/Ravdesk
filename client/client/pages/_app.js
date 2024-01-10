import { ThirdwebProvider } from '@thirdweb-dev/react';
import '../styles/globals.css';
import { FuseSparknet } from "@thirdweb-dev/chains";
import { errors } from 'ethers';
//import ChainContext from './chain';
//import { useState } from 'react';
// This is the chain your dApp will work on.
// Change this to the chain your app is built for.
// You can also import additional chains from `@thirdweb-dev/chains` and pass them directly.


function MyApp({ Component, pageProps }) {
	//const [selectedChain, setSelectedChain] = useState(FuseSparknet)
	return (
		//<ChainContext.Provider value={{selectedChain, setSelectedChain}}>
		<ThirdwebProvider theme= "dark"
		 activeChain={FuseSparknet}
		 supportedChains={[FuseSparknet]}
		 
			
			clientId={process.env.NEXT_PUBLIC_TEMPLATE_CLIENT_ID}
		>
			<Component {...pageProps} />
		</ThirdwebProvider>
		//</ChainContext.Provider>
	);
}

export default MyApp;
