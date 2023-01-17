// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// https://github.com/buttonwood-protocol/button-wrappers/blob/main/contracts/UnbuttonToken.sol

pragma solidity ^0.7.0;

import "../interfaces/IButtonWrapper.sol";

import "@orbcollective/shared-dependencies/contracts/MockMaliciousQueryReverter.sol";
import "@orbcollective/shared-dependencies/contracts/TestToken.sol";

contract MockUnbuttonERC20 is TestToken, IButtonWrapper, MockMaliciousQueryReverter {
    uint256 public constant INITIAL_DEPOSIT = 1_000;
    address internal _underlying;

    constructor(
        address underlying,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) TestToken(name, symbol, decimals) {
        _underlying = underlying;
    }

    function initialize(uint256 initialRate) public {
        uint256 mintAmount = INITIAL_DEPOSIT * initialRate;
        TestToken(_underlying).transferFrom(msg.sender, address(this), INITIAL_DEPOSIT);
        _mint(address(this), mintAmount);
    }

    function mint(uint256 amount) external override returns (uint256) {
        uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
        _deposit(msg.sender, msg.sender, uAmount, amount);
        return uAmount;
    }

    function mintFor(address to, uint256 amount) external override returns (uint256) {
        uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
        _deposit(msg.sender, to, uAmount, amount);
        return uAmount;
    }

    // function burn(uint256 amount) external override returns (uint256) {
    //     uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
    //     _withdraw(msg.sender, msg.sender, uAmount, amount);
    //     return uAmount;
    // }

    function burnTo(address to, uint256 amount) external override returns (uint256) {
        uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
        _withdraw(msg.sender, to, uAmount, amount);
        return uAmount;
    }

    function burnAll() external override returns (uint256) {
        uint256 amount = balanceOf(msg.sender);
        uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
        _withdraw(msg.sender, msg.sender, uAmount, amount);
        return uAmount;
    }

    function burnAllTo(address to) external override returns (uint256) {
        uint256 amount = balanceOf(msg.sender);
        uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
        _withdraw(msg.sender, to, uAmount, amount);
        return uAmount;
    }

    function deposit(uint256 uAmount) external override returns (uint256) {
        uint256 amount = _fromUnderlyingAmount(uAmount, _queryUnderlyingBalance(), totalSupply());
        _deposit(msg.sender, msg.sender, uAmount, amount);
        return amount;
    }

    function depositFor(address to, uint256 uAmount) external override returns (uint256) {
        uint256 amount = _fromUnderlyingAmount(uAmount, _queryUnderlyingBalance(), totalSupply());
        _deposit(msg.sender, to, uAmount, amount);
        return amount;
    }

    function withdraw(uint256 uAmount) external override returns (uint256) {
        uint256 amount = _fromUnderlyingAmount(uAmount, _queryUnderlyingBalance(), totalSupply());
        _withdraw(msg.sender, msg.sender, uAmount, amount);
        return amount;
    }

    function withdrawTo(address to, uint256 uAmount) external override returns (uint256) {
        uint256 amount = _fromUnderlyingAmount(uAmount, _queryUnderlyingBalance(), totalSupply());
        _withdraw(msg.sender, to, uAmount, amount);
        return amount;
    }

    function withdrawAll() external override returns (uint256) {
        uint256 amount = balanceOf(msg.sender);
        uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
        _withdraw(msg.sender, msg.sender, uAmount, amount);
        return amount;
    }

    function withdrawAllTo(address to) external override returns (uint256) {
        uint256 amount = balanceOf(msg.sender);
        uint256 uAmount = _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
        _withdraw(msg.sender, to, uAmount, amount);
        return amount;
    }

    function underlying() external view override returns (address) {
        return _underlying;
    }

    function totalUnderlying() external view override returns (uint256) {
        return _queryUnderlyingBalance();
    }

    function balanceOfUnderlying(address owner) external view override returns (uint256) {
        return _toUnderlyingAmount(balanceOf(owner), _queryUnderlyingBalance(), totalSupply());
    }

    function underlyingToWrapper(uint256 uAmount) external view override returns (uint256) {
        maybeRevertMaliciously();
        return _fromUnderlyingAmount(uAmount, _queryUnderlyingBalance(), totalSupply());
    }

    function wrapperToUnderlying(uint256 amount) external view override returns (uint256) {
        maybeRevertMaliciously();
        return _toUnderlyingAmount(amount, _queryUnderlyingBalance(), totalSupply());
    }

    function _deposit(address from, address to, uint256 uAmount, uint256 amount) private {
        require(amount > 0, "UnbuttonToken: too few unbutton tokens to mint");

        TestToken(_underlying).transferFrom(from, address(this), uAmount);

        _mint(to, amount);
    }

    function _withdraw(address from, address to, uint256 uAmount, uint256 amount) private {
        require(amount > 0, "UnbuttonToken: too few unbutton tokens to burn");

        _burn(from, amount);

        TestToken(_underlying).transferFrom(address(this), to, uAmount);
    }

    function _queryUnderlyingBalance() private view returns (uint256) {
        return IERC20(_underlying).balanceOf(address(this));
    }

    function _fromUnderlyingAmount(
        uint256 uAmount,
        uint256 totalUnderlying_,
        uint256 totalSupply
    ) private pure returns (uint256) {
        return (uAmount * totalSupply) / totalUnderlying_;
    }

    function _toUnderlyingAmount(
        uint256 amount,
        uint256 totalUnderlying_,
        uint256 totalSupply
    ) private pure returns (uint256) {
        return (amount * totalUnderlying_) / totalSupply;
    }
}
