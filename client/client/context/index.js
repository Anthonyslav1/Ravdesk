import React, { useContext, createContext } from 'react';

import { useAddress, useContract, ConnectWallet, useContractWrite } from '@thirdweb-dev/react';
import { ethers } from 'ethers';
import { EditionMetadataWithOwnerOutputSchema } from '@thirdweb-dev/sdk';

const StateContext = createContext();

export const StateContextProvider = ({ children }) => {
  const { contract } = useContract('0xf59A1f8251864e1c5a6bD64020e3569be27e6AA9');
  const { mutateAsync: createProject } = useContractWrite(contract, 'createProject');

  const address = useAddress();
  const connect = ConnectWallet();

  const publishProject = async (form) => {
    try {
      const data = await createProject({
				args: [
					form.fundingGoal,
					form.name, // name
					//form.description, // description
					
					new Date(form.fundingPeriod).getTime(), // fundingPeriod,
					//form.image,
				],
			});

      console.log("contract call success", data)
    } catch (error) {
      console.log("contract call failure", error)
    }
  }

  const getAllProjects = async () => {
    const Projects = await contract.call('getAllProjects');

    const parsedProjects = Projects.map((Project, i) => ({
      owner: Project.owner,
      fundingGoal: ethers.utils.formatEther(Project.fundingGoal.toString()),
      name: Project.name,
      //description: Project.description,
      
      fundingPeriod: Project.fundingPeriod.toNumber(),
      currentBalance: ethers.utils.formatEther(Project.currentBalance.toString()),
      //image: Project.image,
      projectId: i
    }));

    return parsedProjects;
  }

  const getUserProjects = async () => {
    const allProjects = await getProjects();

    const filteredProjects = allProjects.filter((Project) => Project.owner === address);

    return filteredProjects;
  }

 // const getFundedProjects = async () => {
    //const allProjects = await getProjects();

   // const filteredProjects = allProjects.filter((Project) => Project.funderAddress === includes(address));

    //return filteredProjects;
  //}

  const donate = async (projectId, amount) => {
    const data = await contract.fundProject( projectId, { value: ethers.utils.parseEther(amount)});

    return data;
  }

  const getDonations = async (projectId) => {
    const donations = await contract.call('getFunderAddresses', [projectId]);
    const numberOfDonations = donations[0].length;

    const parsedDonations = [];

    for(let i = 0; i < numberOfDonations; i++) {
      parsedDonations.push({
        donator: donations[0][i],
        donation: ethers.utils.formatEther(donations[1][i].toString())
      })
    }

    return parsedDonations;
  }


  return (
    <StateContext.Provider
      value={{ 
        address,
        contract,
        connect,
        createProject: publishProject,
        getProjects,
        getUserProjects,
        donate,
        getDonations
      }}
    >
      {children}
    </StateContext.Provider>
  )
}

export const useStateContext = () => useContext(StateContext);