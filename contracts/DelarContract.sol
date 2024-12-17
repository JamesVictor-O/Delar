// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./libs/Errors.sol";
import "./libs/Events.sol";
import "./interface/IERC20.sol";
import "./interface/INFT.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract DelarContract {
    address tokenAddress;
    address nftAddress;
    address owner;
    uint plotBasePrice = 100;

    enum ElectricityIndex { Excellent, Average, Fair }
    enum WaterIndex { Excellent, Average, Fair }
    enum ProximityToTarredRoad { Close, Average, Far }
    enum LocationIndex { Urban, Suburban, Rural }

    mapping(uint => bool) public registeredTitles;

    struct Land {
        uint numberOfPlots;
        string landLocation;
        uint titleNumber;
        uint netWorth;
        uint plotsforSale;
        bool isVerified;
        bool forSale;
    }

    mapping(address => Land[]) lands;

    // struct for available listings
    struct LandSale {
        address owner;
        uint landIndex;
    }

    LandSale[] public landsForSale;

    struct LandHistory {
        address soldFrom;
        address soldTo;
        uint amount;
        uint numberofPlots;
        uint date;
    }

    //todo: work logic to map land historical data to land index & update in code
    mapping (uint => LandHistory[]) public landHistoricalData;

    constructor(address _tokenAddress, address _nftAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
    }


    // setter functions
    function registerLand(
        uint _numberOfPlots,
        string memory _landLocation,
        uint _titleNumber
    ) external {
        if(_numberOfPlots == 0 ) {
            revert Errors.InvalidNumberOfPlots();
        }

        if(_titleNumber == 0) {
            revert Errors.InvalidTitleNumber();
        }

        // check for empty string
        if (bytes(_landLocation).length == 0) {
            revert Errors.InvalidLandLocation();
        }

        if(registeredTitles[_titleNumber]) {
            revert Errors.TitleExistAlready();
        }

        registeredTitles[_titleNumber] = true;

         
        Land memory newLand = Land({
            numberOfPlots: _numberOfPlots,
            landLocation: _landLocation,
            titleNumber: _titleNumber,
            netWorth: 0,
            plotsforSale: 0,
            forSale: false,
            isVerified: false
        });

        LandHistory memory landHistory = LandHistory({
            soldFrom: msg.sender,
            soldTo: msg.sender,
            amount: 0,
            numberofPlots: _numberOfPlots,
            date: block.timestamp
        });

        lands[msg.sender].push(newLand);

        uint landIndex = lands[msg.sender].length - 1;

        landHistoricalData[landIndex].push(landHistory);

        emit Events.LandRegistered(msg.sender, landIndex, _landLocation);
    }

    function verifyLand(address _landOwner, uint _landIndex) external {
        
        if(_landIndex > lands[_landOwner].length) {
            revert Errors.InvalidLandIndex();
        }

        if(lands[_landOwner][_landIndex].isVerified) {
            revert Errors.LandIsVerifiedAlready();
        }

        if(lands[_landOwner][_landIndex].netWorth == 0) {
            revert Errors.LandIsNotValuedYet();
        }

        uint _delarVerificationCharges = lands[_landOwner][_landIndex].numberOfPlots * 10; // delar tokens

        if(IERC20(tokenAddress).balanceOf(_landOwner) < _delarVerificationCharges) {
            revert Errors.InsufficientDelarTokens();
        }

        lands[_landOwner][_landIndex].isVerified = true;

        //todo: (shaiibu) check this logic
        INFT(nftAddress).mint(_landOwner, _landIndex, 1, '');

        IERC20(tokenAddress).transferFrom(_landOwner, address(this), _delarVerificationCharges);

        emit Events.LandVerified(_landOwner, _landIndex);
    }

    function listLand(uint _landIndex, uint _landPortion) external {

        if(_landIndex > lands[msg.sender].length) {
            revert Errors.InvalidLandIndex();
        }

        Land storage userLand = lands[msg.sender][_landIndex];

        if(!userLand.isVerified) {
            revert Errors.LandIsNotVerified();
        }

        if(userLand.forSale) {
            revert Errors.LandIsAlreadyForSale();
        }

        if(_landPortion > userLand.numberOfPlots) {
            revert Errors.InvalidNumberOfPlots();
        }

        userLand.forSale = true;
        userLand.plotsforSale = _landPortion;

        landsForSale.push(LandSale({
            owner: msg.sender,
            landIndex: _landIndex
        }));

        // todo: networth
        emit Events.LandListedForSale(msg.sender, _landIndex, userLand.netWorth, _landPortion);
    }

    function removeLandFromListing(uint _saleIndex) external {
        if(_saleIndex > landsForSale.length) {
            revert Errors.InvalidLandIndex();
        }

        if(landsForSale[_saleIndex].owner != msg.sender) {
            revert Errors.NotTheOwner();
        }

        uint landIndex = landsForSale[_saleIndex].landIndex;
        
        lands[msg.sender][landIndex].forSale = false;
        lands[msg.sender][landIndex].plotsforSale = 0;

        //todo: test to ensure it doesnt affect other owners index
        landsForSale[_saleIndex] = landsForSale[landsForSale.length - 1];

        landsForSale.pop();

        emit Events.LandDelistedForSale(msg.sender, landIndex);
    }

    function buyLand(uint _saleIndex, address _landOwner, uint _numberOfPlotsToBuy) external {
        if (_saleIndex >= landsForSale.length) {
            revert Errors.InvalidLandIndex();
        }

        uint _landIndex = landsForSale[_saleIndex].landIndex;

        Land storage sellerLand = lands[_landOwner][_landIndex];

        if (_numberOfPlotsToBuy > sellerLand.plotsforSale) {
            revert Errors.InvalidNumberOfPlots();
        }


        sellerLand.numberOfPlots -= _numberOfPlotsToBuy;
        sellerLand.plotsforSale -= _numberOfPlotsToBuy;
        sellerLand.forSale = false;
        uint _amountSold = sellerLand.netWorth * _numberOfPlotsToBuy;

         if(IERC20(tokenAddress).balanceOf(msg.sender) < _amountSold) {
            revert Errors.InsufficientDelarTokens();
         }

        Land memory buyerLand = Land({
            numberOfPlots: _numberOfPlotsToBuy,
            landLocation: sellerLand.landLocation,
            titleNumber: sellerLand.titleNumber,
            netWorth: sellerLand.netWorth,
            plotsforSale: sellerLand.plotsforSale,
            isVerified: sellerLand.isVerified,
            forSale: false
        });

        lands[msg.sender].push(buyerLand);

        // 3. If all plots are sold, transfer ownership
        if (sellerLand.numberOfPlots == 0) {
            INFT(nftAddress).safeTransferFrom(_landOwner, msg.sender, _landIndex, 1, '');

            delete lands[_landOwner][_landIndex];
            landsForSale[_saleIndex] = landsForSale[landsForSale.length - 1];
            landsForSale.pop();
        }else {
           
            INFT(nftAddress).mint(_landOwner, _landIndex, 1, '');
        }

        IERC20(tokenAddress).transferFrom(msg.sender, _landOwner, _amountSold);

        emit Events.LandSold(_landOwner, msg.sender, _amountSold);
    }

    function calculateLandNetWorth(
        address _landOwner,
        uint _landIndex, 
        ElectricityIndex _electricityIndex, 
        WaterIndex _waterIndex, 
        ProximityToTarredRoad _proximityIndex,
        LocationIndex _locationIndex) external {

        uint _totalPoints = this.getTotalPoints(_electricityIndex, _waterIndex, _proximityIndex, _locationIndex);
        uint _landValue = plotBasePrice * _totalPoints;

        lands[_landOwner][_landIndex].netWorth = _landValue;
    }

   //future
    function userRequestNetWorthValueAppreciation() external {
        // 1. when environmental changes and enhancements occurs,
        // 2. user should request so that team can valuate and appreciate propety value
    }


    // getter functions

    function viewAllListings() external view returns(LandSale[] memory) {
        return landsForSale;
    }

    function veiwOwnerLands() external view returns(Land[] memory) {
        return lands[msg.sender];
    }

    function getLandDetails (address _landOwner, uint _landIndex) external view returns (Land memory) {
        return lands[_landOwner][_landIndex];
    }
    
    function getTotalPoints(
        ElectricityIndex _electricityIndex, 
        WaterIndex _waterIndex, 
        ProximityToTarredRoad _proximityIndex,
        LocationIndex _locationIndex
        ) external pure returns(uint) {
        
        uint256 totalPoints = 0;

        // calculate electricity index
        if (_electricityIndex == ElectricityIndex.Excellent) {
            totalPoints += 2;
        } 
        if (_electricityIndex == ElectricityIndex.Average) {
            totalPoints += 1;
        } 
        if (_electricityIndex == ElectricityIndex.Fair){
            totalPoints += 0;
        }

        // calculate water index
        if (_waterIndex == WaterIndex.Excellent) {
            totalPoints += 2;
        } 
        if (_waterIndex == WaterIndex.Average) {
            totalPoints += 1;
        } 
        if (_waterIndex == WaterIndex.Fair){
            totalPoints += 0;
        }

        // calculate proximity index
        if (_proximityIndex == ProximityToTarredRoad.Close) {
            totalPoints += 2;
        } 
        if (_proximityIndex == ProximityToTarredRoad.Average) {
            totalPoints += 1;
        } 
        if (_proximityIndex == ProximityToTarredRoad.Far) {
            totalPoints += 0;
        }

        // calculate location index
        if (_locationIndex == LocationIndex.Urban) {
            totalPoints += 2;
        } 
        if (_locationIndex == LocationIndex.Suburban) {
            totalPoints += 1;
        } 
        if (_locationIndex == LocationIndex.Rural) {
            totalPoints += 0;
        }

        return totalPoints;
    }

}
