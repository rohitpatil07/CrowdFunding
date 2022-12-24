import React, { useContext, createContext } from 'react';

import { useAddress, useContract, useMetamask, useContractWrite } from '@thirdweb-dev/react';
import { ethers } from 'ethers';
import { EditionMetadataWithOwnerOutputSchema } from '@thirdweb-dev/sdk';

const StateContext = createContext();

export const StateContextProvider = ({ children }) => {
  const { contract } = useContract('0x2E0d7ffa8ccF8fAcBeF93c87F89b4ad56b1ddbCB');
  const { mutateAsync: createCampaign } = useContractWrite(contract, 'createCampaign');

  const address = useAddress();
  const connect = useMetamask();

  const publishCampaign = async (form) => {
    try {
      const data = await createCampaign([
        address, // owner
        form.title, // title
        form.name, //name 
        form.description, // description
        form.target,
        new Date(form.deadline).getTime(), // deadline,
        form.image
      ])

      console.log("contract call success", data)
    } catch (error) {
      console.log("contract call failure", error)
    }
  }

  const getCampaigns = async () => {
    try {
      const campaigns = await contract.call('getCampaigns');

      const parsedCampaings = campaigns.map((campaign, i) => ({
        owner: campaign.owner,
        title: campaign.title,
        name: campaign.name,
        description: campaign.description,
        target: ethers.utils.formatEther(campaign.target.toString()),
        deadline: campaign.deadline.toNumber(),
        amountCollected: ethers.utils.formatEther(campaign.amountCollected.toString()),
        image: campaign.image,
        pId: i
      }));

      return parsedCampaings;
    } catch (error) {
      return [];
    }
  }

  const getUserCampaigns = async () => {
    try {
      const allCampaigns = await getCampaigns();

      const filteredCampaigns = allCampaigns.filter((campaign) => campaign.owner === address);

      return filteredCampaigns;
    } catch (error) {
        return [];
    }
  }

  const donate = async (pId, amount) => {
    try {

      const data = await contract.call('donate', pId, { value: ethers.utils.parseEther(amount)});
      return data;

    } catch (error) {
      return error;
    }
  }

  const close = async (pId) => {
    try {
      await contract.call("closeCampaign" , pId);
    } catch (error) {
      return error;
    }
  }

  const withdraw = async (pId) => {
    try {
      await contract.call("withdraw" , address ,pId);
    } catch (error) {
      console.log(error);
    }
  }

  const refund = async (pId , amount) => {
    try {
      console.log(pId , address , amount);
      const amountInWei = ethers.utils.parseEther(amount);
      const res = await contract.call("refundDonation", pId, address, amountInWei);
      console.log(res);
    } catch (error) {
      console.log(error);
    }
  }
      // await contract.call("refundDonation", pId,address,ethers.utils.parseEther(amount));


  const getDonations = async (pId) => {
    try {
      const donations = await contract.call('getDonators', pId);
      const numberOfDonations = donations[0].length;

      const parsedDonations = [];

      for(let i = 0; i < numberOfDonations; i++) {
        parsedDonations.push({
          donator: donations[0][i],
          donation: ethers.utils.formatEther(donations[1][i].toString())
        })
      }

      return parsedDonations;
    } catch (error) {
      return [];
    }
  }


  return (
    <StateContext.Provider
      value={{ 
        address,
        contract,
        connect,
        createCampaign: publishCampaign,
        getCampaigns,
        getUserCampaigns,
        donate,
        getDonations,
        close,
        withdraw,
        refund
      }}
    >
      {children}
    </StateContext.Provider>
  )
}

export const useStateContext = () => useContext(StateContext);