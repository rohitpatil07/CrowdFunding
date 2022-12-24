// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//To do
//Instead of directly sending funds to owner send to adress and give that  address withdraw function
//Option to cancel donations 

contract CrowdFunding {
    struct Campaign {
    address owner;
    string name;
    string title;
    string description;
    uint256 target;
    uint256 deadline;
    uint256 amountCollected;
    string image;
    address[] donators;
    uint256[] donations;
    uint256 id;  // Add this field to store the ID of the campaign
    }

    struct ClosedCampaign {
    address owner;
    string name;
    string title;
    string description;
    uint256 target;
    uint256 deadline;
    uint256 amountCollected;
    string image;
    address[] donators;
    uint256[] donations;
    uint256 id;  // Add this field to store the ID of the campaign
    }

    struct RefundMessage {
        address refundAddr;
        uint256 refundAmount;
    }

    // Replace the campaigns mapping with a sparse mapping
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => ClosedCampaign) public closedCampaigns;


    uint256 public numberOfCampaigns = 0;
    uint256 public numberOfClosedCampaigns = 0; 

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }



    function createCampaign(address _owner, string memory _title ,string memory _name, string memory _description, uint256 _target, uint256 _deadline , string memory _image) public returns (uint256){
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp , "Deadline should be a date in future");
        campaign.id = numberOfCampaigns;
        campaign.owner = _owner;
        campaign.name = _name;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;
        
        return numberOfCampaigns-1;
    }

    function closeCampaign(uint256 _id) public {
        // Check that the campaign exists
        require(_id < numberOfCampaigns, "Campaign ID does not exist");
        
        // Retrieve the campaign from the campaigns mapping
        Campaign storage campaign = campaigns[_id];
        
        // Swap the campaign with the last element in the campaigns mapping
        Campaign storage lastCampaign = campaigns[numberOfCampaigns - 1];
        campaigns[campaign.id] = lastCampaign;
        campaigns[numberOfCampaigns - 1] = campaign;
        
        // Pop the last element off the end of the campaigns mapping
        delete campaigns[numberOfCampaigns - 1];
        numberOfCampaigns--;
        
        // Create a new closed campaign and copy the values from the active campaign
        ClosedCampaign storage closedCampaign = closedCampaigns[numberOfClosedCampaigns];
        closedCampaign.id = numberOfClosedCampaigns;
        closedCampaign.owner = campaign.owner;
        closedCampaign.name = campaign.name;
        closedCampaign.title = campaign.title;
        closedCampaign.description = campaign.description;
        closedCampaign.target = campaign.target;
        closedCampaign.deadline = campaign.deadline;
        closedCampaign.amountCollected = campaign.amountCollected;
        closedCampaign.image = campaign.image;
        closedCampaign.donators = campaign.donators;
        closedCampaign.donations = campaign.donations;
        numberOfClosedCampaigns++;
    }

    function refundDonation(uint256 _id, address _donator, uint256 _donationAmount) public payable returns (RefundMessage  memory message){
        // Check that the campaign exists
        require(_id < numberOfCampaigns, "Campaign ID does not exist");
        
        // Retrieve the campaign from the campaigns mapping
        Campaign storage campaign = campaigns[_id];
        
        // Check that the donor and donation amount are valid
        uint256 donationIndex;
        uint256 donationAmount;
        bool found = false;
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            if (campaign.donators[i] == _donator && campaign.donations[i] == _donationAmount) {
            donationIndex = i;
            donationAmount = _donationAmount;
            found = true;
            break;
            }
        }
        
        require(found, "Donor and donation amount do not match any recorded donations");
        
        // Transfer the donation amount to the refund address ie donator
        payable(_donator).transfer(donationAmount);
        
        // Update the campaign's amount collected and donations arrays
        campaign.amountCollected -= donationAmount;
        campaign.donations[donationIndex] = 0;
        
        // Remove the donor from the donators array
        for (uint256 i = donationIndex; i < campaign.donators.length - 1; i++) {
            campaign.donators[i] = campaign.donators[i + 1];
            campaign.donations[i] = campaign.donations[i + 1];
        }
        delete campaign.donators[campaign.donators.length - 1];
        delete campaign.donations[campaign.donations.length - 1];

        RefundMessage memory refundDonationMessage;

        refundDonationMessage.refundAddr = _donator;
        refundDonationMessage.refundAmount = donationAmount;
        return refundDonationMessage;
    }


    function donate(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];
        

        // payable(address(this)).transfer(amount);
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.amountCollected = campaign.amountCollected + amount;

    }

    function withdraw(address _owner ,uint256 _id) public payable{
        Campaign storage campaign = campaigns[_id];

        //check if owner
        require(_owner == campaign.owner, "You are authorized to withdraw funds");

        payable(campaign.owner).transfer(campaign.amountCollected);

        //reset amountCollect
        campaign.amountCollected = 0;        

    }


    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value : amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        } 

    }

    function getDonators(uint256 _id) public view returns (address[] memory ,uint256[] memory) {
        return (campaigns[_id].donators,campaigns[_id].donations);
    }

    function getCampaigns() public  view returns  (Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns;i++){
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;

    }

}