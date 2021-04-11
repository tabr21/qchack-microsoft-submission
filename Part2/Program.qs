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
        mutable result = 0;
        for i in 0..n - 1 {
            set result = result + array[i];
        }
        return result;
    }

    // SubTask. f(x) = 1 if the subset sum of "array" equals to "sum"
    operation SSPOracle(register : Qubit[], target : Qubit, array : Int[], sum : Int) : Unit is Adj + Ctl {
        let n = Length(array);
        let len = BitSizeI(Sum(array));
        use anc = Qubit[len];
        let ancLE = LittleEndian(anc);
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
        let n = 8;       // length of array
        let MAX = 100;   // maximum possible value in array
        let p = 0.5;     // the probability of selecting as a part of sum
        let q = 0.3;     // the probability of incrementation of sum
        let trials = 5;  // the number of trying searches
        mutable array = new Int[n];
        for i in 0..n - 1 {
            set array w/= i <- DrawRandomInt(0, MAX);
        }
        mutable sum = 0;
        for i in 0..n - 1 {
            if DrawRandomBool(p) {
                set sum = sum + array[i];
            }
        }
        if DrawRandomBool(q) {
            set sum = sum + 1;  // the answer may not exist! 
        }
        Message($"array: {array}");
        Message($"sum: {sum}");
        mutable flag = 0;
        mutable found = false;
        repeat {
            use register = Qubit[n];
            let iterations = Round(PI() / 4.0 * Sqrt(IntAsDouble(1 <<< n)));
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
        } until (flag <= trials or found);
        if not found {
            Message("Answer Not Found");
        }
    }
}
