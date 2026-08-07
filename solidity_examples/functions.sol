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

    // Sums up all elements in a fixed-size array and returns the result.
    function sumArray(uint[5] calldata numbers) external pure returns(uint result){
        for(uint i = 0; i < numbers.length; i ++){
            result += numbers[i];
        }

        return result;
    }

    // Stores even numbers filtered from input arrays.
    uint[] public evenNumbers;

    // Filters even numbers from a dynamic array and stores them in the state variable.
    function filterEven(uint[] calldata numbers) external {
        for(uint i = 0; i < numbers.length; i ++){

            if(numbers[i] % 2 == 0){
                evenNumbers.push(numbers[i]);
            }
        }
    }

    // Filters even numbers from a dynamic array and returns them in memory.
    function filterEvenNumbersToMemory(uint[] calldata numbers) external pure returns(uint[] memory){
        uint count = 0;

        for(uint i = 0; i < numbers.length; i ++){
            if(numbers[i] % 2 == 0){
                count += 1;
            }
        }

        uint[] memory filteredNumbers = new uint[](count);

        uint index = 0;
        
        for(uint i = 0; i < numbers.length; i ++){
            if(numbers[i] % 2 == 0){
                filteredNumbers[index] = numbers[i]; 
                index += 1; 
            }
        }

        return filteredNumbers;
    }
}
