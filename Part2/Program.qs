namespace Part2 {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Random;
    open Microsoft.Quantum.Diagnostics;

    // get phase-oracle from given oracle
    operation OracleConverter(oracle : (Qubit[], Qubit) => Unit is Adj + Ctl, register : Qubit[]) : Unit is Adj + Ctl {
        use target = Qubit();
        within {
            X(target);
            H(target);
        } apply {
            oracle(register, target);
        }
    }

    // template of grover's algorithm
    operation GroversSearch(register : Qubit[], oracle : ((Qubit[], Qubit) => Unit is Adj + Ctl), iterations : Int) : Unit is Adj + Ctl{
        let phaseOracle = OracleConverter(oracle, _);
        ApplyToEachCA(H, register);
        for i in 1..iterations {
            phaseOracle(register);
            within {
                ApplyToEachCA(H, register);
                ApplyToEachCA(X, register);
            } apply {
                Controlled Z(Most(register), Tail(register));
            }
        }
    }

    // calculate the sum of array
    function Sum(array : Int[]) : Int {
        let n = Length(array);
        mutable result = 1;  // to avoid result == 0
        for i in 0..n - 1 {
            set result = result + array[i];
        }
        return result;
    }

    // SubTask. f(x) = 1 if the subset sum of "array" equals to "sum"
    operation SSPOracle(register : Qubit[], target : Qubit, array : Int[], sum : Int) : Unit is Adj + Ctl {
        let n = Length(array);
        let len = BitSizeI(Sum(array)); // set len as Sum(array) < 2 ** len, to avoid overflow
        use anc = Qubit[len];
        let ancLE = LittleEndian(anc);
        // for each i, add array[i] to anc, and flip target if sum == anc
        within {
            for i in 0..n - 1 {
                Controlled IncrementByInteger([register[i]], (array[i], ancLE));
            }
        } apply {
            ControlledOnInt(sum, X)(anc, target);
        }
    }

    // auto generate variables, verify algorithm, and show results
    @EntryPoint()
    operation Main() : Unit {
        let nTestcases = 5;         // the number of test cases
        let n = 6;                  // length of array
        let maxArray = 300;         // maximum possible value in array
        let pSelection = 0.5;       // the probability of selecting as a part of sum
        let pIncrementation = 0.3;  // the probability of incrementation of sum
        let trials = 5;             // the number of trying searches
        for tc in 1..nTestcases {
            Message($"Case #{tc}:");
            // initialize array and sum using random number generator
            mutable array = new Int[n];
            for i in 0..n - 1 {
                set array w/= i <- DrawRandomInt(0, maxArray);
            }
            mutable sum = 0;
            for i in 0..n - 1 {
                if DrawRandomBool(pSelection) {
                    set sum = sum + array[i];
                }
            }
            if DrawRandomBool(pIncrementation) {
                set sum = sum + 1;  // the answer may not exist!
            }
            Message($"array: {array}");
            Message($"sum: {sum}");
            // repeat GroversSearch until answer is found or exceeded "trials" times
            mutable flag = 0;
            mutable found = false;
            repeat {
                use register = Qubit[n];
                let iterations = Round(PI() / 4.0 * Sqrt(IntAsDouble(1 <<< n)));  // O(sqrt(2 ** n)) loops
                GroversSearch(register, SSPOracle(_, _, array, sum), iterations);
                let result = ResultArrayAsBoolArray(MultiM(register));
                ResetAll(register);
                mutable answer = 0;
                for i in 0..n - 1 {
                    if result[i] {
                        set answer = answer + array[i];
                    }
                }
                if answer == sum {
                    set found = true;
                    Message($"Answer Found: {result}");
                }
                set flag = flag + 1;
            } until (flag >= trials or found);
            // when answer is not found, excute brute force to check if "quantum" algorithm is OK or not
            // the part below was used as unit test originally
            if not found {
                Message("Answer Not Found");
                // evaluate using O(n * 2 ** n) "classical" brute force algorithm
                mutable result = new Bool[0];
                for mask in 0..2 ^ n - 1 {
                    mutable temp = 0;
                    for i in 0..n - 1 {
                        if (mask &&& (1 <<< i)) != 0 {
                            set temp = temp + array[i];
                        }
                    }
                    if temp == sum {
                        set result = new Bool[n];
                        for i in 0..n - 1 {
                            if (mask &&& (1 <<< i)) != 0 {
                                set result w/= i <- true;
                            }
                        }
                    }
                }
                // this sometimes happens when maxArray and trials are small
                if Length(result) != 0 {
                    Message($"Answer Found using BruteForce: {result}");
                }
            }
        }
    }
}