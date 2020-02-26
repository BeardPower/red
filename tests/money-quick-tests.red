Red []

#include %../quick-test/quick-test.red

; define constants
nan: (to money! 1) / 0                              ; not a number
nannan: to money! [32768 128]                      ; a non-normal nan
zero: to money! 0                                   ; 0
zip: to money! [0 250]                              ; 0
one: to money! 1                                    ; 1
two: to money! 2                                    ; 2
three: to money! 3                                  ; 3
four: to money! 4                                   ; 4
five: to money! 5                                   ; 5
six: to money! 6                                    ; 6
seven: to money! 7                                  ; 7
eight: to money! 8                                  ; 8
nine: to money! 9                                   ; 9
ten: to money! 10                                   ; 10
minnum: to money! [1 -127]    						; the smallest possible number
epsilon: to money! [1 -6]    						; the smallest number addable to 1
negative_epsilon: to money! [-1 -6]                 ; the smallest negative number addable to 1

cent: to money! [1 -2]                              ; 0.01
half: to money! [5 -1]                              ; 0.5
almost_one: to money! [999999 -6]                   ; 0.999999
e: to money! [2718281 -6]                           ; e
pi: to money! [3141592 -6]                          ; pi

maxint: to money! [8388607 0]                       ; the largest normal integer
maxint_plus: to money! [838861 1]                   ; the smallest number larger than maxint
one_over_maxint: to money! [119 -9]                 ; one / maxint
maxnum: to money! [8388607 127]                     ; the largest possible number
googol: to money! [1 100]                           ; googol

negative_minnum: to money! [-1 -127]                ; the smallest possible negative number
negative_one: to money! [-1 0]                      ; -1
negative_nine: to money! [-9 0]                     ; -9
negative_pi: to money! [-3141592 -6]                ; -pi
negative_maxint: to money! [-8388608 0]             ; the largest negative normal integer
negative_maxnum: to money! [-8388608 127]           ; the largest possible negative number
almost_negative_one: to money! [-999999 -6]         ; -0.999999

~~~start-file~~~ "money!"

===start-group=== "to money! [coefficient exponent]"

    --test-- "nan"
            --assert "NAN" = to string! nan

    --test-- "zero"
            --assert "$0.00" = to string! zero

    --test-- "zip"
            --assert "$0.00" = to string! zip

    --test-- "one"
            --assert "$1.00" = to string! one

    --test-- "two"
            --assert "$2.00" = to string! two
            
    --test-- "three"
            --assert "$3.00" = to string! three

    --test-- "four"
            --assert "$4.00" = to string! four

    --test-- "five"
            --assert "$5.00" = to string! five

    --test-- "six"
            --assert "$6.00" = to string! six

    --test-- "seven"
            --assert "$7.00" = to string! seven

    --test-- "eight"
            --assert "$8.00" = to string! eight

    --test-- "nine"
            --assert "$9.00" = to string! nine

    --test-- "ten"
            --assert "$10.00" = to string! ten

    --test-- "minnum"
            --assert "$0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001" = to string! minnum

    --test-- "epsilon"
            --assert "$0.000001" = to string! epsilon

    --test-- "negative_epsilon"
            --assert "-$0.000001" = to string! negative_epsilon

    --test-- "cent"
            --assert "$0.01" = to string! cent

    --test-- "epsilon"
            --assert "$0.5" = to string! half

    --test-- "almost_one"
            --assert "$0.999999" = to string! almost_one

    --test-- "e"
            --assert "$2.718281" = to string! e

    --test-- "pi"
            --assert "$3.141592" = to string! pi

    --test-- "maxint"
            --assert "$8388607.00" = to string! maxint

    --test-- "maxint_plus"
            --assert "$8388610.00" = to string! maxint_plus

    ;--test-- "one_over_maxint": to money! [27755575615628914 -33]  ; one / maxint

    --test-- "maxnum"
            --assert "$83886070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.00" = to string! maxnum

    --test-- "googol"
            --assert "$10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.00" = to string! googol

    --test-- "negative_minnum"
            --assert "-$0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001" = to string! negative_minnum

    --test-- "negative_one"
            --assert "-$1.00" = to string! negative_one

    --test-- "negative_nine"
            --assert "-$9.00" = to string! negative_nine

    --test-- "negative_pi"
            --assert "-$3.141592" = to string! negative_pi

    --test-- "negative_maxint"
            --assert "-$8388608.00" = to string! negative_maxint

    --test-- "negative_maximum"
            --assert "-$83886080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.00" = to string! negative_maxnum

    --test-- "almost_negative_one"
            --assert "-$0.999999" = to string! almost_negative_one

===end-group===

===start-group=== "absolute"

    --test-- "zero"
            --assert "$0.00" = to string! absolute zero

    --test-- "zero direct"        
            --assert zero = absolute zero

    --test-- "zip"
            --assert "$0.00" = to string! absolute zip        

    --test-- "zip direct"
            --assert zip = absolute zip

    --test-- "zero alias"
            --assert "$0.00" = to string! absolute to money! [0 100]

    --test-- "zero alias direct"
            --assert zero = absolute to money! [0 100]

    --test-- "-1"
            --assert "$1.00" = to string! absolute negative_one

    --test-- "-1 direct"
            --assert one = absolute negative_one

    ;--test-- "almost_negative_one"
    ;        --assert "$0.999999" = to string! absolute almost_negative_one

    ;--test-- "almost_negative_one direct"
    ;        --assert almost_one = absolute almost_negative_one

    --test-- "-maxint"
            --assert "$8388610.00" = to string! absolute negative_maxint

    --test-- "-maxint direct"
            --assert maxint_plus = absolute negative_maxint

    ;--test-- "-maxnum direct"
    ;        --assert nan = absolute negative_maxnum

    --test-- "maxnum"
            --assert "$83886070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.00" = to string! maxnum

    --test-- "maxnum direct"
            --assert maxnum = absolute maxnum

===end-group===

===start-group=== "add"
    ;--test-- "nan + zero"
    ;--assert "NAN" = to string! nan + zero

    --test-- "nan + zero"
    --assert nan = (nan + zero)

    ; --test-- "nan + nan"
    ; --assert "NAN" = to string! nan + nan

    --test-- "nan + nan direct"
    --assert nan = (nan + nan)

    ; --test-- "nannan + 1"
    ; --assert nan = (nannan + one)

    ;test_add(nannan, one, nan, "nannan + 1");
    ;test_add(nannan, nannan, nan, "nannan + nannan");
    ;test_add(zero, nannan, nan, "0 + nannan");

    ; --test-- "zero + zip"
    ; --assert "$0.00" = to string! zero + zip

    --test-- "zero + zip"
    --assert zero = (zero + zip)

    ; --test-- "zip + zero"
    ; --assert "$0.00" = to string! zip + zero

    --test-- "zip + zero"
    --assert zero = (zip + zero)

    ; --test-- "zip + zip"
    ; --assert "$0.00" = to string! zip + zip

    --test-- "zip + zip"
    --assert zero = (zip + zip)

    ; --test-- "almost_one + epsilon"
    ; --assert "$1.00" = to string! almost_one + epsilon

    --test-- "almost_one + epsilon"
    --assert one = (almost_one + epsilon)

    ; --test-- "almost_one + nine"
    ; --assert ten = "$10.00" = to string! almost_one + nine

    --test-- "almost_one + nine"
    --assert ten = (almost_one + nine)

    ; --test-- "one + nan"
    ; --assert "NAN" = to string! one + nan

    --test-- "one + nan"
    --assert nan = (one + nan)

    ; --test-- "one + one"
    ; --assert "$2.00" = to string! one + one

    --test-- "one + one"
    --assert two = (one + one)

    ; --test-- "one + cent"
    ; --assert "$1.01" = to string! one + cent

    --test-- "one + cent"
    --assert (to money! [101 -2]) = (one + cent)

    ; --test-- "one + epsilon"
    ; --assert "$1.000001" = to string! one + epsilon

    --test-- "one + epsilon"
    --assert (to money! [1000001 -6]) = (one + epsilon)

    ; --test-- "three + four"
    ; --assert "$7.00" = to string! three + four

    --test-- "three + four"
    --assert seven = (three + four)

    ; --test-- "four + epsilon"
    ; --assert "$4.00" = to string! four + epsilon

    ; DEC64 difference!
    --test-- "four + epsilon"
    --assert (to money! [4000001 -6]) = (four + epsilon)

    ; --test-- "100 - 0.01"
    ; --assert "$99.99" = to string! (to money! [1 2]) + (to money! [-1 -2])

    --test-- "100 - 0.01"
    --assert (to money! [9999 -2]) = ((to money! [1 2]) + (to money! [-1 -2]))

    ; --test-- "10E10 + 20E10"
    ; --assert "$300000000000.00" = to string! (to money! [10 10]) + (to money! [20 10])

    --test-- "10E10 + 20E10"
    --assert (to money! [30 10]) = ((to money! [10 10]) + (to money! [20 10]))

    ; --test-- "1.99 + 2.99"
    ; --assert "$4.98" = to string! (to money! [199 -2]) + (to money! [299 -2])

    --test-- "1.99 + 2.99"
    --assert (to money! [498 -2]) = ((to money! [199 -2]) + (to money! [299 -2]))

    ; --test-- "test overflow with big exponents"
    ; --assert "$16777214" = to string! (to money! [8388607 126]) + (to money! [8388607 126])

    --test-- "test overflow with big exponents"
    --assert (to money! [1677721 127]) = ((to money! [8388607 126]) + (to money! [8388607 126]))

    ; --test-- "999999 + 1"
    ; --assert "$1000000.00" = to string! (to money! [999999 0]) + one

    --test-- "999999 + 1"
    --assert (to money! [1000000 0]) = ((to money! [999999 0]) + one)

    ; --test-- "-1 + epsilon"
    ;--assert "-$0.999999" = to string! negative_one + epsilon

    --test-- "-1 + epsilon"
    --assert almost_negative_one = (negative_one + epsilon)

    ; --test-- "-pi + pi"
    ; --assert "$0.00" = to string! negative_pi + pi

    --test-- "-pi + pi"
    --assert zero = (negative_pi + pi)

    ; --test-- "maxint + one"
    ; --assert "$8388610.00" = to string! maxint + one

    --test-- "maxint + one"
    --assert maxint_plus = (maxint + one)

    ; --test-- "maxint + half"
    ; --assert "$8388610.00" = to string! maxint + half

    --test-- "maxint + half"
    --assert maxint_plus = (maxint + half)

    ; --test-- "maxint + cent"
    ; --assert "$8388607.00" = to string! maxint + cent

    --test-- "maxint + cent"
    --assert maxint = (maxint + cent)

    ; --test-- "maxint + 0.499999"
    ; --assert "$8388607.00" = to string! maxint + 0.499999

    --test-- "maxint + 0.499999"
    --assert maxint = (maxint + 0.499999)

    ; --test-- "maxint + maxint"
    ; --assert "$16777210.00" = to string! maxint + maxint

    --test-- "maxint + maxint"
    --assert (to money! [1677721 1]) = (maxint + maxint)

    ; --test-- "maxint + 1.11"
    ; --assert "$8388610.00" = to string! maxint + to money! [111 -2]

    --test-- "maxint + 1.11"
    --assert maxint_plus = (maxint + to money! [111 -2])

    --test-- "maxint + something too small"
    --assert maxint = ((to money! [36028797018963967 -20]) + maxint)

    --test-- "maxint + 3"
    --assert maxint_plus = ((to money! [3000000 -6]) + maxint)
 
    --test-- "maxint + something too small"
    --assert maxint = ((to money! [2000000 -6]) + maxint)

    --test-- "maxint + -maxint"
    --assert (to money! [-1 0]) = (maxint + negative_maxint)    

    --test-- "insignificance"
    --assert maxnum = ((to money! [1 -127]) + maxnum)

    --test-- "insignificance"
    --assert maxnum = (one + maxnum)

    --test-- "insignificance"
    --assert maxnum = (maxnum + maxint)

    --test-- "overflow the exponent"
    --assert nan = (maxnum + to money! [1 127])

    --test-- "overflow the exponent alias_1"
    --assert nan = (maxnum + to money! [10 126])

    --test-- "overflow the exponent alias_2"
    --assert nan = (maxnum + to money! [100 125])

    --test-- "overflow the exponent alias_3"
    --assert nan = (maxnum + to money! [1000 124])

    --test-- "overflow the exponent alias_4"
    --assert nan = (maxnum + to money! [500 124])

    --test-- "overflow the exponent alias_5"
    --assert nan = (maxnum + maxnum)

    --test-- "extreme zero"
    --assert zero = (maxnum + to money! [-8388607 127])

    --test-- "almost_negative_one + one"
    --assert epsilon = (almost_negative_one + one)

    --test-- "almost_negative_one + almost_one"
    --assert zero = (almost_negative_one + almost_one)

    --test-- "0.1 + 0.001"
    --assert (to money! [101 -3]) = ((to money! [1 -1]) + to money! [1 -3])

    ; TODO divide by zero
    --test-- "0.1 + 1e-6"
    --assert (to money! [1000001 -7]) = ((to money! [1 -1]) + to money! [1 -7])

    --test-- "718281e-6 + 1"
    --assert (to money! [1718281 -6]) = ((to money! [718281 -6]) + one)

    --test-- "718281e-6 + 10e-1"
    --assert (to money! [1718281 -6]) = ((to money! [718281 -6]) + to money! [10 -1])

    --test-- "400000e-6 + 10e-1"
    --assert (to money! [1400000 -6]) = ((to money! [400000 -6]) + to money! [10 -1])

    --test-- "0.1 + 0.2"
    --assert (to money! [3 -1]) = ((to money! [1 -1]) + to money! [2 -1])

===end-group===

===start-group=== "divide"

    ; --test-- "41958 / 31457"
    ; --assert "$1.3338" = to string! (to money! [41958 0]) / (to money! [31457 0]) 

    --test-- "41958 / 31457"
    --assert (to money! [13338 -4]) = ((to money! [41958 0]) / (to money! [31457 0]))

    ; --test-- "nan / nan"
    ; --assert "NAN" = to string! nan / nan

    --test-- "nan / nan"
    --assert nan = (nan / nan)

    ; --test-- "nan / 3"
    ; --assert "NAN" = to string! nan / three

    --test-- "nan / 3"
    --assert nan = (nan / three)
   
    ; test_divide(nannan, nannan, nan, "nannan / nannan");
    ; test_divide(nannan, one, nan, "nannan / 1");

    ; --test-- "0 / nan"
    ; --assert "$0.00" = to string! zero / nan

    --test-- "0 / nan"
    --assert zero = (zero / nan)
    ; test_divide(zero, nannan, zero, "0 / nannan");

    ; --test-- "zero / zip"
    ; --assert "$0.00" = to string! zero / zip

    --test-- "zero / zip"
    --assert zero = (zero / zip)

    ; --test-- "zip / nan"
    ; --assert "$0.00" = to string! zip / nan

    --test-- "zip / nan"
    --assert zero = (zip / nan)

    ; test_divide(zip, nannan, zero, "zip / nannan");

    ; --test-- "zip / zero"
    ; --assert "$0.00" = to string! zip / zero

    --test-- "zip / zero"
    --assert zero = (zip / zero)

    ; --test-- "zip / zip"
    ; --assert "$0.00" = to string! zip / zip

    --test-- "zip / zip"
    --assert zero = (zip / zip)
    
    ; --test-- "0 / 1"
    ; --assert "$0.00" = to string! zero / one

    --test-- "0 / 1"
    --assert zero = (zero / one)

    ; --test-- "0 / 0 direct"
    ; --assert "$0.00" = to string! zero / zero

    --test-- "0 / 0"
    --assert zero = (zero / zero)

    ; --test-- "1 / 0 direct"
    ; --assert "NAN" = to string! one / zero

    --test-- "1 / 0"
    --assert nan = (one / zero)

    ; --test-- "1 / -1"
    ; --assert "-$1.00" = to string! one / negative_one

    --test-- "1 / -1"
    --assert (to money! [-10000000 -6]) = (one / negative_one)

    ; --test-- "-1 / 1"
    ; --assert "-$1.00" = to string! negative_one / one

    --test-- "-1 / 1"
    --assert (to money! [-10000000 -6]) = (negative_one / one)

    ; --test-- "1 / 2"
    ; --assert "$0.50" = to string! one / two

    --test-- "1 / 2"
    --assert (to money! [500000 -6]) = (one / two)

    ; --test-- "1 / 3"
    ; --assert "$0.3333333" = to string! one / three

    --test-- "1 / 3"
    --assert (to money! [3333333 -7]) = (one / three)

    ; --test-- "2 / 3"
    ; --assert "$0.6666667" = to string! two / three

    --test-- "2 / 3"
    --assert (to money! [6666667 -7]) = (two / three)

    ; --test-- "2 / 3 alias"
    ; --assert "$0.6666667" = to string! two / to money! [3000000 -6]

    --test-- "2 / 3 alias"
    --assert (to money! [66 -2]) = (two / to money! [3000000 -6])

    ; --test-- "2 / 3 alias_2"
    ; --assert "$0.6666667" = to string! (to money! [2000000 -6]) / three

    --test-- "2 / 3 alias_2"
    --assert (to money! [6666667 -7]) = ((to money! [2000000 -6]) / three)

    ; --test-- "5 / 3 "
    ; --assert "$166667" = to string! five / three

    --test-- "5 / 3"
    --assert (to money! [1666667 -6]) = (five / three)

    --test-- "5 / -3"
    --assert (to money! [-166 -2]) = (five / to money! [-3000000 -6])

    --test-- "-5 / 3"
    --assert (to money! [-1666667 -6]) = ((to money! [-5000000 -6]) / three)

    --test-- "-5 / -3"
    --assert (to money! [166 -2]) = ((to money! [-5000000 -6]) / to money! [-3000000 -6])

    --test-- "6 / nan"
    --assert (nan) = (six / nan)

    --test-- "6 / 3"
    --assert (to money! [2000000 -6]) = (six / three)

    --test-- "0 / 9"
    --assert zero = (zero / nine)

    --test-- "1 / 9"
    --assert (to money! [1111111 -7]) = (one / nine)

    --test-- "2 / 9"
    --assert (to money! [2222222 -7]) = (two / nine)

    --test-- "3 / 9"
    --assert (to money! [3333333 -7]) = (three / nine)

    --test-- "4 / 9"
    --assert (to money! [4444444 -7]) = (four / nine)

    --test-- "5 / 9"
    --assert (to money! [5555556 -7]) = (five / nine)

    --test-- "6 / 9"
    --assert (to money! [6666667 -7]) = (six / nine)

    --test-- "7 / 9"
    --assert (to money! [7777778 -7]) = (seven / nine)

    --test-- "8 / 9"
    --assert (to money! [888889 -6]) = (eight / nine)

    --test-- "9 / 9"
    --assert one = (nine / nine)

    --test-- "0 / -9"
    --assert zero = (zero / negative_nine)

    --test-- "1 / -9"
    --assert (to money! [-1111111 -7]) = (one / negative_nine)
    
    --test-- "2 / -9"
    --assert (to money! [-2222222 -7]) = (two / negative_nine)

    --test-- "3 / -9"
    --assert (to money! [-3333333 -7]) = (three / negative_nine)

    --test-- "4 / -9"
    --assert (to money! [-4444444 -7]) = (four / negative_nine)

    --test-- "5 / -9"
    --assert (to money! [-5555556 -7]) = (five / negative_nine)

    --test-- "6 / -9"
    --assert (to money! [-6666667 -7]) = (six / negative_nine)

    --test-- "7 / -9"
    --assert (to money! [-7777778 -7]) = (seven / negative_nine)

    --test-- "8 / -9"
    --assert (to money! [-888889 -6]) = (eight / negative_nine)

    --test-- "9 / -9"
    --assert (negative_one) = (nine / negative_nine)

    --test-- "pi / -pi"
    --assert (to money! [-1000000 -6]) = (pi / negative_pi)

    --test-- "-pi / pi"
    --assert (to money! [-1000000 -6]) = (negative_pi / pi)

    --test-- "-pi / -pi"
    --assert (to money! [1000000 -6]) = (negative_pi / negative_pi)

    --test-- "-16 / 10"
    --assert (to money! [-16 -1]) = ((to money! [-16 0]) / ten)

    --test-- "maxint / epsilon"
    --assert (to money! [8388607 6]) = (maxint / epsilon)

    --test-- "one / maxint"
    --assert one_over_maxint = (one / maxint)

    --test-- "one / one / maxint"
    --assert maxint = (one / one_over_maxint)

    --test-- "one / -maxint"
    --assert (to money! [-119 -9]) = (one / negative_maxint)

    --test-- "maxnum / epsilon"
    --assert nan = (maxnum / epsilon)

    --test-- "maxnum / maxnum"
    --assert (to money! [1000000 -6]) = (maxnum / maxnum)

    --test-- "one / maxint alias 1"
    --assert one_over_maxint = ((to money! [10 -1]) / maxint)
    
    --test-- "one / maxint alias 2"
    --assert one_over_maxint = ((to money! [100 -2]) / maxint)

    --test-- "one / maxint alias 3"
    --assert one_over_maxint = ((to money! [1000 -3]) / maxint)

    --test-- "one / maxint alias 4"
    --assert one_over_maxint = ((to money! [10000 -4]) / maxint)

    --test-- "one / maxint alias 5"
    --assert one_over_maxint = ((to money! [100000 -5]) / maxint)

    --test-- "one / maxint alias 6"
    --assert one_over_maxint = ((to money! [1000000 -6]) / maxint)

    --test-- "one / maxint alias 7"
    --assert nan = ((to money! [10000000 -7]) / maxint)

    --test-- "one / maxint alias 8"
    --assert nan = ((to money! [100000000 -8]) / maxint)

    --test-- "one / maxint alias 9"
    --assert nan = ((to money! [1000000000 -9]) / maxint)

    --test-- "one / maxint alias 10"
    --assert nan = ((to money! [10000000000 -10]) / maxint)

    --test-- "one / maxint alias 11"
    --assert nan = ((to money! [100000000000 -11]) / maxint)

    --test-- "one / maxint alias 12"
    --assert nan = ((to money! [1000000000000 -12]) / maxint)

    --test-- "one / maxint alias 13"
    --assert nan = ((to money! [10000000000000 -13]) / maxint)

    --test-- "one / maxint alias 14"
    --assert nan = ((to money! [100000000000000 -14]) / maxint)

    --test-- "one / maxint alias 15"
    --assert nan = ((to money! [1000000000000000 -15]) / maxint)

    --test-- "one / maxint alias 16"
    --assert nan = ((to money! [10000000000000000 -16]) / maxint)

    --test-- "minnum / 2"
    --assert minnum = (minnum / two)

    ; test_divide(one, 0x1437EEECD800000LL, dec64_new(28114572543455208, -31), "1/17!");
    ; test_divide(one, 0x52D09F700003LL, dec64_new(28114572543455208, -31), "1/17!");

===end-group===

===start-group=== "equal short"

    --test-- "nan = nan"
    --assert true = (nan = nan)

    --test-- "nan = zero"
    --assert false = (nan = zero)
    
    ; test_equal(nan, nannan, false, "nan = nannan");
    ; test_equal(nannan, nannan, true, "nannan = nannan");
    ; test_equal(nannan, nan, false, "nannan = nan");
    ; test_equal(nannan, one, false, "nannan = 1");
    
    --test-- "zero = nan"
    --assert false = (zero = nan)

    ; test_equal(zero, nannan, false, "0 = nannan");

    --test-- "zero = zip"
    --assert true = (zero = zip)

    --test-- "zero = minnum"
    --assert false = (zero = minnum)

    --test-- "zero = one"
    --assert false = (zero = one)

    --test-- "zero = zero"
    --assert true = (zero = zero)

    --test-- "zip = zip"
    --assert true = (zip = zip)

    --test-- "zip = zip"
    --assert true = (zip = zip)

    --test-- "1 = -1"
    --assert false = (1 = -1)

    --test-- "2 = 2"
    --assert true = (2 = 2)

    --test-- "2 = 2e-6"
    --assert false = ((to money! [2 -6]) = 2)

    --test-- "pi = 3"
    --assert false = (pi = 3)

    --test-- "maxint = maxnum"
    --assert false = (maxint = maxnum)

    --test-- "-maxint = maxint"
    --assert false = (negative_maxint = maxint)

    --test-- "-maxint = -1"
    --assert false = (negative_maxint = negative_one)

    --test-- "-maxint = -1"
    --assert false = (negative_maxint = negative_one)

    ; test_equal(0x1437EEECD800000LL, 0x52D09F700003LL, true, "17!");

===end-group===

===start-group=== "less"

    --test-- "nan < nan"
    --assert false = (nan < nan)

    ; test_less(nan, nan, nan, "nan < nan");
    ; test_less(nan, nannan, nan, "nan < nannan");
    ; test_less(nan, zero, nan, "nan < zero");
    ; test_less(nannan, nan, nan, "nannan < nan");
    ; test_less(nannan, nannan, nan, "nannan < nannan");
    ; test_less(nannan, one, nan, "nannan < 1");
    
    --test-- "zero < nan"
    --assert false = (zero < nan)

    ; test_less(zero, nannan, nan, "0 < nannan");

    --test-- "zero < zip"
    --assert false = (zero < zip)
    
    --test-- "zero < minnum"
    --assert true = (zero < minnum)

    --test-- "zero < one"
    --assert true = (zero < one)

    --test-- "zip < zero"
    --assert false = (zip < zero)

    --test-- "zip < zip"
    --assert false = (zip < zip)

    --test-- "1 < -1"
    --assert false = (one < negative_one)

    --test-- "-9 < 9"
    --assert true = (negative_nine < nine)

    --test-- "2 < 2"
    --assert false = (two < two)

    --test-- "2 < 2e-6"
    --assert false = (two < to money! [2 -6])

    --test-- "3 < pi"
    --assert true = (three < pi)

    --test-- "4 < pi"
    --assert false = (four < pi)

    --test-- "pi < 3"
    --assert false = (pi < three)

    --test-- "maxint < maxnum"
    --assert true = (maxint < maxnum)

    --test-- "maxnum < maxint"
    --assert false = (maxnum < maxint)

    --test-- "-maxint < maxint"
    --assert true = (negative_maxint < maxint)

    --test-- "-maxint < -1"
    --assert true = (negative_maxint < negative_one)

    --test-- "maxnum < nan"
    --assert false = (maxnum < nan)

    --test-- "9 < 10"
    --assert true = (nine < ten)

    --test-- "-9 < -1E1"
    --assert false = (negative_nine < to money! [-1 1])

    --test-- "-0.9... < -1"
    --assert false = (almost_negative_one < negative_one)

    --test-- "0.9... < 1"
    --assert true = (almost_one < one)

    --test-- "epsilon < minnum"
    --assert false = (epsilon < minnum)

    --test-- "e < 2"
    --assert false = (e < two)

    --test-- "e < 3"
    --assert true = (e < three)

    --test-- "e < pi"
    --assert true = (e < pi)

    --test-- "cent < half"
    --assert true = (cent < half)

    --test-- "1/maxint < 0"
    --assert false = (one_over_maxint < zero)

    --test-- "1/maxint < minnum"
    --assert false = (one_over_maxint < minnum)

    --test-- "googol < maxint"
    --assert false = (googol < maxint)

    --test-- "googol < maxnum"
    --assert true = (googol < maxnum)

    --test-- "maxint < maxint+1"
    --assert true = (maxint < maxint_plus)

===end-group===

===start-group=== "less or equal"

    --test-- "nan <= nan"
    --assert true = (nan <= nan)

    ; test_less(nan, nan, nan, "nan < nan");
    ; test_less(nan, nannan, nan, "nan < nannan");
    ; test_less(nan, zero, nan, "nan < zero");
    ; test_less(nannan, nan, nan, "nannan < nan");
    ; test_less(nannan, nannan, nan, "nannan < nannan");
    ; test_less(nannan, one, nan, "nannan < 1");

    --test-- "zero <= nan"
    --assert false = (zero <= nan)

    ; test_less(zero, nannan, nan, "0 < nannan");

    --test-- "zero <= zip"
    --assert true = (zero <= zip)
    
    --test-- "zero <= minnum"
    --assert true = (zero <= minnum)

    --test-- "zero <= one"
    --assert true = (zero <= one)

    --test-- "zip <= zero"
    --assert true = (zip <= zero)

    --test-- "zip <= zip"
    --assert true = (zip <= zip)

    --test-- "1 <= -1"
    --assert false = (one <= negative_one)

    --test-- "-9 <= 9"
    --assert true = (negative_nine <= nine)

    --test-- "2 <= 2"
    --assert true = (two <= two)

    --test-- "2 <= 2e-6"
    --assert false = (two <= to money! [2 -6])

    --test-- "3 <= pi"
    --assert true = (three <= pi)

    --test-- "4 <= pi"
    --assert false = (four <= pi)

    --test-- "pi <= 3"
    --assert false = (pi <= three)

    --test-- "maxint <= maxnum"
    --assert true = (maxint <= maxnum)

    --test-- "maxnum <= maxint"
    --assert false = (maxnum <= maxint)

    --test-- "-maxint <= maxint"
    --assert true = (negative_maxint <= maxint)

    --test-- "-maxint <= -1"
    --assert true = (negative_maxint <= negative_one)

    --test-- "maxnum <= nan"
    --assert false = (maxnum <= nan)

    --test-- "9 <= 10"
    --assert true = (nine <= ten)

    --test-- "-9 <= -1E1"
    --assert false = (negative_nine <= to money! [-1 1])

    --test-- "-0.9... <= -1"
    --assert false = (almost_negative_one <= negative_one)

    --test-- "0.9... <= 1"
    --assert true = (almost_one <= one)

    --test-- "epsilon <= minnum"
    --assert false = (epsilon <= minnum)

    --test-- "e <= 2"
    --assert false = (e <= two)

    --test-- "e <= 3"
    --assert true = (e <= three)

    --test-- "e <= pi"
    --assert true = (e <= pi)

    --test-- "cent <= half"
    --assert true = (cent <= half)

    --test-- "1/maxint <= 0"
    --assert false = (one_over_maxint <= zero)

    --test-- "1/maxint <= minnum"
    --assert false = (one_over_maxint <= minnum)

    --test-- "googol <= maxint"
    --assert false = (googol <= maxint)

    --test-- "googol <= maxnum"
    --assert true = (googol <= maxnum)

    --test-- "maxint <= maxint+1"
    --assert true = (maxint <= maxint_plus)

===end-group===

===start-group=== "equal"

    --test-- "nan = nan"
    --assert true = (nan = nan)

    ; test_less(nan, nan, nan, "nan < nan");
    ; test_less(nan, nannan, nan, "nan < nannan");
    ; test_less(nan, zero, nan, "nan < zero");
    ; test_less(nannan, nan, nan, "nannan < nan");
    ; test_less(nannan, nannan, nan, "nannan < nannan");
    ; test_less(nannan, one, nan, "nannan < 1");

    --test-- "zero = nan"
    --assert false = (zero = nan)
    
    ; test_less(zero, nannan, nan, "0 < nannan");

    --test-- "zero = zip"
    --assert true = (zero = zip)
    
    --test-- "zero = minnum"
    --assert false = (zero = minnum)

    --test-- "zero = one"
    --assert false = (zero = one)

    --test-- "zip = zero"
    --assert true = (zip = zero)

    --test-- "zip = zip"
    --assert true = (zip = zip)

    --test-- "1 = -1"
    --assert false = (one = negative_one)

    --test-- "-9 = 9"
    --assert false = (negative_nine = nine)

    --test-- "2 = 2"
    --assert true = (two = two)

    --test-- "2 = 2e-6"
    --assert false = (two = to money! [2 -6])

    --test-- "3 = pi"
    --assert false = (three = pi)

    --test-- "4 = pi"
    --assert false = (four = pi)

    --test-- "pi = 3"
    --assert false = (pi = three)

    --test-- "maxint = maxnum"
    --assert false = (maxint = maxnum)

    --test-- "maxnum = maxint"
    --assert false = (maxnum = maxint)

    --test-- "-maxint = maxint"
    --assert false = (negative_maxint = maxint)

    --test-- "-maxint = -1"
    --assert false = (negative_maxint = negative_one)

    --test-- "maxnum = nan"
    --assert false = (maxnum = nan)

    --test-- "9 = 10"
    --assert false = (nine = ten)

    --test-- "-9 = -1E1"
    --assert false = (negative_nine = to money! [-1 1])

    --test-- "-0.9... = -1"
    --assert false = (almost_negative_one = negative_one)

    --test-- "0.9... = 1"
    --assert false = (almost_one = one)

    --test-- "epsilon = minnum"
    --assert false = (epsilon = minnum)

    --test-- "e = 2"
    --assert false = (e = two)

    --test-- "e = 3"
    --assert false = (e = three)

    --test-- "e = pi"
    --assert false = (e = pi)

    --test-- "cent = half"
    --assert false = (cent = half)

    --test-- "1/maxint = 0"
    --assert false = (one_over_maxint = zero)

    --test-- "1/maxint = minnum"
    --assert false = (one_over_maxint = minnum)

    --test-- "googol = maxint"
    --assert false = (googol = maxint)

    --test-- "googol = maxnum"
    --assert false = (googol = maxnum)

    --test-- "maxint = maxint+1"
    --assert false = (maxint = maxint_plus)

===end-group===

===start-group=== "not equal"

    --test-- "nan <> nan"
    --assert false = (nan <> nan)

    ; test_less(nan, nan, nan, "nan < nan");
    ; test_less(nan, nannan, nan, "nan < nannan");
    ; test_less(nan, zero, nan, "nan < zero");
    ; test_less(nannan, nan, nan, "nannan < nan");
    ; test_less(nannan, nannan, nan, "nannan < nannan");
    ; test_less(nannan, one, nan, "nannan < 1");
    
    --test-- "zero <> nan"
    --assert true = (zero <> nan)

    ; test_less(zero, nannan, nan, "0 < nannan");

    --test-- "zero <> zip"
    --assert false = (zero <> zip)
    
    --test-- "zero <> minnum"
    --assert true = (zero <> minnum)

    --test-- "zero <> one"
    --assert true = (zero <> one)

    --test-- "zip <> zero"
    --assert false = (zip <> zero)

    --test-- "zip <> zip"
    --assert false = (zip <> zip)

    --test-- "1 <> -1"
    --assert true = (one <> negative_one)

    --test-- "-9 <> 9"
    --assert true = (negative_nine <> nine)

    --test-- "2 <> 2"
    --assert false = (two <> two)

    --test-- "2 <> 2e-6"
    --assert true = (two <> to money! [2 -6])

    --test-- "3 <> pi"
    --assert true = (three <> pi)

    --test-- "4 <> pi"
    --assert true = (four <> pi)

    --test-- "pi <> 3"
    --assert true = (pi <> three)

    --test-- "maxint <> maxnum"
    --assert true = (maxint <> maxnum)

    --test-- "maxnum <> maxint"
    --assert true = (maxnum <> maxint)

    --test-- "-maxint <> maxint"
    --assert true = (negative_maxint <> maxint)

    --test-- "-maxint <> -1"
    --assert true = (negative_maxint <> negative_one)

    --test-- "maxnum <> nan"
    --assert true = (maxnum <> nan)

    --test-- "9 <> 10"
    --assert true = (nine <> ten)

    --test-- "-9 <> -1E1"
    --assert true = (negative_nine <> to money! [-1 1])

    --test-- "-0.9... <> -1"
    --assert true = (almost_negative_one <> negative_one)

    --test-- "0.9... <> 1"
    --assert true = (almost_one <> one)

    --test-- "epsilon <> minnum"
    --assert true = (epsilon <> minnum)

    --test-- "e <> 2"
    --assert true = (e <> two)

    --test-- "e <> 3"
    --assert true = (e <> three)

    --test-- "e <> pi"
    --assert true = (e <> pi)

    --test-- "cent <> half"
    --assert true = (cent <> half)

    --test-- "1/maxint <> 0"
    --assert true = (one_over_maxint <> zero)

    --test-- "1/maxint <> minnum"
    --assert true = (one_over_maxint <> minnum)

    --test-- "googol <> maxint"
    --assert true = (googol <> maxint)

    --test-- "googol <> maxnum"
    --assert true = (googol <> maxnum)

    --test-- "maxint <> maxint+1"
    --assert true = (maxint <> maxint_plus)

===end-group===

===start-group=== "greater"

    --test-- "nan > nan"
    --assert false = (nan > nan)

    ; test_less(nan, nan, nan, "nan < nan");
    ; test_less(nan, nannan, nan, "nan < nannan");
    ; test_less(nan, zero, nan, "nan < zero");
    ; test_less(nannan, nan, nan, "nannan < nan");
    ; test_less(nannan, nannan, nan, "nannan < nannan");
    ; test_less(nannan, one, nan, "nannan < 1");

    --test-- "zero > nan"
    --assert false = (zero > nan)

    ; test_less(zero, nannan, nan, "0 < nannan");

    --test-- "zero > zip"
    --assert false = (zero > zip)
    
    --test-- "zero > minnum"
    --assert false = (zero > minnum)

    --test-- "zero > one"
    --assert false = (zero > one)

    --test-- "zip > zero"
    --assert false = (zip > zero)

    --test-- "zip > zip"
    --assert false = (zip > zip)

    --test-- "1 > -1"
    --assert true = (one > negative_one)

    --test-- "-9 > 9"
    --assert false = (negative_nine > nine)

    --test-- "2 > 2"
    --assert false = (two > two)

    --test-- "2 > 2e-6"
    --assert true = (two > to money! [2 -6])

    --test-- "3 > pi"
    --assert false = (three > pi)

    --test-- "4 > pi"
    --assert true = (four > pi)

    --test-- "pi > 3"
    --assert true = (pi > three)

    --test-- "maxint > maxnum"
    --assert false = (maxint > maxnum)

    --test-- "maxnum > maxint"
    --assert true = (maxnum > maxint)

    --test-- "-maxint > maxint"
    --assert false = (negative_maxint > maxint)

    --test-- "-maxint > -1"
    --assert false = (negative_maxint > negative_one)

    --test-- "maxnum > nan"
    --assert false = (maxnum > nan)

    --test-- "9 > 10"
    --assert false = (nine > ten)

    --test-- "-9 > -1E1"
    --assert true = (negative_nine > to money! [-1 1])

    --test-- "-0.9... > -1"
    --assert true = (almost_negative_one > negative_one)

    --test-- "0.9... > 1"
    --assert false = (almost_one > one)

    --test-- "epsilon > minnum"
    --assert true = (epsilon > minnum)

    --test-- "e > 2"
    --assert true = (e > two)

    --test-- "e > 3"
    --assert false = (e > three)

    --test-- "e > pi"
    --assert false = (e > pi)

    --test-- "cent > half"
    --assert false = (cent > half)

    --test-- "1/maxint > 0"
    --assert true = (one_over_maxint > zero)

    --test-- "1/maxint > minnum"
    --assert true = (one_over_maxint > minnum)

    --test-- "googol > maxint"
    --assert true = (googol > maxint)

    --test-- "googol > maxnum"
    --assert false = (googol > maxnum)

    --test-- "maxint > maxint+1"
    --assert false = (maxint > maxint_plus)

===end-group===

===start-group=== "greater or equal"

    --test-- "nan >= nan"
    --assert true = (nan >= nan)

    ; test_less(nan, nan, nan, "nan < nan");
    ; test_less(nan, nannan, nan, "nan < nannan");
    ; test_less(nan, zero, nan, "nan < zero");
    ; test_less(nannan, nan, nan, "nannan < nan");
    ; test_less(nannan, nannan, nan, "nannan < nannan");
    ; test_less(nannan, one, nan, "nannan < 1");

    --test-- "zero >= nan"
    --assert false = (zero >= nan)

    ; test_less(zero, nannan, nan, "0 < nannan");

    --test-- "zero >= zip"
    --assert true = (zero >= zip)
    
    --test-- "zero >= minnum"
    --assert false = (zero >= minnum)

    --test-- "zero >= one"
    --assert false = (zero >= one)

    --test-- "zip >= zero"
    --assert true = (zip >= zero)

    --test-- "zip >= zip"
    --assert true = (zip >= zip)

    --test-- "1 >= -1"
    --assert true = (one >= negative_one)

    --test-- "-9 >= 9"
    --assert false = (negative_nine >= nine)

    --test-- "2 >= 2"
    --assert true = (two >= two)

    --test-- "2 >= 2e-6"
    --assert true = (two >= to money! [2 -6])

    --test-- "3 >= pi"
    --assert false = (three >= pi)

    --test-- "4 >= pi"
    --assert true = (four >= pi)

    --test-- "pi >= 3"
    --assert true = (pi >= three)

    --test-- "maxint >= maxnum"
    --assert false = (maxint >= maxnum)

    --test-- "maxnum >= maxint"
    --assert true = (maxnum >= maxint)

    --test-- "-maxint >= maxint"
    --assert false = (negative_maxint >= maxint)

    --test-- "-maxint >= -1"
    --assert false = (negative_maxint >= negative_one)

    --test-- "maxnum >= nan"
    --assert false = (maxnum >= nan)

    --test-- "9 >= 10"
    --assert false = (nine >= ten)

    --test-- "-9 >= -1E1"
    --assert true = (negative_nine >= to money! [-1 1])

    --test-- "-0.9... >= -1"
    --assert true = (almost_negative_one >= negative_one)

    --test-- "0.9... >= 1"
    --assert false = (almost_one >= one)

    --test-- "epsilon >= minnum"
    --assert true = (epsilon >= minnum)

    --test-- "e >= 2"
    --assert true = (e >= two)

    --test-- "e >= 3"
    --assert false = (e >= three)

    --test-- "e >= pi"
    --assert false = (e >= pi)

    --test-- "cent >= half"
    --assert false = (cent >= half)

    --test-- "1/maxint >= 0"
    --assert true = (one_over_maxint >= zero)

    --test-- "1/maxint >= minnum"
    --assert true = (one_over_maxint >= minnum)

    --test-- "googol >= maxint"
    --assert true = (googol >= maxint)

    --test-- "googol >= maxnum"
    --assert false = (googol >= maxnum)

    --test-- "maxint >= maxint+1"
    --assert false = (maxint >= maxint_plus)

===end-group===

===start-group=== "multiply"

    --test-- "nan * nan"
    --assert nan = (nan * nan)

    --test-- "nan * zero"
    --assert zero = (nan * zero)

    ; test_multiply(nannan, nannan, nan, "nannan * nannan");
    ; test_multiply(nannan, one, nan, "nannan * 1");

    --test-- "0 * nan"
    --assert zero = (zero * nan)

    ; test_multiply(zero, nannan, zero, "0 * nannan");

    --test-- "zero * zip"
    --assert zero = (zero * zip)
  
    --test-- "zero * maxnum"
    --assert zero = (zero * maxnum)

    --test-- "zip * zero"
    --assert zero = (zip * zero)

    --test-- "zip * zip"
    --assert zero = (zip * zip)

    --test-- "minnum * half"
    --assert minnum = (minnum * half)

    --test-- "minnum * minnum"
    --assert zero = (minnum * minnum)

    --test-- "minnum * minnum"
    --assert zero = (minnum * minnum)

    ; --test-- "epsilon * epsilon"
    ; --assert (to money! [1 -16]) = (minnum * minnum)
    ; test_multiply(one, nannan, nan, "1 * nannan");

    --test-- "-1 * 1"
    --assert negative_one = (negative_one * one)

    --test-- "-1 * -1"
    --assert one = (negative_one * negative_one)

    --test-- "2 * 5"
    --assert ten = (two * five)

    --test-- "2 * maxnum"
    --assert nan = (two * maxnum)

    --test-- "2 * a big one"
    --assert (to money! [1677721 127]) = (two * to money! [8388607 126])

    --test-- "3 * 2"
    --assert six = (three * two)

    --test-- "10 * a big one"
    --assert maxnum = (ten * to money! [8388607 126])

    --test-- "10 * 1e127"
    --assert (to money! [10 127]) = (ten * to money! [1 127])

    --test-- "1e2 * 1e127"
    --assert (to money! [100 127]) = ((to money! [1 2]) * to money! [1 127])

    --test-- "1e12 * 1e127"
    --assert (to money! [1000000000000 127]) = ((to money! [1 12]) * to money! [1 127])

    --test-- "3e16 * 1e127"
    --assert (to money! [30000000000000000 127]) = ((to money! [3 16]) * to money! [1 127])

    --test-- "3e17 * 1e127"
    --assert nan = ((to money! [3 17]) * to money! [1 127])

    --test-- "3e17 * 1e127"
    --assert (to money! [-30000000000000000 127])  = ((to money! [-3 16]) * to money! [1 127])

    --test-- "-3e17 * 1e127"
    --assert nan = ((to money! [-3 17]) * to money! [1 127])

    --test-- "999999 * 10"
    --assert (to money! [999999 1]) = ((to money! [999999 0]) * 10)

    --test-- "maxint * zero"
    --assert zero = (maxint * zero)

    --test-- "maxint * epsilon"
    --assert (to money! [8388607 -6]) = (maxint * epsilon)

    --test-- "maxint * maxint"
    --assert (to money! [70368727400449 7]) = (maxint * maxint)

    ; --test-- "maxint * 1 / maxint"
    ; --assert one = (maxint * one_over_maxint)

    --test-- "-maxint * nan"
    --assert nan = (negative_maxint * nan)

    --test-- "-maxint * maxint"
    --assert (to money! [-70368744177664 7]) = (negative_maxint * maxint)

    --test-- "maxnum * maxnum"
    --assert nan = (maxnum * maxnum)

    --test-- "maxnum * minnum"
    --assert maxint = (maxnum * minnum)

===end-group===

comment {
===start-group=== "multiply; to string!"

    --test-- "nan * nan"
    --assert "NAN" = to string! (nan * nan)

    --test-- "nan * zero"
    --assert "$0.00" = to string! (nan * zero)
    
    ; test_multiply(nannan, nannan, nan, "nannan * nannan");
    ; test_multiply(nannan, one, nan, "nannan * 1");

    --test-- "0 * nan"
    --assert "$0.00" = to string! (zero * nan)

    ; test_multiply(zero, nannan, zero, "0 * nannan");

    --test-- "zero * zip"
    --assert "$0.00" = to string! (zero * zip)

===end-group===
}

===start-group=== "neg"

    --test-- "nan"
    --assert nan = negate nan

    ; test_neg(nannan, nan, "nannan");

    --test-- "zero alias"
    --assert zero = negate to money! [0 100]

    --test-- "zero"
    --assert zero = negate zero

    --test-- "zip"
    --assert zero = negate zip

    --test-- "one"
    --assert negative_one = negate one

    --test-- "-1"
    --assert negative_one = negate one

    --test-- "maxint"
    --assert (to money! [-8388607 0]) = negate maxint

    --test-- "-maxint"
    --assert maxint_plus = negate negative_maxint

    --test-- "maxnum"
    --assert (to money! [-8388607 127]) = negate maxnum

    --test-- "-maxnum"
    --assert (to money! [8388610 127]) = negate negative_maxnum

===end-group===

; NEW here

; NORMAL here

===start-group=== "not"

    --test-- "false"
    --assert true = not false

    --test-- "true"
    --assert false = not true

    --test-- "nan"
    --assert false = not nan

    ; test_not(nannan, nan, "nannan");

    --test-- "zip"
    --assert false = not zip

    --test-- "true alias"
    --assert false = not to money! [10 -1]

    --test-- "almost 1"
    --assert false = not almost_one

    --test-- "2"
    --assert false = not two

    --test-- "-1"
    --assert false = not negative_one

    --test-- "-maxint"
    --assert false = not negative_maxint

    --test-- "-maxnum"
    --assert false = not negative_maxnum

===end-group===

===start-group=== "subtract"

    --test-- "nan - 3"
    --assert nan = (nan - three)
    ; test_subtract(nannan, nannan, nan, "nannan - nannan");
    ; test_subtract(nannan, one, nan, "nannan - 1");
    ; test_subtract(zero, nannan, nan, "0 - nannan");

    --test-- "zero - zip"
    --assert zero = (zero - zip)

    --test-- "0 - -pi"
    --assert pi = (zero - negative_pi)

    --test-- "0 - pi"
    --assert negative_pi = (zero - pi)

    --test-- "0 - -maxint"
    --assert maxint_plus = (zero - negative_maxint)

    --test-- "0 - -maxnum"
    --assert nan = (zero - negative_maxnum)

    --test-- "zip - zero"
    --assert zero = (zip - zero)

    --test-- "zip - zip"
    --assert zero = (zip - zip)

    --test-- "epsilon - epsilon"
    --assert zero = (epsilon - epsilon)

    --test-- "1 - -maxint"
    --assert maxint_plus = (one - negative_maxint)

    --test-- "1 - epsilon"
    --assert almost_one = (one - epsilon)

    --test-- "1 - almost_one"
    --assert epsilon = (one - almost_one)

    --test-- "-1 - -maxint"
    --assert maxint = (negative_one - negative_maxint)

    --test-- "3 - nan"
    --assert nan = (three - nan)

    --test-- "equal but with different exponents"
    --assert zero = (three - to money! [3000000 -6])

    --test-- "3 - 4"
    --assert (to money! [-1 0]) = (three - four)

    --test-- "-pi - -pi"
    --assert zero = (negative_pi - negative_pi)

    --test-- "-pi - 0"
    --assert negative_pi = (negative_pi - zero)

    --test-- "equal but with different exponents"
    --assert zero = (four - to money! [400000 -5])

    --test-- "10 - 6"
    --assert four = (ten - six)

    --test-- "-maxint"
    --assert (to money! [1677722 1]) = (maxint - negative_maxint)

    --test-- "maxint - (maxint + 1)"
    --assert (to money! [-3 0]) = (maxint - maxint_plus)

    --test-- "-maxint - -maxint"
    --assert zero = (negative_maxint - negative_maxint)

    --test-- "maxnum - maxint"
    --assert maxnum = (maxnum - maxint)

    --test-- "maxnum - -maxint" 
    --assert maxnum = (maxnum - negative_maxint)

    --test-- "maxnum - maxnum" 
    --assert zero = (maxnum - maxnum)

    --test-- "almost_negative_one - almost_negative_one" 
    --assert zero = (almost_negative_one - almost_negative_one)

===end-group===

comment {
    test_subtract(maxint, maxint_plus, dec64_new(-3, 0), "maxint - (maxint + 1)");
}

~~~end-file~~~