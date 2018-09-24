Red/System [
	Title:   "Money! datatype runtime functions"
	Author:  "Harald Wille"
	File: 	 %money.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define MIN_FLOAT -9223372036854775808.0
#define MAX_FLOAT  9223372036854775807.0

#define MIN_INT ‭FFFFFFFF80000000‬h ; ‭-2147483648
#define MAX_INT ‭000000007FFFFFFF‬h ;  2147483647
                                     
; 32-bit
#define MIN_COEFFICIENT FF800000h ; -8388608
#define MAX_COEFFICIENT 007FFFFFh ;  8388607
#define ULTIMATE_COEFFICIENT 8388608
#define ULTIMATE_COEFFICIENT_10 83886080
#define ULTIMATE_COEFFICIENT_100 838860800

; 64-bit
; #define MIN_COEFFICIENT -3.6028797018963968E16 ; FF800000000000000000000000000000h
; #define MAX_COEFFICIENT  3.6028797018963967E16 ; 0000000000000000007FFFFFFFFFFFFFh

#define MIN_EXPONENT FFFFFF81h 	; -127
#define MAX_EXPONENT 0000007Fh 	;  127

#define NAN FFFFFF80h 			; -128
#define EXPONENT_MASK FFh 		;  255
#define COEFFICIENT_SHIFT 08h	;  8
#define EXPONENT_SHIFT 18h		; 24
#define COEFFICIENT_MASK FFFFFF00h ; -256
#define SHIFT_MULTIPLY 0100h 	;  256

int64!: alias struct! [int1 [integer!] int2 [integer!]]

money: context [
	
	; powers of 10
	powers: [
		1						; 0
		10						; 1
		100						; 2
		1000					; 3
		10000					; 4
		100000					; 5
		1000000					; 6		
		10000000				; 7
		100000000				; 8
		1000000000			    ; 9		
		; 32-bit limit 2147483647 (24-bit 8388608)
		; 10000000000	   	    ; 10
		; 100000000000			; 11
		; 1000000000000			; 12
		; 10000000000000		; 13
		; 100000000000000		; 14
		; 1000000000000000		; 15
		; 10000000000000000		; 16
		; 100000000000000000	; 17
		; 1000000000000000000	; 18
		; 10000000000000000000	; 19
		; 64-bit 36028797018963968
	]

	verbose: 0
	
	overflow?: func [
		integer	[integer!]
		return: [logic!]
	][
		any [integer > MAX_COEFFICIENT integer < MIN_COEFFICIENT]
	]

	safe-add: func [
		left	[integer!]
		right	[integer!]
		return: [integer!]
	][
		either all [left > 0 right > (2147483647 - left)][
			fire [TO_ERROR(math overflow)]
			return 0
		][
			if all [left < 0 right < (-2147483648 - left)][
				fire [TO_ERROR(math overflow)]
				return 0
			]
		]

		left + right
	]

	box: func [
		value	[integer!]
		return:	[red-money!]
		/local
			money [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/box"]]

		money: as red-money! stack/arguments
		money/header: TYPE_MONEY
		money/value: value
		money
	]
	
	push: func [
		value	[integer!]
		return: [red-money!]
		/local
			money [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/push"]]
		
		money: as red-money! stack/push*
		money/header: TYPE_MONEY
		money/value: value
		money
	]

	; the coefficient is too big, so it's attempted to scale it back by decreasing the coefficient of the DEC64 value
	pack-large: func [
		value 	[red-money!]
		return: [red-money!]
	]
	[
		#if debug? = yes [if verbose > 0 [print-line "money/pack-large"]]

		print-line ["money/pack-large"]

		value/coefficient: value/coefficient / 10.0
		value/exponent: value/exponent + 1
		value: convert value

		print-line ["coefficient: " value/coefficient " exponent: " value/exponent " value: " value/value]

		value
	]
	
	; the exponent is too small, so it's attempted to scale it up by increasing the exponent of the DEC64 value
	pack-increase: func [
		value 		[red-money!]
		diff		[integer!]
		return:		[red-money!]
		/local
			power-of-ten		[integer!]
			half-power-of-ten	[integer!]
	]
	[
		#if debug? = yes [if verbose > 0 [print-line "money/pack-increase"]]

		diff: diff + 1 ; TODO: look into a way to dynamically calculate the offset
		power-of-ten: powers/diff ; powers of two start with 0, so we have to add 1 to get the correct index into powers

		; restore original value
		diff: diff - 1

		; if the difference is more than 10, the result is zero (rare)
		if diff > 10 [
			value/coefficient: 0
			value/exponent: 0
			return value
		]

		; sign the power of 10 according to the sign of the coefficient
		; if value/coefficient < 0 [power-of-ten: power-of-ten * -1]

		; rounding fudge
		half-power-of-ten: power-of-ten / 2

		print-line ["half-power-of-ten: " half-power-of-ten]

		; add the rounding fudge
		either value/coefficient < 0 [
			print-line ["-"]
			value/coefficient: value/coefficient - half-power-of-ten
		][
			print-line ["+"]
			value/coefficient: value/coefficient + half-power-of-ten
		]		

		print-line ["value/coefficient " value/coefficient]

		; divide by the power of ten
		value/coefficient: value/coefficient / power-of-ten
	
		print-line ["value/coefficient " value/coefficient]

		; increase the exponent by the difference
		value/exponent: value/exponent + diff

		value
	]	

	; the exponent is too big, so it's attempted to scale it back by decreasing the exponent of the DEC64 value
	; this can salvage values in a small set of cases, because the decimal values are decreased
	pack-decrease: func [
		value 		[red-money!]
		return:		[red-money!]
		/local
			carry	[integer!]
	][		
		#if debug? = yes [if verbose > 0 [print-line "money/pack-decrease"]]

		; decrease the exponent until it is smaller than MAX_EXPONENT
		while [value/exponent > MAX_EXPONENT][

			print-line ["value/exponent: " value/exponent]

			; multiply the coefficient by 10			
			value/coefficient: value/coefficient * 10	

			; if we overflow, we failed to salvage and bail out early
			if system/cpu/overflow? [
				print-line ["overflow"]
				value: generate-nan value

				print-line ["value/exponent: " value/exponent]
				print-line ["value/coefficient: " value/coefficient]
				print-line ["value/value: " value/value]

				return value
			]

			; decrease the exponent
			value/exponent: value/exponent - 1		

			print-line ["value/exponent: " value/exponent]
			print-line ["value/coefficient: " value/coefficient]
		]
			
		carry: value/coefficient >> EXPONENT_SHIFT
		
		either carry <> 0 [
			print-line ["carry: " carry]
			value: generate-nan value

			return value
		][
			; if the coefficient is zero, also zero out the exponent
			if value/coefficient = 0 [value/exponent: 0]
		]
		
		value/value: value/coefficient << COEFFICIENT_SHIFT	; shift the coefficient into place
		value/value: value/value or value/exponent			; add the exponent value		
		
		value		
	]

	; The pack function will combine the coefficient and exponent into a dec64.
	; Numbers that are too huge to be contained in this format become nan.
	; Numbers that are too tiny to be contained in this format become zero.
	pack: func [
		value 	[red-money!]
		return:	[red-money!]
		/local
			diff_coefficient [integer!] ; difference of the coefficient in digits
			diff_exponent	 [integer!] ; difference of the exponent in digits
			exponent		 [integer!] ; masked exponent
			coefficient		 [integer!] ; absolute value of the coefficient
			loop?			 [logic!] 	; continue looping from pack-large
	][		
		#if debug? = yes [if verbose > 0 [print-line "money/pack"]]

		print-line ["money/pack"]

		loop?: no

		; the value is packed, as long as there it is not a number
		; if there is some valid packing found, the loop is bailed out early
		until [
			; If the exponent is greater than 127, then the number is too big and we bail out early.
			; But it might still be possible to salvage a value.
			if value/exponent > 127 [
				print-line ["value/exponent > 127"]	
				return pack-decrease value
			]

			; If the exponent is too small, or if the coefficient is too large, then some
			; division is necessary. The absolute value of the coefficient is off by one
			; for the negative because
			;    negative_extreme_coefficent = -(extreme_coefficent + 1)

			diff_coefficient: 0
			diff_exponent: 0

			; the difference in digits between 32-bit values and 24-bit values is 3, so we can safely multiply by 100 tp get the maximum
			; max-coefficient 			= 8388608
			; max-coefficient * 100 	= 838860800
			; max-coefficient * 10 - 1  = 83886079
			; max-coefficient - 1		= 8388607

			print-line ["coefficient: " value/coefficient " exponent: " value/exponent " value: " value/value]

			; negate the coefficient
			coefficient: value/coefficient xor -1
			if coefficient < 0 [coefficient: value/coefficient]

			print-line ["coefficient: " coefficient " value/coefficient: " value/coefficient " exponent: " value/exponent " value: " value/value]
			
			either coefficient > ULTIMATE_COEFFICIENT_100 [
				print-line ["ULTIMATE_COEFFICIENT_100 coefficient: " coefficient " > " ULTIMATE_COEFFICIENT_100]
				value: pack-large value

				; the loop is started over
				print-line ["loop"]
				loop?: yes
			][
				if coefficient > (ULTIMATE_COEFFICIENT - 1) [
					diff_coefficient: diff_coefficient + 1

					print-line ["ULTIMATE_COEFFICIENT - 1 coefficient: " coefficient " > " ULTIMATE_COEFFICIENT - 1]
				]

				diff_exponent: MIN_EXPONENT - value/exponent

				if coefficient > (ULTIMATE_COEFFICIENT_10 - 1) [
					diff_coefficient: diff_coefficient + 1

					print-line ["ULTIMATE_COEFFICIENT_10 - 1 coefficient: " coefficient " > " ULTIMATE_COEFFICIENT_10 - 1]
			
				]

				; check, which access is larger
				diff_coefficient: either diff_coefficient > diff_exponent [diff_coefficient][diff_exponent]

				either diff_coefficient > 0 [
					print-line ["diff_coefficient: call pack-increase with value/coefficient: " value/coefficient]

					value: pack-increase value diff_coefficient

					print-line ["           after: call pack-increase with value/coefficient: " value/coefficient]

					; the loop is started over
					either value/coefficient = 0 [
						loop?: no

						print-line ["exit loop"]
					][
						print-line ["loop"]
						loop?: yes
					]
				]
				[			
					; if the coefficient is zero, also zero the exp
					if value/coefficient = 0 [
						value/exponent: 0
					]

					loop?: no
					print-line ["coeff/exp = 0 or coeff/exp are valid; exit loop"]

				]
			]
			
			; we bail out, if the number is zero or not a number
			; any [loop?:yes value/coefficient <> 0 value/exponent <> NAN]

			print-line ["rerun loop"]

			loop? = no
		]

		print-line ["bailed out"]
		print-line ["coefficient: " value/coefficient " exponent: " value/exponent " value: " value/value]
		value: convert value

		print-line ["after convert"]
		print-line ["coefficient: " value/coefficient " exponent: " value/exponent " value: " value/value]
		value
	]

	convert: func [
		value	[red-money!]
		return:	[red-money!]
		/local
			exponent [integer!]
		
	][
		; shift the coefficient into position
		value/value: value/coefficient << COEFFICIENT_SHIFT		

		; mix in the exponent
		exponent: value/exponent and EXPONENT_MASK

		value/value: value/value or exponent
			
		print-line ["value/coefficient: " value/coefficient " value/exponent: " value/exponent " value/value: " value/value]

		value
	]

	generate-nan: func [
		value	[red-money!]
		return:	[red-money!]
	][
		value/coefficient: 0
		value/exponent: NAN
		value/value: NAN
			
		value
	]


	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/add"]]

		as red-value! do-math OP_ADD
	]
	
	sub: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/sub"]]

		as red-value! do-math OP_SUB
	]

	multiply: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/multiply"]]

		as red-value! do-math OP_MUL
	]

	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/divide"]]

		as red-value! do-math OP_DIV
	]

	add-money: func [
		lhs		[red-money!]
		rhs		[red-money!]
		return: [red-money!]
		/local
			diff 					[integer!]
			power-of-ten 			[integer!]
			tmp						[integer!]
			enlarged_coefficient	[integer!]
			neg?					[logic!]

	][
		print-line ["lhs/exponent: " lhs/exponent " rhs/exponent: " rhs/exponent]
		print-line ["lhs/coefficient: " lhs/coefficient " rhs/coefficient: " rhs/coefficient]
		print-line ["lhs/value: " lhs/value " rhs/value: " rhs/value]

		if lhs/coefficient < 0 [
			print-line ["value is negative"]
			neg?: yes
		]

		; copy the value into the coefficient, as calculations are done in the 32-bit coefficient slot
		; and the original value is saved in the value slot
		lhs/coefficient: lhs/value ; lhs/value and FFFFFF00h
		rhs/coefficient: rhs/value ; rhs/value and FFFFFF00h

		print-line ["after shift lhs/coefficient: " lhs/coefficient " rhs/coefficient: " rhs/coefficient]

		; fast path: coefficients can be added, if the exponents are both zero
		either all [lhs/exponent = 0 rhs/exponent = 0][
			print-line ["fast path; add coefficients"]
			print-line ["lhs/coefficient: " lhs/coefficient " rhs/coefficient: " rhs/coefficient]
			lhs/coefficient: lhs/coefficient + rhs/coefficient

			; check overflow
			either system/cpu/overflow? [
				print-line ["overflow"]
				; If there was an overflow (extremely unlikely) then we must make it fit.
				; pack knows how to do that.				
				; rotate with carry
 				print-line ["lhs/value: " lhs/value " lhs/coefficient: " lhs/coefficient]				
				lhs/coefficient: (lhs/coefficient >>> 1) or (lhs/coefficient << 31) >> (COEFFICIENT_SHIFT - 1)
 
				; get back the original coefficients, as we had an overflow
				rhs/coefficient: rhs/value >> COEFFICIENT_SHIFT

				print-line [">> 8: lhs/coefficient: " lhs/coefficient " rhs/coefficient: " rhs/coefficient]				

				return pack lhs
			][
				print-line ["no overflow; shift coefficients >> 8"]
				; shift back the coefficients
				lhs/coefficient: lhs/coefficient >> COEFFICIENT_SHIFT
				rhs/coefficient: rhs/coefficient >> COEFFICIENT_SHIFT
				return convert lhs
			]
		][					
			print-line ["slow path"]

			; The slow path is taken if the two operands do not both have zero exponents.
			; Any of the exponents is nan
			either any [lhs/exponent = NAN rhs/exponent = NAN][
				lhs: generate-nan lhs

				return lhs
			]
			[			
				; Are the two exponents the same? This will happen often, especially with
				; money values.
				either lhs/exponent = rhs/exponent [			
					print-line ["exponents match: " lhs/exponent " " rhs/exponent]
					; The exponents match so we may add now. Zero out the exponents so there
					; will be no carry into the coefficients when the coefficients are added.
					; If the result is zero, then return the normal zero.

					lhs/coefficient: lhs/coefficient and COEFFICIENT_MASK
					rhs/coefficient: rhs/coefficient and COEFFICIENT_MASK

					print-line ["adding coefficients: " lhs/coefficient " " rhs/coefficient]
					lhs/coefficient: lhs/coefficient + rhs/coefficient

					; check overflow
					either system/cpu/overflow? [
						print-line ["overflow"]
						; If there was an overflow (extremely unlikely) then we must make it fit.
						; pack knows how to do that.

						print-line ["old: " lhs/coefficient]
						print-line ["rcr: " lhs/coefficient >> 1]
						print-line ["     " lhs/coefficient >> 1 + MAX_COEFFICIENT]

						; get back the coefficients
						; lhs/coefficient: lhs/value >> COEFFICIENT_SHIFT
						; rhs/coefficient: rhs/value >> COEFFICIENT_SHIFT

						; simulate rotate with carry (rcr)
						lhs/coefficient: lhs/coefficient >> 1 + MAX_COEFFICIENT
						;lhs/coefficient: lhs/coefficient / 2

						print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value " rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]

						; get back the original coefficients and exponents, as we had an overflow
						lhs/coefficient: lhs/value >> COEFFICIENT_SHIFT
						rhs/coefficient: rhs/value >> COEFFICIENT_SHIFT

						lhs/exponent: lhs/value << EXPONENT_SHIFT >> EXPONENT_SHIFT
						rhs/exponent: lhs/exponent

						print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value " lhs/value " rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]

						return pack lhs

					][
						; if the coefficient is zero, the exponent is zero
						if lhs/coefficient = 0 [
							print-line ["coefficient is zero: " lhs/coefficient]
							lhs/exponent: 0
						]

						; shift back the coefficients
						lhs/coefficient: lhs/coefficient >> COEFFICIENT_SHIFT
						rhs/coefficient: rhs/coefficient >> COEFFICIENT_SHIFT

						print-line ["return lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value " lhs/value " rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]

						return convert lhs
					]
				][
					print-line ["slower path"]
					; The slower path is taken when neither operand is nan, and their
					; exponents are different. Before addition can take place, the exponents
					; must be made to match. Swap the numbers if the second exponent is greater
					; than the first.
					; swap exponents
					if rhs/exponent > lhs/exponent [
						tmp: lhs/exponent
						lhs/exponent: rhs/exponent
						rhs/exponent: tmp

						tmp: lhs/coefficient
						lhs/coefficient: rhs/coefficient
						rhs/coefficient: tmp

						tmp: lhs/value
						lhs/value: rhs/value
						rhs/value: tmp

						print-line ["swapping values"]

						print-line ["after swapping lhs/coefficient: " lhs/coefficient " rhs/coefficient: " rhs/coefficient]
						print-line ["after swapping lhs/exponent: " lhs/exponent " rhs/exponent: " rhs/exponent]
						print-line ["after swapping lhs/value: " lhs/value " rhs/value: " rhs/value]
					]

					print-line ["shift back lhs/coefficient: " lhs/coefficient " rhs/coefficient: " rhs/coefficient]
					print-line ["           lhs/exponent: " lhs/exponent " rhs/exponent: " rhs/exponent]
					print-line ["           lhs/value: " lhs/value " rhs/value: " rhs/value]

					; shift back the coefficients
					lhs/coefficient: lhs/coefficient >> COEFFICIENT_SHIFT
					rhs/coefficient: rhs/coefficient >> COEFFICIENT_SHIFT
					enlarged_coefficient: lhs/coefficient

					; add slower decrease
					; The coefficients are not the same. Before we can add, they must be the same.
					; We will try to decrease the first exponent. When we decrease the exponent
					; by 1, we must also multiply the coefficient by 10. We can do this as long as
					; there is no overflow. We have 8 extra bits to work with, so we can do this
					; at least twice, possibly more.
					until [
						enlarged_coefficient: enlarged_coefficient * 10
						
						; check on overflow
						if system/cpu/overflow? [
							print-line ["overflow"]

							; add slower increase
							; We cannot decrease the first exponent any more, so we must instead try to
							; increase the second exponent, which will result in a loss of significance.
							; That is the heartbreak of floating point.

							; Determine how many places need to be shifted. If it is more than 7, there is
							; nothing more to add.

							; get back the original coefficients, as we had an overflow
							; lhs/coefficient: lhs/value >> COEFFICIENT_SHIFT
							; rhs/coefficient: rhs/value >> COEFFICIENT_SHIFT

							diff: lhs/exponent - rhs/exponent
							either diff > 7 [
								print-line ["diff > 7: " diff]
								; too small to matter
								; return the original number

								print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value " lhs/value]
								return lhs
							][
								print-line ["diff < 7: " diff]

								print-line ["< 7: lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value " lhs/value]
								print-line ["< 7: rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value " rhs/value]
								diff: diff + 1
								power-of-ten: powers/diff
								rhs/coefficient: rhs/coefficient / power-of-ten								
										
								print-line ["< 7: power-of-ten: " power-of-ten " rhs/coefficient: " rhs/coefficient]
								either rhs/coefficient = 0 [
									print-line ["too insignifcant = 0: " rhs/coefficient]
									; too insignificant to add
									; return the original number
									return lhs
								][
									print-line ["add together"]

									lhs/coefficient: lhs/coefficient + rhs/coefficient
									print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value " lhs/value " rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]
									return pack lhs
								]
							]
						]						

						lhs/coefficient: enlarged_coefficient
						lhs/exponent: lhs/exponent - 1

						print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " rhs/exponent: " rhs/exponent]

						lhs/exponent = rhs/exponent
					]
					
					print-line ["normal add: lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value " rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]

					lhs/coefficient: lhs/coefficient + rhs/coefficient

					return pack lhs					
				]
			]	
		]
	]

	subtract-money: func [
		lhs		[red-money!]
		rhs		[red-money!]
		return: [red-money!]
		/local
			diff 			[integer!]
			power-of-ten 	[integer!]
			tmp				[integer!]
			a				[integer!]
			b				[integer!]

	][
		; This is the same as add-money, except that the rhs operand its
		; coefficient complemented first.
		; rhs/coefficient: rhs/coefficient xor -1
		; rhs/coefficient: rhs/coefficient + 1
		; exponents don't need to be complemented, as they are added to the value

		print-line ["subtract-money rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]
		rhs/coefficient: rhs/coefficient xor -1 + 1
		print-line ["a: " rhs/value >> 8 xor -1 + 1 << 8]
		tmp: rhs/value >> 8 xor -1 + 1 << 8 
		a: rhs/value >> 8 xor -1 + 1 << 8
		b: either rhs/exponent > 0 [rhs/exponent][rhs/exponent + SHIFT_MULTIPLY]

		print-line ["a: " a]
		print-line ["b: " b]
		a: a xor b
		print-line ["a: " a]
		a: (rhs/value >> 8 xor -1 + 1 << 8) or either rhs/exponent > 0 [rhs/exponent][rhs/exponent + SHIFT_MULTIPLY]
		print-line ["a: " a]
		print-line ["b: " rhs/value >> 8 xor -1 + 1 << 8 " " either rhs/exponent > 0 [rhs/exponent][rhs/exponent + SHIFT_MULTIPLY]]
		print-line ["c: " (rhs/value >> 8 xor -1 + 1 << 8) or (either rhs/exponent > 0 [rhs/exponent][rhs/exponent + SHIFT_MULTIPLY])]
		rhs/value: (rhs/value >> 8 xor -1 + 1 << 8) or either rhs/exponent > 0 [rhs/exponent][rhs/exponent + SHIFT_MULTIPLY]
		rhs/value: tmp or either rhs/exponent > 0 [rhs/exponent][rhs/exponent + SHIFT_MULTIPLY]

		rhs: convert rhs

		print-line ["subtract-money rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]
		;if there is no overflow, begin the adding
		either not system/cpu/overflow? [
			print-line ["no overflow: " rhs/coefficient]

			return add-money lhs rhs
		][
			print-line ["overflow"]
			; The subtrahend coefficient is -8388608. This value cannot easily be
			; complemented, so take the slower path. This should be extremely rare.		
			either any [lhs/exponent = NAN rhs/exponent = NAN][
				lhs: generate-nan lhs

				return lhs
			]
			[
				; swap
				if rhs/exponent > lhs/exponent [
					tmp: lhs/exponent
					lhs/exponent: rhs/exponent
					rhs/exponent: tmp
				]

				; The coefficients are not the same. Before we can add, they must be the same.
				; We will try to decrease the first exponent. When we decrease the exponent
				; by 1, we must also multiply the coefficient by 10. We can do this as long as
				; there is no overflow. We have 8 extra bits to work with, so we can do this
				; at least twice, possibly more.
				while [lhs/exponent <> rhs/exponent][
					lhs/coefficient: lhs/coefficient * 10

					; check on overflow
					if system/cpu/overflow? [
						; sub slower increase
						; We cannot decrease the first exponent any more, so we must instead try to
						; increase the second exponent, which will result in a loss of significance.
						; That is the heartbreak of floating point.

						; Determine how many places need to be shifted. If it is more than 7, there is
						; nothing more to add.
						diff: lhs/exponent - rhs/exponent
						either diff > 7 [
							; too small to matter
							; call pack with the original value
							return pack lhs
						][
							power-of-ten: powers/diff
							rhs/coefficient: rhs/coefficient / power-of-ten
						]
					]
					
					lhs/exponent: lhs/exponent - 1								
				]

				; The exponents are now equal, so the coefficients may be added.
				lhs/coefficient: lhs/coefficient + rhs/coefficient

				return pack lhs					
			]					
		]
	]

	multiply-money: func [
		lhs		[red-money!]
		rhs		[red-money!]
		return: [red-money!]
		/local
			diff 			[integer!]
			power-of-ten 	[integer!]
			tmp				[integer!]
			digits			[integer!]
			neg? 			[logic!]
	][
		print-line ["multiply-money"]
		print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value]
		print-line ["rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]

		neg?: no
		; The result is nan if one or both of the exponents is nan and neither of the
		; coefficients is zero.
		; either any [all [lhs/exponent = NAN lhs/coefficient = 0] all [rhs/exponent = NAN rhs/coefficient = 0]][
		; either all [any [lhs/exponent = NAN rhs/exponent = NAN] all [lhs/coefficient <> 0 rhs/coefficient <> 0]][
		either any [all [lhs/exponent = NAN lhs/coefficient = 0]
					all [lhs/exponent = NAN lhs/coefficient = 0 rhs/exponent = NAN rhs/coefficient = 0]
					all [lhs/coefficient <> 0 lhs/exponent <> NAN rhs/exponent = NAN]][
			lhs: generate-nan lhs

			return lhs
		][
			lhs/exponent: lhs/exponent + rhs/exponent
			
			if lhs/coefficient xor rhs/coefficient < 0 [neg? yes]

			print-line ["negative product: " neg?]

			; lhs/value: lhs/value * rhs/value

			lhs/coefficient: lhs/coefficient * rhs/coefficient

			; check overflow
			if overflow? lhs/coefficient[
				print-line ["overflow"]

				lhs: generate-nan lhs
				return lhs
				
				; There was an overflow.
				; Make the 110 bit coefficient all fit. Estimate the number of
				; digits of excess, and increase the exponent by that many digits.
				; We use 77/256 to convert log2 to log10.
				; work with absolute value

				; an overflow is produced by going over the max coefficient, so we need to restore it
				; either neg? [lhs/coefficient: MIN_COEFFICIENT - 1][lhs/coefficient: MAX_COEFFICIENT + 1]

				print-line ["lhs/coefficient: " lhs/coefficient]
				tmp: lhs/coefficient
										
				print-line ["tmp: " tmp " idx: " (msb-DeBruijn-32 as byte-ptr! tmp)]

				; lhs/coefficient: (lhs/coefficient >>> 1) or (lhs/coefficient << 31) >> (COEFFICIENT_SHIFT - 1)
 
				; print-line ["rotate with carry: lhs/coefficient: " lhs/coefficient]

				digits: 8 - ((msb-DeBruijn-32 as byte-ptr! tmp) * 77 >> COEFFICIENT_SHIFT + 2) ; add two extra digits to the scale

				; we can only scale 9 digits maxium				
				if digits < 0 [
					print-line ["<0; cannot scale"]
					digits: 0

					; return a NaN
					lhs: generate-nan lhs

					return lhs
				]				

				print-line ["digits: " digits]
				; lhs/exponent: lhs/exponent + digits + 1 ; add 1 for the digit from the overflow

				digits: digits + 1
				power-of-ten: powers/digits
				digits: digits - 1 
				print-line ["lhs/coefficient: " lhs/coefficient " power-of-ten: " power-of-ten]

				lhs/coefficient: lhs/coefficient / power-of-ten

				
			]
			
			print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value]

			lhs: convert lhs
			
			print-line ["after comvert lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value]
			lhs: pack lhs
		]

		return lhs
	]

	divide-money: func [
		lhs		[red-money!]
		rhs		[red-money!]
		return: [red-money!]
		/local
			diff 			[integer!]
			power-of-ten 	[integer!]
			dividend		[integer!]
			divisor			[integer!]
			scale-factor	[integer!]
			msb_dividend	[integer!]
			msb_divisor		[integer!]
			value			[byte-ptr!]
	][
		print-line "divide-money"

		print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value]
		print-line ["rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]

		case [
			; if the dividiend is zero
			all [lhs/coefficient = 0 lhs/exponent <> NAN][
				lhs/exponent: 0
				lhs: convert lhs

				print-line "0"
				return lhs
			]

			; if either is nan or dividing by zero
			any [lhs/exponent = NAN rhs/exponent = NAN rhs/coefficient = 0][
				lhs: generate-nan lhs

				print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value]

				return lhs
			]

			; if neither is nan and the dividiend is not zero
			true [							
				until [
					; We want to get as many bits into the quotient as possible in order to capture
					; enough significance. But if the quotient has more than 64 bits, then there
					; will be a hardware fault. To avoid that, we compare the magnitudes of the
					; dividend coefficient and divisor coefficient, and use that to scale the
					; dividend to give us a good quotient.

					; Multiply the dividend by the scale factor, and divide that 128 bit result by
					; the divisor.  Because of the scaling, the quotient is guaranteed to use most
					; of the 64 bits, and never more. Reduce the final exponent by the number
					; of digits scaled.

					; use absolute values
					dividend: lhs/coefficient
					divisor: rhs/coefficient

					value: as byte-ptr! dividend
					
					if dividend < 0 [dividend: dividend * -1]
					if divisor < 0 [divisor: divisor * -1]

					msb_dividend: msb-DeBruijn-32 as byte-ptr! dividend
					msb_divisor: msb-DeBruijn-32 as byte-ptr! divisor

					print-line ["dividend: " dividend " divisor: " divisor " msb_dividend: " msb_dividend " msb_divisor: " msb_divisor]

					; Scale up the dividend to be approximately 58 bits longer than the divisor.
					; Scaling uses factors of 10, so we must convert from a bit count to a digit
					; count by multiplication by 77/256 (approximately LN2/LN10).
					; scale-factor: msb_divisor + 58 - msb_dividend * 77 >> COEFFICIENT_SHIFT
					; scale-factor: msb_divisor + 26 - msb_dividend * 77 >> COEFFICIENT_SHIFT
					; we cannot use 128-bit register splits like with imul/idiv
					; scale-factor: 30 - msb_dividend * 77 >> COEFFICIENT_SHIFT

					scale-factor: 30 - msb_dividend * 77 >> COEFFICIENT_SHIFT
					; scale-factor: msb_divisor + 26 - msb_dividend * 77 >> COEFFICIENT_SHIFT
					print-line ["scale-factor: " scale-factor]
					; The largest power of 10 that can be held in an int32 is 1e9.

					either scale-factor > 9 [
						print-line "scale-factor > 9"

						; If the number of scaling digits is larger than 18, then we will have to
						; scale in two steps: first prescaling the dividend to fill a register, and
						; then repeating to fill a second register. This happens when the divisor
						; coefficient is much larger than the dividend coefficient.
						scale-factor: 26 - msb_dividend * 77 >> COEFFICIENT_SHIFT
						scale-factor: scale-factor + 1
						power-of-ten: powers/scale-factor
						scale-factor: scale-factor - 1
						print-line ["new scale-factor: " scale-factor " power-of-ten: " power-of-ten]					
					][
						print-line "scale-factor <= 9"

						; Multiply the dividend by the scale factor, and divide that 128 bit result by
						; the divisor.  Because of the scaling, the quotient is guaranteed to use most
						; of the 64 bits, and never more. Reduce the final exponent by the number
						; of digits scaled.
						scale-factor: scale-factor + 1
						power-of-ten: powers/scale-factor
						scale-factor: scale-factor - 1
						print-line ["new scale-factor: " scale-factor " power-of-ten: " power-of-ten]												
					]			

					print-line ["lhs/coefficient: " lhs/coefficient " power-of-ten: " power-of-ten " rhs/coefficient: " rhs/coefficient]

					lhs/coefficient: lhs/coefficient * power-of-ten
					lhs/exponent: lhs/exponent - scale-factor
					lhs: convert lhs
					print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value]
					print-line ["rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]				

					scale-factor < 10
				]

				print-line "return"
				
				lhs/coefficient: lhs/coefficient / rhs/coefficient
				lhs/exponent: lhs/exponent - rhs/exponent
				lhs: convert lhs
				
				print-line ["lhs/coefficient: " lhs/coefficient " lhs/exponent: " lhs/exponent " lhs/value: " lhs/value]
				print-line ["rhs/coefficient: " rhs/coefficient " rhs/exponent: " rhs/exponent " rhs/value: " rhs/value]							
				
				lhs: pack lhs
			]
		]
		return lhs
	]
 
	negate: func [
		return: [red-money!]
		/local
			money [red-money!]
			fl	  [red-float!]
			value [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/negate"]]
		
		money: as red-money! stack/arguments

		; Negate a number. We need to negate the coefficient without changing the
		; exponent.
		if money/exponent = NAN [
			money/coefficient: 0

			return money
		]

		; if the coefficient is zero, then the zero the exponent too
		if money/coefficient = 0 [
			money/exponent = 0
		]

		; complement/negate
		money/value: money/value xor -256
		money/value: money/value + 256

		; The coefficient is -36028797018963968, which is the only coefficient that
		; cannot be trivially negated. So we do this the hard way.
		if system/cpu/overflow? [
			; complement/negate the coefficient
			money/coefficient: (money/coefficient xor -1) + 1

			return pack money
		]

		; store the coefficient and exponent based on the value
		money/coefficient: money/value >> COEFFICIENT_SHIFT
		money/exponent: money/value and EXPONENT_MASK

		money
	]

	absolute: func [
		return: [red-money!]
		/local
			money [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/absolute"]]
		
		money: as red-money! stack/arguments

		; Find the absolute value of a number. If the number is negative, hand it off
		; to negate. Otherwise, return the number unless it is nan or zero.
		if money/coefficient < 0 [
			return negate money
		]

		case [
			; if the coefficient is zero, then the zero the exponent too
			money/coefficient = 0 [
				money/exponent: 0
			]
			; is the number NaN?
			money/exponent = NAN [
				money/coefficient: 0
			]
			true []
		]

		return convert money
	]

	compare: func [
		lhs    	[red-money!]						;-- first operand
		rhs   	[red-money!]						;-- second operand
		op	    [integer!]							;-- type of comparison
		return:	[integer!]
		/local
			value 	[red-value!] 
			result	[integer!]
			tmp		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/compare"]]

		if all [
			any [op = COMP_FIND op = COMP_SAME op = COMP_STRICT_EQUAL]
			TYPE_OF(rhs) <> TYPE_MONEY
		][
			return 1
		]
		
		rhs: as red-money! rhs
		value: as red-value! rhs 				
		
		switch TYPE_OF(rhs) [
			TYPE_CHAR 
			TYPE_INTEGER [
				value/header: TYPE_INTEGER
				rhs: money/to rhs value TYPE_INTEGER
			]
			TYPE_FLOAT
			TYPE_PERCENT [
				value/header: TYPE_FLOAT
				rhs: money/to rhs value TYPE_FLOAT
			]
			TYPE_MONEY
			[]
			default [RETURN_COMPARE_OTHER]
		]

		print-line ["euqal lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
		print-line ["      rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

		switch op [
			COMP_EQUAL
			COMP_STRICT_EQUAL	[result: equal-money lhs rhs]
			COMP_NOT_EQUAL 		[result: (equal-money lhs rhs) xor -1 + 1]
			COMP_LESSER			[result: less-money lhs rhs]
			COMP_LESSER_EQUAL 	[
				print-line ["call lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["     rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

				tmp: less-money lhs rhs
				print-line ["less: " tmp]

				print-line ["ret lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["    rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

				print-line ["call lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["     rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]
				
				result: equal-money lhs rhs
				print-line ["equal: " result]
				print-line ["ret lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["    rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]
				
				print-line ["result either: " either any [(less-money lhs rhs) = -1 (equal-money lhs rhs) = 0][0][1]]
				print-line ["result either: " either any [tmp = -1 result = 0][0][1]]

				; result: either any [(less-money lhs rhs) = -1 (equal-money lhs rhs) = 0][0][1]]

				print-line ["less tmp: " tmp " equal result: " result]

				result: either any [tmp = -1 result = 0][0][1]]
			
			COMP_GREATER 		[result: (less-money rhs lhs) xor -1 + 1]
			COMP_GREATER_EQUAL 	[
				print-line ["call lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["     rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

				tmp: (less-money rhs lhs) xor -1 + 1
				print-line ["less: " tmp]

				print-line ["ret lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["    rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

				print-line ["call lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["     rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

				result: equal-money lhs rhs

				print-line ["ret lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
				print-line ["    rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

				; result: either any [((less-money rhs lhs) xor -1 + 1) = 1 (equal-money lhs rhs) = 0][0][-1]]

				print-line ["result either: " either any [((less-money rhs lhs) xor -1 + 1) = 1 (equal-money lhs rhs) = 0][0][-1]]
				print-line ["result either: " either any [tmp = 1 result = 0][0][1]]

				print-line ["less tmp: " tmp " equal result: " result]

				result: either any [tmp = 1 result = 0][0][-1]]
			default [SIGN_COMPARE_RESULT(lhs/value rhs/value)]
		]

		print-line ["result: " result]
		result
	]

	equal-money: func [
		; Compare two dec64 numbers. If they are equal, return 0, otherwise return 1.
		; Denormal zeroes are equal but denormal nans are not.
		lhs 	[red-money!]
		rhs 	[red-money!]
		return: [integer!]
			/local
				difference [red-money!]
				tmp_lhs    [red-money!]
				tmp_rhs    [red-money!]
	]
	[
		#if debug? = yes [if verbose > 0 [print-line "money/equal-money"]]
		
		; If the numbers are trivally equal, then return 0.
		if lhs/value = rhs/value [
			return 0
		]

		; If the exponents match or if their signs are different, then return false.
		if any [lhs/exponent = rhs/exponent lhs/value xor rhs/value < 0][
			print-line ["wrong"]
			print-line ["lhs/coefficient: " lhs/coefficient " rhs/coefficient: " rhs/coefficient " lhs/exponent: " lhs/exponent " rhs/exponent: " rhs/exponent " lhs/value: " lhs/value " rhs/value: " rhs/value " lhs/value xor rhs/value: " lhs/value xor rhs/value]
			return 1
		]

		print-line ["equal subtract lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
		print-line ["               rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]

		; save the original value, as subract-money will change lhs/rhs.
		tmp_lhs: declare red-money!
		copy-cell as red-value! lhs as red-value! tmp_lhs
		tmp_rhs: declare red-money!
		copy-cell as red-value! rhs as red-value! tmp_rhs

		; Do it the hard way by subtraction. Is the difference zero?
		difference: declare red-money!
		difference: subtract-money tmp_lhs tmp_rhs

		print-line ["equal-money difference exponent: " difference/exponent " coefficient: " difference/exponent " value: " difference/value]
		
		if any [difference/exponent = NAN difference/coefficient <> 0][

			print-line ["eq nan | <> 0"]
			return 1
		]

		return 0
	]

	less-money: func [
		; Compare two dec64 numbers. If either argument is any nan, then the result is
		; nan. If the first is less than the second, return -1, otherwise return 1.
		lhs 	[red-money!]
		rhs 	[red-money!]
		return: [integer!]
			/local
				difference [red-money!]
				tmp_lhs    [red-money!]
				tmp_rhs    [red-money!]
				a       [integer!]
				b       [integer!]
	]
	[
		#if debug? = yes [if verbose > 0 [print-line "money/equal-money"]]
	
		if any [lhs/exponent = NAN rhs/exponent = NAN][
			return 1
		]

		; If the exponents are the same, or the coefficient signs are different, then
		; do a simple compare.
		either any [lhs/exponent = rhs/exponent lhs/value xor rhs/value < 0][
			if lhs/coefficient < rhs/coefficient [
				return -1
			]
		]
		[	
			; save the original value, as subract-money will change lhs/rhs.
			tmp_lhs: declare red-money!
			copy-cell as red-value! lhs as red-value! tmp_lhs
			tmp_rhs: declare red-money!
			copy-cell as red-value! rhs as red-value! tmp_rhs

			difference: declare red-money!
			
			print-line ["less-money subtract lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
			print-line ["                    rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]
			print-line ["                tmp_lhs coefficient: " tmp_lhs/coefficient " exponent: " tmp_lhs/exponent " value: " tmp_lhs/value]
			print-line ["                tmp_rhs coefficient: " tmp_rhs/coefficient " exponent: " tmp_rhs/exponent " value: " tmp_rhs/value]

			; Do it the hard way by subtraction. Is the difference zero?
			difference: subtract-money tmp_lhs tmp_rhs

			print-line ["less-money difference coefficient: " difference/coefficient " exponent: " difference/exponent " value: " difference/value]

			print-line ["less-money subtract lhs coefficient: " lhs/coefficient " exponent: " lhs/exponent " value: " lhs/value]
			print-line ["                    rhs coefficient: " rhs/coefficient " exponent: " rhs/exponent " value: " rhs/value]
			print-line ["                tmp_lhs coefficient: " tmp_lhs/coefficient " exponent: " tmp_lhs/exponent " value: " tmp_lhs/value]
			print-line ["                tmp_rhs coefficient: " tmp_rhs/coefficient " exponent: " tmp_rhs/exponent " value: " tmp_rhs/value]

			if all [difference/exponent <> NAN difference/coefficient < 0][
				print-line ["eq <> nan & < 0"]
				return -1
			]
		]

		return 1
	]

	do-math-op: func [
		lhs		[red-money!]
		rhs		[red-money!]
		type	[integer!]
		return: [red-money!]
	][
		switch type [
			OP_ADD [
				return add-money lhs rhs
			]							
			OP_SUB [
				return subtract-money lhs rhs
			]
			OP_MUL [
				return multiply-money lhs rhs
			]
			OP_DIV [
				return divide-money lhs rhs
			]
			default [
				fire [TO_ERROR(script cannot-use) stack/get-call datatype/push TYPE_MONEY]
		
				lhs
			]
		]
		lhs
	]

	do-math: func [
		op			[math-op!]
		return:		[red-money!]
		/local
			lhs			[red-money!]
			rhs			[red-money!]
			type-lhs 	[integer!]
			type-rhs 	[integer!]
			word		[red-word!]			
			size		[integer!]
			n			[integer!]
			v			[integer!]
			tp			[byte-ptr!]
			int 		[red-integer!]			
			int-value	[integer!]			
			value		[red-value!]
			tmp			[red-value!]
	][
		lhs: as red-money! stack/arguments
		rhs: as red-money! lhs + 1

		type-lhs: TYPE_OF(lhs)
		type-rhs: TYPE_OF(rhs)
		
		; allowed types for the right value
		assert any [
			type-rhs = TYPE_INTEGER
			type-rhs = TYPE_FLOAT
			type-rhs = TYPE_MONEY
		]
		
		switch type-rhs [
			TYPE_INTEGER [
				print-line ["integer"]
				value: as red-value! rhs
				value/header: TYPE_INTEGER				
				rhs: to rhs value TYPE_INTEGER
				lhs: do-math-op lhs rhs op

				return lhs
			]
			TYPE_FLOAT [
				value: as red-value! rhs
				value/header: TYPE_FLOAT
				rhs: to rhs value TYPE_FLOAT
				lhs: do-math-op lhs rhs op

				return lhs
			]
			TYPE_MONEY [
				switch type-lhs [
					TYPE_INTEGER [
						int: as red-integer! lhs

						; cast to the money type and set values accordingly to the money! spec
						lhs/header: TYPE_MONEY				
						lhs/coefficient: int/value			
						lhs/exponent: 0
						lhs: do-math-op lhs rhs op

						return lhs
					]	
					TYPE_MONEY [
						lhs: do-math-op lhs rhs op

						return lhs
					]

					default [
						fire [TO_ERROR(script invalid-type) datatype/push type-lhs]
					]
				]	
			]		
			default [
				fire [TO_ERROR(script invalid-type) datatype/push type-rhs]
			]
		]
		lhs	
	]

	get-rs-float: func [
		val		[red-float!]
		return: [float!]
		/local
			int [red-integer!]
	][
		switch TYPE_OF(val) [
			TYPE_INTEGER [
				int: as red-integer! val
				as float! int/value
			]
			TYPE_FLOAT [val/value]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_FLOAT val]
				0.0
			]
		]
	]

	from-block: func [
		blk		[red-block!]
		return: [float!]
		/local
			coefficient	[red-float!]
			exponent	[integer!]
			value		[float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/from-block"]]

		coefficient: as red-float! block/rs-head blk 		; get first value from the block: coefficient
															; (by using the head pointer of the block)
		exponent: as-integer get-rs-float coefficient + 1 	; get second value from the block: exponent
															; (by increasing the head pointer by the size of a red-float! struct)
		
		value: coefficient/value * SHIFT_MULTIPLY 			; shift the coefficient into place
		value: value + exponent								; add the exponent to the lower 8 bits
		
		value
	]

	format: func [
		value 	[red-money!]
		return: [c-string!]
		/local
			coefficient		[integer!]
			exponent		[integer!]
			formed 			[c-string!]
			power-of-ten	[integer!]
			sign 			[c-string!]
			integral-part	[integer!]
			fractional-part	[integer!]
	]
	[
		formed: "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" ;-- 32 bytes wide, big enough.
		sign: ""

		coefficient: value/coefficient
		exponent: value/exponent
		
		print-line ["format: coefficient: " coefficient " exponent: " exponent " value: " value/value]

		; absolute value of coefficient		
		if coefficient < 0 [sign: "-" coefficient: (not coefficient) + 1]

		; positive exponents are appended zeros to the coefficient
		; negative exponents are appending zeros to 0,
		case [
			exponent = 0 [sprintf [formed "%s$%d.00" sign coefficient]]
			exponent > 0 [
				sprintf [formed "%s$%d%0*d.00" sign coefficient exponent 0]
			]
			true [
				exponent: (exponent * -1) + 1
				power-of-ten: powers/exponent
				integral-part: coefficient / power-of-ten

				either integral-part = 0 [
					sprintf [formed "%s$0.%0*d" sign exponent - 1 coefficient]		
				]
				[
					fractional-part: coefficient - (integral-part * power-of-ten)					
					sprintf [formed "%s$%d.%0*d" sign integral-part exponent - 1 fractional-part]					
				]		
			]
		]

		formed
	]

	msb-DeBruijn-32: func [
		value	[byte-ptr!]
		return:	[integer!]
		/local
			index							[integer!]
			multiply-DeBruijn-Bit-Position 	[int-ptr!]
	][

		multiply-DeBruijn-Bit-Position: [0 9 1 10 13 21 2 29 11 14 16 18 22 25 3 30 8 12 20 28 15 17 24 7 19 27 23 6 26 5 4 31]

		index: as integer! value
		index: index or (index >>> 1)
		index: index or (index >>> 2)
		index: index or (index >>> 4)
		index: index or (index >>> 8)
		index: index or (index >>> 16)
		index: index * 07C4ACDDh >>> 27 + 1
		
		multiply-DeBruijn-Bit-Position/index
	]

	;-- Actions --
    make: func [
		proto	[red-money!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-money!]
		/local
			bool  		[red-logic!]
			int 		[red-integer!]
			coefficient [integer!]
			exponent 	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/make"]]

        ; cast the source spec accordingly to money!
		switch TYPE_OF(spec) [
			TYPE_INTEGER
			TYPE_CHAR [
				int: as red-integer! spec			
				coefficient: int/value
				exponent: 0
			]			
            default [print-line ["fire"] fire [TO_ERROR(script bad-to-arg) datatype/push type spec] print-line ["after fire"]]
        ]

		; move coefficient and exponent in position
		proto/value: coefficient << COEFFICIENT_SHIFT

		; money/value: money/value or exponent
		proto/value: proto/value or exponent
        proto
	]

    to: func [
		proto	[red-money!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-money!]
		/local
			bool 		[red-logic!]
			money		[red-money!]
			float		[red-float!]
			value		[red-value!]
			int   		[red-integer!]
			blk			[red-block!]
			decimals	[integer!]
			factor		[integer!]
			coefficient [integer!]
			exponent 	[integer!]
			error		[integer!]
			length	 	[integer!]
			string  	[red-string!]
			formed		[c-string!]
			series	 	[series!]
			pointer	 	[byte-ptr!]
			unit 		[integer!]
			fl			[red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/to"]]

		if TYPE_OF(spec) = TYPE_MONEY [return as red-money! spec] ; type cast to red-money!

		proto/header: type

		switch TYPE_OF(spec) [
			TYPE_CHAR [
				print-line ["char"]
				proto/coefficient: spec/data2
				proto/exponent: 0
				proto: pack proto
			]
			TYPE_INTEGER [
				print-line ["integer"]
				int: as red-integer! spec

				comment {
				either overflow? int/value [
					print-line ["overflow in set"]
					proto: generate-nan
					return proto			
				]
				[
					proto/coefficient: int/value
					proto/exponent: 0
					proto/value: proto/coefficient << COEFFICIENT_SHIFT
				]
				}

				proto/coefficient: int/value
				proto/exponent: 0
				
				print-line ["before convert: coefficient " proto/coefficient " exponent: " proto/exponent " value: " proto/value]

				proto: convert proto

				print-line ["after convert: coefficient " proto/coefficient " exponent: " proto/exponent " value: " proto/value]
				proto: pack proto	
			]			
			TYPE_FLOAT [
				print-line ["float"]
				error: 0				
				value: as red-value! spec
				float: as red-float! spec
				string: as red-string! spec

				formed: "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" ;-- 32 bytes wide, big enough.
				sprintf [formed "%f" float/value]

				print-line ["formed: " formed]
				
				; formed: red/float/form-float float/value red/float/FORM_FLOAT_32

				; print-line ["formed: " formed]
				
				decimals: GET_SIZE_FROM(spec)

				print-line ["decimals GSF: " decimals]

				; fl: as red-float! spec
				; decimals: as-integer fl/value
				; print-line ["decimals as-int: " decimals]

				; print-line ["decimals size: " size? formed]
				; decimals: size? formed
				
				; fl: as red-float! spec
				; print-line ["fl: " fl/value " " as-integer fl/value]
				
				; red/string/concatenate-literal string formed

				; string: red/string/load formed decimals UTF-8

				; print-line ["string: " string]

				; print-line ["spec: " spec " type: " type]
				; print-line ["float: " float/value]
				; string: as red-string! spec

				; string: red/string/to spec spec TYPE_FLOAT

				; string: red/string/make string spec TYPE_FLOAT

				;string: red/string/to value spec TYPE_FLOAT
				;string: red/string/make string value TYPE_FLOAT

				; print-line ["string"]

				print-line ["size: " size? formed]

				string: red/string/rs-load formed size? formed UTF-8
				series: GET_BUFFER(string)

				print-line ["series: " series]

				unit: GET_UNIT(series)
				print-line ["unit: " unit]
				pointer: (as byte-ptr! series/offset) + (string/head << log-b unit)
				print-line ["pointer: " pointer]
				length: (as-integer series/tail - pointer) >> log-b unit
				
				print-line ["length: " length]
								
				either length > 0 [
					; print-line ["calling tokenizer: pointer: " pointer " length: " length " unit: " unit]
					proto: tokenizer/scan-money pointer length unit proto :error
					error: 0
					; print-line ["returned from call"]
					; print-line ["coefficient: " proto/coefficient " exponent: " proto/exponent " value: " proto/value]

				][error: -1]

				if error <> 0 [fire [TO_ERROR(script bad-to-arg) datatype/push type spec]]

				; print-line ["exit from switch"]

				comment {
				float: as red-float! spec
				int: as red-integer! spec
				int/value: as integer! float/value

				either overflow? int/value [
					print-line ["overflow in set"]
					proto/coefficient: 0
					proto/exponent: -128
					proto/value: 0
					return proto
				]
				[
					factor: 1
					decimals: 0

					value: float/value
					;int: as red-integer! spec
					;int/value: as integer! float/value
					int: declare red-integer!
					int/value: as integer! float/value

					; print-line ["int: " int/value]
					; print-line ["float: " value]

					while [all [factor < 10000000 (as float! int/value) <> value]] [
						factor: factor * 10
						decimals: decimals + 1				
						
						value: float/value * factor
						int/value: as integer! value

						if overflow? int/value [
							print-line ["overflow in while"]
							proto/coefficient: 0
							proto/exponent: -128
							proto/value: 0

							return proto
						]			

						print-line ["factor: " factor " decimals: " decimals " value: " value " int/value: " int/value]			
					]				

					proto/coefficient: int/value

					; fractional values have a negative exponent
					proto/exponent: decimals * -1
				]

				print-line ["pack with coefficient: " proto/coefficient " exponent: " proto/exponent " value: " proto/value]
				proto: pack proto
				}
			]
			TYPE_ANY_STRING [
				print-line ["string"]
				error: 0
				string: as red-string! spec
				series: GET_BUFFER(string)
				unit: GET_UNIT(series)
				pointer: (as byte-ptr! series/offset) + (string/head << log-b unit)
				length: (as-integer series/tail - pointer) >> log-b unit
				
				; print-line ["length: " length]

				either length > 0 [
					; print-line ["calling tokenizer: pointer: " pointer " length: " length " unit: " unit]
					proto: tokenizer/scan-money pointer length unit proto :error
					error: 0
					; print-line ["returned from call"]
					; print-line ["coefficient: " proto/coefficient " exponent: " proto/exponent " value: " proto/value]

				][error: -1]

				if error <> 0 [fire [TO_ERROR(script bad-to-arg) datatype/push type spec]]

				; print-line ["exit from switch"]
			]
			TYPE_ANY_LIST [
				print-line ["list"]
				; a DEC64 consists of two values: coefficient and exponent
				if 2 <> block/rs-length? as red-block! spec [
					fire [TO_ERROR(script bad-to-arg) datatype/push type spec]
				]

				blk: as red-block! spec
				int: as red-integer! block/rs-head blk				; get first value from the block: coefficient
																	; (by using the head pointer of the block)
				proto/coefficient: int/value						
				; if we overflow, we cannot scale the coefficient, as it's outside of the integer range
				if overflow? proto/coefficient[
					print-line "overflowed"

					proto: generate-nan proto
					
					return proto
				]

				int: int + 1
				proto/exponent: int/value							; get second value from the block: exponent
																	; (by increasing the head pointer by the size of a red-integer! struct)
				if proto/coefficient = 0 [
					proto/exponent: 0
				]

				print-line ["before convert: coefficient " proto/coefficient " exponent: " proto/exponent " value: " proto/value]

				proto: convert proto

				print-line ["after convert: coefficient " proto/coefficient " exponent: " proto/exponent " value: " proto/value]
				proto: pack proto				
			]

			default [
				; print-line ["default"]
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_MONEY spec]
			]
		]

		; print-line ["return proto"]
		; print-line ["coefficient: " proto/coefficient " exponent: " proto/exponent " value: " proto/value]
        proto
	]

    form: func [
		money	   [red-money!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			formed 		[c-string!]
			coefficient [integer!]
			exponent 	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/form"]]
		
		print-line ["money/form"]

		; sign extend the exponent
		either money/exponent = NAN [
			formed: "NAN"	
		]
		[
			print-line ["money/coefficient: " money/coefficient " money/exponent: " money/exponent " money/value: " money/value]
	
			formed: format money
		]

		string/concatenate-literal buffer formed
		part - length? formed							;@@ optimize by removing length?
	]

	mold: func [
		money	[red-money!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			formed 		[c-string!]
			coefficient [integer!]
			exponent 	[integer!]
			sign 		[c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/mold"]]
		
		print-line ["money/mold"]
		form money buffer arg part
	]

	init: does [
		#if debug? = yes [print-line "debug yes"]
		
		datatype/register [
			TYPE_MONEY
			TYPE_VALUE
			"money!"
			;-- General actions --
			null
			null
			null		;reflect
			:to; :to
			:form ;:form; :form
			:mold ;:form
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			null
			null
			null
			:sub
			null
			null
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]