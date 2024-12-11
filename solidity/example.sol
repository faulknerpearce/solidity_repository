// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
    // Public state variable x that stores an unsigned integer.
    uint public x;
    
    // Initializes x with a provided value.
    constructor(uint _x){
        x = _x;
    }

    // Increments the value of x by 1; callable externally.
    function increment() external {
        x ++;
    }

    // Returns the sum of x and y without modifying x.
    function add(uint _y) external view returns(uint){
        return x + _y;
    }
    
    // Returns double the value  of y; does not read from or write to the contract state.
    function double(uint _y) external pure returns(uint){
        return _y * 2;
    }

    // Returns double the values of both x and y.
    function doubleBoth(uint _x, uint _y) external pure returns(uint, uint){
        return (_x * 2, _y * 2);
    }

    // Returns the sum and average of four provided variables. 
    function sumAndAverage(uint a, uint b, uint c, uint d) external pure returns(uint, uint) {
        uint sum = a + b + c + d;
        uint average = sum / 4;

        return (sum, average);

    }
}
