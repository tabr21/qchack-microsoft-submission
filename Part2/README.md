# Solving Subset sum problem (SSP) using Grover's algorithm.

Subset sum problem (SSP) is a well-known problem in informatics. 
The problem asks you that in the given array and target integer, if there is a subset whose sum is exactly equals to target. 
SSP is a NP complete problem, so if you want to solve this naively, it will take O(n * 2 ** n) time.
This time, the problem is restricted as each value in array is non negative in order to make it solvable in Q#. 
Using Grover's algorithm, this can be solved in O(n * sqrt(2 ** n)) time, which is great improve!

You can run `Program.qs` with command `dotnet run`. 
You can change some variables at Main() in `Program.qs`. 
But be careful, don't make these values too large or the program takes very long time or causes error.