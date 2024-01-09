// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract PriceOFMATICTOUSD{
    AggregatorV3Interface priceFeed;
    // 18 decimals
    uint256 requiredPriceInUsd = 1015 * 1e15 ;
    //price is 0.1015 dollars this is make it affordable on Mumbai

    constructor() {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    }

    // returns amount of in 1e18) ;
   function getconversionRate(uint256 Amount) public view returns (uint256) {
        (,int answer,,,) = priceFeed.latestRoundData();

        // returned price is 8 decimals, convert to 18 decimal
        uint256 UsdPrice = uint256(answer * 1e10 ) ;

        // 36 decimals / 18 decimals = 18 decimals
        uint256 requiredpricenusd =   (Amount * UsdPrice) / 1e18;
        return requiredpricenusd;
    }
}

error RavDesk___FundsTransferFailed();

contract RavDesk is ReentrancyGuard, PriceOFMATICTOUSD {
    address public immutable owner;
    IERC20 public token;
    using SafeERC20 for IERC20;

    constructor() {
        owner = msg.sender; // Set the contract creator as the owner
         token = IERC20(0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747);
    }

    // struct for project details.
    struct Project {
        uint256 projectId;
        address owner;
        uint256 fundingGoal;
        uint256 currentBalance;
        uint256 currentBalanceErc20;
        uint256 createdOn;
        uint256 fundingPeriod; // Represented in seconds
        bool isFundingPaused;
        string name;
    }

    // struct for Withdrawal Request
    struct WithdrawalRequest {
        address requester;
        uint256 amount;
        bool approved;
    }

    // mapping to store withdrawal requests for each project
    mapping(uint256 => WithdrawalRequest[]) public withdrawalRequests;
    mapping(string => uint256) private projectIdsByName;
    // mapping to store project details.
    mapping(uint256 => Project) public projects;
    uint256 public projectCount;

    // Separate mapping to track funders for each project
    mapping(uint256 => mapping(address => uint256)) public projectFunders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(
            projects[_projectId].owner == msg.sender,
            "Only the project owner can call this function."
        );
        _;
    }

    // Create a new project.
    function createProject(
        uint256 _fundingGoal,
        string memory name,
        uint256 _fundingPeriod
    ) public {
        projectCount++;
        projects[projectCount] = Project(
            projectCount,
            msg.sender,
            _fundingGoal,
            0,
            0,
            block.timestamp,
            _fundingPeriod,
            false,
            name
        );
        projectIdsByName[name] = projectCount;
    }

    // Fund a project.
    function fundProject(uint256 _projectId) public payable {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "Project does not exist.");
        require(
           project.currentBalance + project.currentBalanceErc20 + getconversionRate(msg.value) <= project.fundingGoal,
            "Funding goal exceeded."
        );
         require( getconversionRate(msg.value) > 1, "You can only fund $1 upwards " );
        // Check if the funding period has ended and pause funding if it has.
        if (block.timestamp >= project.createdOn + project.fundingPeriod) {
            project.isFundingPaused = true;
        }
        require(!project.isFundingPaused, "Funding is paused for this project.");

        project.currentBalance += getconversionRate(msg.value);
        projectFunders[_projectId][msg.sender] += getconversionRate(msg.value);
        // Store the project ID by name
    }
    function fundProjectErc20(uint256 _projectId, uint _amount) external {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "Project does not exist.");
        require(
            project.currentBalance + project.currentBalanceErc20 + _amount <= project.fundingGoal,
            "Funding goal exceeded."
        );
        // Check if the funding period has ended and pause funding if it has.
        if (block.timestamp >= project.createdOn + project.fundingPeriod) {
            project.isFundingPaused = true;
        }
        require(!project.isFundingPaused, "Funding is paused for this project.");

          token.safeTransferFrom(msg.sender, address(this), _amount);
   

        project.currentBalanceErc20 += _amount;
        projectFunders[_projectId][msg.sender] += _amount;
        // Store the project ID by name
    }

    function resumeFunding(uint256 _projectId, uint256 _resumeDuration) public onlyOwner {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "Project does not exist.");
        require(project.isFundingPaused, "Funding is not paused for this project.");

        // Check if the project has been paused.
        require(
            block.timestamp >= project.createdOn + project.fundingPeriod,
            "Funding period has not ended."
        );

        // Resume funding for the specified duration.
        project.isFundingPaused = false;
        project.fundingPeriod = block.timestamp + _resumeDuration;
    }

    // Allow the project owner to request a fund withdrawal
    function requestWithdrawal(
        uint256 _projectId,
        uint256 _amount
    ) public onlyProjectOwner(_projectId) {
        require(
            _amount > 0 && _amount <= projects[_projectId].currentBalance + projects[_projectId].currentBalanceErc20,
            "Invalid withdrawal amount"
        );

        withdrawalRequests[_projectId].push(WithdrawalRequest(msg.sender, _amount, false));
    }

    // Allow the owner to approve the fund withdrawal request
    function approvePendingWithdrawal(uint256 _projectId) public onlyOwner {
        WithdrawalRequest[] storage requests = withdrawalRequests[_projectId];
        int256 oldestPendingIndex = findOldestPendingWithdrawal(requests);

        require(oldestPendingIndex != int256(-1), "No pending withdrawal requests.");

        WithdrawalRequest storage request = requests[uint256(oldestPendingIndex)];

        // Mark the withdrawal request as approved
        request.approved = true;

        // Update the current balance of the project
        projects[_projectId].currentBalance  -= request.amount;

        // Transfer the approved funds to the project owner
        (bool success, ) = payable(msg.sender).call{value: request.amount}("");
        if (!success) {
            revert RavDesk___FundsTransferFailed();
        }
    }
    function approvePendingWithdrawalERC20(uint256 _projectId) public onlyOwner {
        WithdrawalRequest[] storage requests = withdrawalRequests[_projectId];
        int256 oldestPendingIndex = findOldestPendingWithdrawal(requests);

        require(oldestPendingIndex != int256(-1), "No pending withdrawal requests.");

        WithdrawalRequest storage request = requests[uint256(oldestPendingIndex)];

        // Mark the withdrawal request as approved
        request.approved = true;

        // Update the current balance of the project
        projects[_projectId].currentBalanceErc20  -= request.amount;
     

        // Transfer the approved funds to the project owner
         if (request.approved == true ) {
              token.safeTransfer(msg.sender, request.amount);
        }
         else {
            revert RavDesk___FundsTransferFailed();
        }
    }

    // Function to find the index of the oldest pending withdrawal request
    function findOldestPendingWithdrawal(
        WithdrawalRequest[] storage requests
    ) internal view returns (int256) {
        for (uint256 i = 0; i < requests.length; i++) {
            if (!requests[i].approved) {
                return int256(i);
            }
        }
        return int256(-1); // No pending requests found
    }

    // Function to delete a project
    function deleteProject(uint256 _projectId) public onlyOwner {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "Project does not exist");

        returnFundsToOriginalFunders(_projectId);
        // Remove the project details and withdrawal requests
        delete projects[_projectId];
        delete withdrawalRequests[_projectId];
        delete projectIdsByName[project.name];
    }

    // Function to return funds to original funders based on their contribution proportion
    function returnFundsToOriginalFunders(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "Project does not exist");
        require(project.currentBalance != 0, "No balance to refund");
        // Retrieve the total amount contributed by all funders
        uint256 totalContributed = 0;
        address[] memory funderAddresses = getFunderAddresses(_projectId);

        for (uint256 i = 0; i < funderAddresses.length; i++) {
            address funder = funderAddresses[i];
            totalContributed += projectFunders[_projectId][funder];
        }

        // Iterate through the funders and refund their proportion
        for (uint256 i = 0; i < funderAddresses.length; i++) {
            address funder = funderAddresses[i];
            uint256 funderContribution = projectFunders[_projectId][funder];

            // Calculate the proportion to refund
            uint256 refundAmount = (project.currentBalance * funderContribution) / totalContributed;

            // Transfer the calculated refund amount back to the funder
            if (project.currentBalance > 0 && project.currentBalance > refundAmount) {
                (bool success, ) = payable(funder).call{value: refundAmount}("");
                
                if (success) {
                project.currentBalance -= refundAmount; // Update the project's current balance
            }  
            }
             else {
                (bool success, ) = address(token).call(abi.encodeWithSignature("transfer(address, uint256)", funder,refundAmount));

                if (success) {
                project.currentBalanceErc20 -= refundAmount; // Update the project's current balance
            }  

             }
        }
    }

    // Getter function to return an array of all project IDs
    function getAllProjectIDs() public view returns (uint256[] memory) {
        uint256[] memory projectIDs = new uint256[](projectCount);
        for (uint256 i = 1; i <= projectCount; i++) {
            projectIDs[i - 1] = i;
        }
        return projectIDs;
    }

    // Getter function to return an array of all project details
    function getAllProjects() public view returns (Project[] memory) {
        Project[] memory allProjects = new Project[](projectCount);

        for (uint256 i = 1; i <= projectCount; i++) {
            Project storage project = projects[i];
            allProjects[i - 1] = project;
        }

        return allProjects;
    }

    // Getter function to return project count
    function getProjectCount() public view returns (uint256) {
        return projectCount;
    }

    // Getter function to return project details
    function getProjectById(
        uint256 _projectId
    )
        public
        view
        returns (
            uint256 projectId,
            address projectowner,
            uint256 fundingGoal,
            uint256 currentBalance,
            uint256 currentBalanceErc20,
            uint256 createdOn,
            uint256 fundingPeriod,
            bool isFundingPaused,
            string memory name
        )
    {
        Project storage project = projects[_projectId];
        return (
            project.projectId,
            project.owner,
            project.fundingGoal,
            project.currentBalance,
            project.currentBalanceErc20,
            project.createdOn,
            project.fundingPeriod,
            project.isFundingPaused,
            project.name
        );
    }

    function getProject(
        uint256 _projectId
    )
        public
        view
        returns (
            uint256 projectId,
            address projectowner,
            uint256 fundingGoal,
            uint256 currentBalance,
            uint256 currentBalanceErc20,
            uint256 createdOn,
            uint256 fundingPeriod,
            bool isFundingPaused
        )
    {
        Project storage project = projects[_projectId];
        return (
            project.projectId,
            project.owner,
            project.fundingGoal,
            project.currentBalance,
            project.currentBalanceErc20,
            project.createdOn,
            project.fundingPeriod,
            project.isFundingPaused
        );
    }

    // Function to get the addresses of all funders for a specific project
    function getFunderAddresses(uint256 _projectId) public view returns (address[] memory) {
        address[] memory addresses = new address[](projectCount);

        for (uint256 i = 1; i <= projectCount; i++) {
            addresses[i - 1] = projects[_projectId].owner;
        }

        return addresses;
    }
}