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

    // SubTask. f(x) = 1 if the subset sum of "array" equals to "sum"
    operation SSPOracle(register : Qubit[], target : Qubit, array : Int[], sum : Int) : Unit is Adj + Ctl {
        let n = Length(array);
        let len = 15; // !! 後で変更
        use x = Qubit[len];
        use y = Qubit[len];
        within {
            for i in 0..n - 1 {
                Controlled IncrementByInteger([register[i]], (array[i], LittleEndian(x)));
            }
            IncrementByInteger(sum, LittleEndian(y));
            ApplyToEachCA(X, y);
            for i in 0..n - 1 {
                CNOT(x[i], y[i]);
            }
        } apply {
            Controlled X(y, target);
        }
    }

    // auto generate variables, verify algorithm, and show results
    @EntryPoint()
    operation Main() : Unit {
        let n = 5;      // length of array
        let MAX = 1000;  // maximum possible value in array
        let p = 0.3;     // the probability of selected as a part of sum
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
        Message($"array: {array}");
        Message($"sum: {sum}");
        mutable found = false;
        mutable count = 0;
        repeat {
            set count = count + 1;
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
                Message($"Answer found: {result}");
            } else {
                Message($"{answer} != {sum}");
            }
        } until (found or count > 1000);
        Message($"{count}");
    }
}
