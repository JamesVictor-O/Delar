// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error InvalidNumberOfPlots();

    error InvalidLandLocation();

    error InvalidTitleNumber();

    error TitleExistAlready();

    error LandIsVerifiedAlready();

    error InvalidLandIndex();

    error LandIsNotVerified();

    error LandIsAlreadyForSale();

    error LandIsNotForSale();

    error NotTheOwner();

    error LandIsNotValuedYet();

    error InsufficientDelarTokens();
}
