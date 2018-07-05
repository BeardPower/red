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
#define ULTIMATE_COEFFICIENT 838860700

; 64-bit
; #define MIN_COEFFICIENT -3.6028797018963968E16 ; FF800000000000000000000000000000h
; #define MAX_COEFFICIENT  3.6028797018963967E16 ; 0000000000000000007FFFFFFFFFFFFFh

#define MIN_EXPONENT FFFFFF81h 	; -127
#define MAX_EXPONENT 0000007Fh 	;  127

#define NAN FFFFFF80h 			; -128
#define EXPONENT_MASK FFh 		;  255
#define COEFFICIENT_SHIFT 08h	;  8
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
		1000000000				; 9
		; 32-bit limit 8388608			
		; 10000000000			; 10
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
		fl		[red-float!]
		return: [logic!]
	][
		any [fl/value > 2147483647.0 fl/value < -2147483648.0]
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
		print-line ["money/box " verbose]
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
		
		print-line ["money/push " verbose]

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
		value/exponent: value/exponent - 1

		print-line ["coefficient: " value/coefficient " exponent: " value/exponent]

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

		print-line ["money/pack-increase"]

		diff: diff + 1 ; TODO: look into a way to dynamically calculate the offset
		power-of-ten: powers/diff ; powers of two start with 0, so we have to add 1 to get the correct index into powers

		; restiore original value
		diff: diff - 1
		print-line ["power of ten: " power-of-ten " difference: " diff]

		; if the difference is more than 10, the result is zero (rare)
		if diff > 10 [
			print-line ["diff > 10 " diff]
			value/coefficient: 0
			value/exponent: 0
			return value
		]

		; sign the power of 10 according to the sign of the coefficient
		if value/coefficient < 0 [power-of-ten: power-of-ten * -1]

		; rounding fudge
		half-power-of-ten: power-of-ten / 2

		print-line ["half-power-of-ten: " half-power-of-ten]
		
		; add the rounding fudge
		value/coefficient: value/coefficient + half-power-of-ten

		print-line ["coefficient: " value/coefficient]

		; divide by the power of ten
		value/coefficient: value/coefficient / power-of-ten

		print-line ["coefficient / power: " value/coefficient]
		
		; increase the exponent by the difference
		value/exponent: value/exponent + diff

		print-line ["exponent: " value/exponent]

		value
	]	

	comment {
	; The slow path is taken if the two operands do not both have zero exponents.
	add-slow: func [
		lhs 	[red-money!]
		rhs		[red-money!]
		return:	[red-money!]
	][
		; Any of the exponents is nan
		either any [lhs/exponent = 128 rhs/exponent = 128][
			lhs/coefficient: 0
			lhs/exponent: NAN
			return lhs
		]
		[			
			; Are the two exponents the same? This will happen often, especially with
			; money values.
			either lhs/exponent = rhs/exponent [

				; The exponents match so we may add now. Zero out the exponents so there
				; will be no carry into the coefficients when the coefficients are added.
				; If the result is zero, then return the normal zero.
				lhs/coefficient: lhs/coefficient + rhs/coefficient

				; check overflow
    			either system/cpu/overflow? [
					print-line ["add overflow"]
					lhs/coefficient: lhs/coefficient / 2
				][
					; if the coefficient is zero, the exponent is zero
					if lhs/coefficient = 0 [lhs/exponent: 0]
				]
			]
			; The slower path is taken when neither operand is nan, and their
			; exponents are different. Before addition can take place, the exponents
			; must be made to match. Swap the numbers if the second exponent is greater
			; than the first.
		]				

		lhs
	]
	}

	comment {
	; The slower path is taken when neither operand is nan, and their
	; exponents are different. Before addition can take place, the exponents
	; must be made to match. Swap the numbers if the second exponent is greater
	; than the first.
	add-slower: func [
		value-left 	[float!]
		value-right	[float!]
		return:	[float!]
		/local
			exponent-left 		[integer!]
			exponent-right 		[integer!]
			coefficient-left 	[float!]
			coefficient-right 	[float!]
			difference			[integer!]
			power-of-ten		[float!]
			temp				[float!]
	][		
		exponent-left: as integer! value-left and EXPONENT_MASK
		exponent-right: as integer! value-right and EXPONENT_MASK
		coefficient-left: value-left / SHIFT_MULTIPLY
		coefficient-right: value-right / SHIFT_MULTIPLY

		; swap
		if exponent-right > exponent-left [
			tmp: exponent-left
			exponent-left: exponent-right
			exponent-right: exponent-left
		]

		; prepare the first coefficient
		value-left: coefficient-left

		; add slower decrease
		; The coefficients are not the same. Before we can add, they must be the same.
		; We will try to decrease the first exponent. When we decrease the exponent
		; by 1, we must also multiply the coefficient by 10. We can do this as long as
		; there is no overflow. We have 8 extra bits to work with, so we can do this
		; at least twice, possibly more.
		until [
			value-left: value-left * 10.0
			; check on overflow
			exponent-left: exponent-left - 1
		
			exponent-left <> exponent-right
		]
		
		value-left: value-left + coefficient-right

		; pack

		; slower increase
		; We cannot decrease the first exponent any more, so we must instead try to
		; increase the second exponent, which will result in a loss of significance.
		; That is the heartbreak of floating point.

		; Determine how many places need to be shifted. If it is more than 17, there is
		; nothing more to add.

		difference: exponent-left - exponent-right
		either difference > 17 [
			return value-left
		][
			power-of-ten: powers/difference
			coefficient-right: coefficient-right / power-of-ten
			either coefficient-right = 0 [
				return value-left
			][
				value-left: coefficient-left + coefficient-right

				; pack
			]
		]

	]
	}

	; the exponent is too big, so it's attempted to scale it back by decreasing the exponent of the DEC64 value
	; this can salvage values in a small set of cases, because the decimal values are decreased
	pack-decrease: func [
		value 		[red-money!]
		return:		[red-money!]
		/local
			carry	[integer!]
	][		
		#if debug? = yes [if verbose > 0 [print-line "money/pack-decrease"]]

		print-line ["money/pack-decrease"]

		; decrease the exponent until it is smaller than MAX_EXPONENT
		while [value/exponent > MAX_EXPONENT][
			; multiply the coefficient by 10			
			value/coefficient: value/coefficient * 10	

			; if we overflow, we failed to salvage and bail out early
			if system/cpu/overflow? [
				print-line ["overflow pack-decrease; bail out with NAN"]

				value/coefficient: 0
				value/exponent: NAN

				value/value: value/coefficient << COEFFICIENT_SHIFT	; shift the coefficient into place
				value/value: value/value or value/exponent		; add the exponent value

				return value
			]

			print-line ["new coefficient: " value/coefficient]
			print-line ["new exponent: " value/exponent - 1]		

			; decrease the exponent
			value/exponent: value/exponent - 1		
		]
	
		carry: value/coefficient >> 24
		carry: carry + 0

		either carry <> 0 [
			print-line ["carry > 0; number is still to big; bail out with NAN"]
			fire [TO_ERROR(math overflow)]

			value/coefficient: 0
			value/exponent: NAN			
		][
			; if the coefficient is zero, also zero out the exponent
			if value/coefficient = 0 [value/exponent: 0]
		]
		
		value/value: value/coefficient << COEFFICIENT_SHIFT	; shift the coefficient into place
		value/value: value/value or value/exponent			; add the exponent value		
		
		print-line ["return value: " value]
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
	][		
		; the value is packed, as long as there it is not a number
		; if there is some valid packing found, the loop is bailed out early
		until [
			; If the exponent is greater than 127, then the number is too big and we bail out early.
			; But it might still be possible to salvage a value.
			if value/exponent > 127 [
				print-line ["exponent > 127: " value/exponent " call pack-decrease"]
				return pack-decrease value
			]

			; If the exponent is too small, or if the coefficient is too large, then some
			; division is necessary. The absolute value of the coefficient is off by one
			; for the negative because
			;    negative_extreme_coefficent = -(extreme_coefficent + 1)

			diff_coefficient: 0
			diff_exponent: 0

			; the difference in digits between 32-bit values and 24-bit values is 3, so we can safely multiply by 100 tp get the maximum
			; max-coefficient 			= 8388607
			; max-coefficient * 100 	= 838860700
			; max-coefficient * 10 - 1  = 83886069
			; max-coefficient - 1		= 8388606

			; work with absolute value
			if value/coefficient < 0 [value/coefficient: value/coefficient * -1]

			either value/coefficient > 838860700 [
				print-line ["coefficient > 838860700 pack-large: " value/coefficient " " value/exponent]
				value: pack-large value

				; the loop is started over
			][
				if value/coefficient > 8388606 [
					print-line ["coefficient > 8388606 increase diff_coefficient: " diff_coefficient]
					diff_coefficient: diff_coefficient + 1
				]

				diff_exponent: MIN_EXPONENT - value/exponent
				print-line ["diff_exponent: " diff_exponent]
				print-line ["diff_coefficient: " diff_coefficient]

				if value/coefficient > 83886069 [
					print-line ["coefficient > 83886069 increase diff_coefficient: " diff_coefficient]
					diff_coefficient: diff_coefficient + 1
				]

				; check, which access is larger
				diff_coefficient: either diff_coefficient > diff_exponent [diff_coefficient][diff_exponent]

				either diff_coefficient > 0 [
					print-line ["diff_coefficient: " diff_coefficient " diff_exponent: " diff_exponent]
					print-line ["diff_coefficient > 0 pack-increase: " value/coefficient " " value/exponent]
					value: pack-increase value diff_coefficient

					; the loop is started over
				]
				[			
					; if the coefficient is zero, also zero the exp
					if value/coefficient = 0 [
						print-line ["coefficient = 0, set exponent to 0"]
						value/exponent: 0
					]
				]

			]
			
			; we bail out, if the number is zero or not a number
			any [value/coefficient <> 0 value/exponent <> NAN]
		]

		print-line ["preparing value: " value/coefficient " " value/exponent]

		; shift the coefficient into position
		value/value: value/coefficient << COEFFICIENT_SHIFT

		print-line ["value after <<: " value/value]

		; mix in the exponent
		value/exponent: value/exponent and EXPONENT_MASK
		value/value: value/value or value/exponent

		print-line ["final return value from pack: " value/value]

		value
	]

	convert: func [
		value	[red-money!]
		return:	[red-money!]
		
	][
		; shift the coefficient into position
		value/value: value/coefficient << COEFFICIENT_SHIFT

		; mix in the exponent
		value/exponent: value/exponent and EXPONENT_MASK
		value/value: value/value or value/exponent
		value
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/add"]]

		print-line ["adding two money!"]
		as red-value! do-math OP_ADD
	]
	
	add-money: func [
		lhs		[red-money!]
		rhs		[red-money!]
		return: [red-money!]
		/local
			diff 			[integer!]
			power-of-ten 	[integer!]
			tmp				[integer!]

	][
		; fast path: coefficients can be added, if the exponents are both zero
		either all [lhs/exponent = 0 rhs/exponent = 0][
			print-line ["fast path add: " lhs/coefficient " " lhs/exponent " " rhs/coefficient " " rhs/exponent]	
			lhs/coefficient: lhs/coefficient + rhs/coefficient

			print-line ["lhs/coefficient: " lhs/coefficient]	

			; check overflow
			either system/cpu/overflow? [
				; If there was an overflow (extremely unlikely) then we must make it fit.
				; pack knows how to do that.
				lhs/coefficient: lhs/coefficient / 2

				print-line ["overflow in fast add; call pack with: " lhs/coefficient " " lhs/exponent]

				return pack lhs
			][
				return convert lhs
			]
		][					
			; The slow path is taken if the two operands do not both have zero exponents.
			print-line ["slow path add: " lhs/exponent " " rhs/exponent]

			; Any of the exponents is nan
			either any [lhs/exponent = -128 rhs/exponent = -128][
				lhs/coefficient: 0
				lhs/exponent: NAN
				return lhs
			]
			[			
				; Are the two exponents the same? This will happen often, especially with
				; money values.
				either lhs/exponent = rhs/exponent [

					; The exponents match so we may add now. Zero out the exponents so there
					; will be no carry into the coefficients when the coefficients are added.
					; If the result is zero, then return the normal zero.
					lhs/coefficient: lhs/coefficient + rhs/coefficient

					; check overflow
					either system/cpu/overflow? [
						; If there was an overflow (extremely unlikely) then we must make it fit.
						; pack knows how to do that.
						lhs/coefficient: lhs/coefficient / 2

						print-line ["overflow in equal; call pack with: " lhs/coefficient " " lhs/exponent]

						return pack lhs

					][
						; if the coefficient is zero, the exponent is zero
						if lhs/coefficient = 0 [lhs/exponent: 0]

						return lhs
					]
				][
					; The slower path is taken when neither operand is nan, and their
					; exponents are different. Before addition can take place, the exponents
					; must be made to match. Swap the numbers if the second exponent is greater
					; than the first.

					; swap
					if rhs/exponent > lhs/exponent [
						print-line ["switch exponents rhs lhs " rhs/exponent " > " lhs/exponent]
						tmp: lhs/exponent
						lhs/exponent: rhs/exponent
						rhs/exponent: tmp

						tmp: lhs/coefficient
						lhs/coefficient: rhs/coefficient
						rhs/coefficient: tmp

						print-line ["switched coefficient exponents rhs lhs: " rhs/coefficient " " rhs/exponent " " lhs/coefficient " " lhs/exponent]
					]

					; add slower decrease
					; The coefficients are not the same. Before we can add, they must be the same.
					; We will try to decrease the first exponent. When we decrease the exponent
					; by 1, we must also multiply the coefficient by 10. We can do this as long as
					; there is no overflow. We have 8 extra bits to work with, so we can do this
					; at least twice, possibly more.
					until [
						lhs/coefficient: lhs/coefficient * 10

						; check on overflow
						if system/cpu/overflow? [
							print-line ["add slower overflow"]
							print-line ["add slower increase"]

							; add slower increase
							; We cannot decrease the first exponent any more, so we must instead try to
							; increase the second exponent, which will result in a loss of significance.
							; That is the heartbreak of floating point.

							; Determine how many places need to be shifted. If it is more than 7, there is
							; nothing more to add.

							diff: lhs/exponent - rhs/exponent
							either diff > 7 [
								; too small to matter
								; return the original number
								return lhs
							][
								power-of-ten: powers/diff
								rhs/coefficient: rhs/coefficient / power-of-ten
								either rhs/coefficient = 0 [
									; too insignificant to add
									; return the original number
									return lhs
								][
									lhs/coefficient: lhs/coefficient + rhs/coefficient
									print-line ["call pack from add-slower-increase"]
									return pack lhs
								]
							]
						]
						
						lhs/exponent: lhs/exponent - 1								
						print-line ["add slower exponent: " lhs/exponent]

						lhs/exponent = rhs/exponent
					]
					
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

	][
		; This is the same as dec64_add, except that the operand in r2 has its
		; coefficient complemented first.

		rhs/coefficient: rhs/coefficient
		rhs/coefficient: rhs/coefficient + 256

		;if there is no overflow, begin the beguine
		either not system/cpu/overflow? [
			print-line ["no overflow in sub; call add"]

			return add-money lhs rhs
		][
			; The subtrahend coefficient is -8388608. This value cannot easily be
			; complemented, so take the slower path. This should be extremely rare.
		
			either any [lhs/exponent = 128 rhs/exponent = 128][
				lhs/coefficient: 0
				lhs/exponent: 128

				return lhs
			]
			[
				; swap
				if rhs/exponent > lhs/exponent [
					print-line ["switch exponents rhs lhs " rhs/exponent " > " lhs/exponent]
					tmp: lhs/exponent
					lhs/exponent: rhs/exponent
					rhs/exponent: tmp

					print-line ["switched exponents rhs lhs: " rhs/exponent " " lhs/exponent]
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
						print-line ["sub slower overflow"]
						print-line ["sub slower increase"]

						; sub slower increase
						; We cannot decrease the first exponent any more, so we must instead try to
						; increase the second exponent, which will result in a loss of significance.
						; That is the heartbreak of floating point.

						; Determine how many places need to be shifted. If it is more than 7, there is
						; nothing more to add.

						diff: lhs/exponent - rhs/exponent
						either diff > 7 [
							print-line ["subtract_underflow; call pack"]
							; too small to matter
							; call pack with the oritinal number
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

	][
		return lhs
	]

	divide-money: func [
		lhs		[red-money!]
		rhs		[red-money!]
		return: [red-money!]
		/local
			diff 			[integer!]
			power-of-ten 	[integer!]
			tmp				[integer!]

	][
		return lhs
	]

	do-math-op: func [
		lhs		[red-money!]
		rhs		[red-money!]
		type	[integer!]
		return: [red-money!]
	][
		print-line ["opping two money!"]
		print-line ["coefficient-left: " lhs/coefficient]
		print-line ["exponent-left: " lhs/exponent]
		print-line ["coefficient-right: " rhs/coefficient]
		print-line ["exponent-right: " rhs/exponent]

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
			value		[integer!]
			size		[integer!]
			n			[integer!]
			v			[integer!]
			tp			[byte-ptr!]
			coefficient [red-integer!]
			int 		[red-integer!]
	][
		lhs: as red-money! stack/arguments
		rhs: as red-money! lhs + 1

		type-lhs: TYPE_OF(lhs)
		type-rhs: TYPE_OF(rhs)
		
		; allowed types for the right value
		assert any [
			type-rhs = TYPE_INTEGER
			type-rhs = TYPE_MONEY
		]
		
		switch type-rhs [
			TYPE_INTEGER [
				print-line ["type-right == TYPE_INTEGER"]

				int: as red-integer! rhs
				print-line ["rhs/value: " int/value]

				; cast to the money type and set values accordingly to the money! spec
				rhs/header: TYPE_MONEY				
				rhs/coefficient: int/value			
				rhs/exponent: 0
	
				print-line ["adding " lhs/coefficient "E" lhs/exponent " and " rhs/coefficient "E" rhs/exponent]

				lhs: do-math-op lhs rhs op
				return lhs
			]
			TYPE_MONEY [
				switch type-lhs [
					TYPE_INTEGER [
						print-line ["type-left == TYPE_INTEGER"]

						int: as red-integer! lhs
						print-line ["lhs/value: " int/value]

						; cast to the money type and set values accordingly to the money! spec
						lhs/header: TYPE_MONEY				
						lhs/coefficient: int/value			
						lhs/exponent: 0
			
						print-line ["adding " lhs/coefficient "E" lhs/exponent " and " rhs/coefficient "E" rhs/exponent]

						lhs: do-math-op lhs rhs op

						return lhs
					]	
					TYPE_MONEY [
						print-line ["both sides == TYPE_MONEY"]

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
		
		print-line ["money/from-block: coefficient: " coefficient/value " exponent: " exponent " value: " value]

		value
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
		; print-line ["money/make " verbose]

		#if debug? = yes [if verbose > 0 [print-line "money/make"]]

		;either TYPE_OF(spec) = TYPE_LOGIC [
		;	bool: as red-logic! spec
		;	money: as red-money! proto
		;	money/header: TYPE_MONEY
		;	money/value: as-money bool/value
		;	money
		;][
		;as red-money!; to proto spec type
		;]

		; print-line ["header is set to " TYPE_MONEY]

		; print-line ["data1: " spec/data1 " data2: " spec/data2 " data3: " spec/data3]

		; money/coefficient: as-integer spec/data2
		; money/exponent: as-integer spec/data3

		; print-line ["switch"]
		; print-line ["money/value: " money/value]
		; print-line ["proto/value: " proto/value]

        ; cast the source spec accordingly to money!
		switch TYPE_OF(spec) [
			TYPE_INTEGER
			TYPE_CHAR [
				print-line ["in switch"]
				int: as red-integer! spec			
				coefficient: int/value
				exponent: 0

				print-line ["after setting"]
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
			bool 			[red-logic!]
			money			[red-money!]
			float 			[red-float!]			
			int   			[red-integer!]
			value			[float!]
			blk				[red-block!]
			values 			[struct! [coefficient [integer!] exponent[integer!]]]
	][
		; print-line ["money/to verbosity: " verbose]

		#if debug? = yes [if verbose > 0 [print-line "money/to"]]

		if TYPE_OF(spec) = TYPE_MONEY [return as red-money! spec] ; type cast to red-money!

		;print-line ["type of spec: " TYPE_OF(spec)]

		;print-line ["coefficient: " proto/coefficient "exponent: " proto/exponent]

		print-line ["type: " TYPE_OF(spec) " " spec/data1 " " spec/data2 " " spec/data3]

		proto/header: type

		switch TYPE_OF(spec) [
			TYPE_CHAR [
				proto/value: spec/data2

				print-line ["from char"]
			]
			TYPE_INTEGER [
				print-line ["from integer"]

				int: as red-integer! spec		

				print-line ["value: " int/value]

				proto/coefficient: int/value
				proto/exponent: 0
				proto: convert proto			
			]			
			TYPE_FLOAT [
				print-line ["from float"]
				float: as red-float! spec

				proto/coefficient: as integer! float/value
				proto/exponent: 0
				proto: convert proto			
			]
			TYPE_ANY_LIST [
				; a DEC64 consists of two values: coefficient and exponent
				if 2 <> block/rs-length? as red-block! spec [
					fire [TO_ERROR(script bad-to-arg) datatype/push type spec]
				]

				blk: as red-block! spec
				int: as red-integer! block/rs-head blk				; get first value from the block: coefficient
																	; (by using the head pointer of the block)
				proto/coefficient: int/value										
				int: int + 1
				proto/exponent: int/value 								; get second value from the block: exponent
																	; (by increasing the head pointer by the size of a red-integer! struct)

				print-line ["coefficient: " proto/coefficient " exponent: " proto/exponent]
				proto: pack proto

				print-line ["proto/value: " proto/value " " proto/coefficient " " proto/exponent]

				comment {
				print-line ["test-pack-increase"]

				values: declare struct! [coefficient [integer!] exponent[integer!]]

				values: pack-increase 500 3 2
				print-line ["values/coefficient: " values/coefficient " values/exponent: " values/exponent]

				print-line ["test-pack-large"]
				values: pack-large 500 3
				print-line ["values/coefficient: " values/coefficient " values/exponent: " values/exponent]
				}
				
				; early return, as the returned value has coefficient and exponent already in the correct place
				return proto
			]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_MONEY spec]]
		]

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
		print-line ["money/form " verbose]

		#if debug? = yes [if verbose > 0 [print-line "money/form"]]
		
		formed: "0000000000000000000000000000000"					;-- 32 bytes wide, big enough.

		coefficient: money/value
		coefficient: coefficient >> COEFFICIENT_SHIFT

		exponent: money/value

		; sign extend the exponent
		exponent: exponent << 24 >> 24

		sprintf [formed "%dE%d" coefficient exponent]
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
		print-line ["money/mold "]

		#if debug? = yes [if verbose > 0 [print-line "money/mold"]]
		
		formed: "0000000000000000000000000000000"					;-- 32 bytes wide, big enough.
		
		coefficient: money/value		
		print-line ["coefficient: " money/value]

		coefficient: coefficient >> 8
		print-line ["coefficient >> 8: " coefficient]

		exponent: money/value

		; sign extend the exponent
		exponent: exponent << 24 >> 24
		
		either exponent = -128 [
			formed: "NAN"	
		]
		[
			sprintf [formed "%dE%d" coefficient exponent]
		]
		
		string/concatenate-literal buffer formed
		part - length? formed							;@@ optimize by removing length?
	]

	init: does [
		#if debug? = yes [print-line "debug yes"]
		if verbose > 0 [print-line "verbose > 1"]

		print-line "money/init here"
		
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
			null
			;-- Scalar actions --
			null
			:add
			null
			null
			null
			null
			null
			null
			null
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

		print-line "money/after registering"
	]
]