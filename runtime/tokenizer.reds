Red/System [
	Title:   "Red values low-level tokenizer"
	Author:  "Nenad Rakocevic"
	File: 	 %tokenizer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tokenizer: context [

	scan-integer: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		error	[int-ptr!]
		return: [integer!]
		/local
			c	 [integer!]
			n	 [integer!]
			m	 [integer!]
			neg? [logic!]
	][
		neg?: no
		
		c: string/get-char p unit
		if any [
			c = as-integer #"+" 
			c = as-integer #"-"
		][
			neg?: c = as-integer #"-"
			p: p + unit
			len: len - 1
		]
		n: 0
		until [
			c: (string/get-char p unit) - #"0"
			either all [c <= 9 c >= 0][					;-- skip #"'"
				m: n * 10
				if system/cpu/overflow? [error/value: -2 return 0]
				n: m
				if all [neg? n = 2147483640 c = 8][return 80000000h] ;-- special exit trap for -2147483648
				m: n + c
				if system/cpu/overflow? [error/value: -2 return 0]
				n: m
			][
				c: c + #"0"
				case [
					c = as-integer #"." [break]
					c = as-integer #"'" [0]				;-- pass-thru
					true				[
						error/value: -1
						len: 1 							;-- force exit
					]
				]
			]
			p: p + unit
			len: len - 1
			zero? len
		]
		either neg? [0 - n][n]
	]

	scan-float: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		error	[int-ptr!]
		return: [float!]
		/local
			cp	 [integer!]
			tail [byte-ptr!]
			cur	 [byte-ptr!]
			s0	 [byte-ptr!]
	][
		cur: as byte-ptr! "0000000000000000000000000000000"		;-- 32 bytes including NUL
		tail: p + (len << (unit >> 1))

		if len > 31 [cur: as byte-ptr! system/stack/allocate (len + 1) >> 2 + 1]
		s0: cur

		until [											;-- convert to ascii string
			cp: string/get-char p unit
			if cp <> as-integer #"'" [					;-- skip #"'"
				if cp = as-integer #"," [cp: as-integer #"."]
				cur/1: as-byte cp
				cur: cur + 1
			]
			p: p + unit
			p = tail
		]
		cur/1: #"^@"									;-- replace the byte with null so to-float can use it as end of input
		string/to-float s0 len error
	]

	scan-tuple: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		error	[int-ptr!]
		slot	[red-value!]
		/local
			c	 [integer!]
			n	 [integer!]
			m	 [integer!]
			size [integer!]
			tp	 [byte-ptr!]
	][
		tp: (as byte-ptr! slot) + 4
		n: 0
		size: 0
		
		loop len [
			c: string/get-char p unit
			either c = as-integer #"." [
				size: size + 1
				if any [n < 0 n > 255 size > 12][error/value: -1 exit]
				tp/size: as byte! n
				n: 0
			][
				m: n * 10
				if system/cpu/overflow? [error/value: -1 exit]
				n: m
				m: n + c - #"0"
				if system/cpu/overflow? [error/value: -1 exit]
				n: m
			]
			p: p + unit
		]
		size: size + 1									;-- last number
		tp/size: as byte! n
		slot/header: TYPE_TUPLE or (size << 19)
	]

	scan-money: func [
		p		[byte-ptr!]
		len		[integer!]
		unit	[integer!]
		value	[red-money!]
		error	[int-ptr!]
		return: [red-money!]
		/local
			c		   [integer!]
			n	 	   [integer!]
			m	 	   [integer!]
			f	 	   [integer!]
			z          [integer!]
			tmp		   [integer!]
			leading?   [logic!]
			fractions? [logic!]
			neg? 	   [logic!]
			overflow?  [logic!]
	][
		leading?: yes
		fractions?: no
		neg?: no
		overflow?: no

		c: string/get-char p unit
		if any [
			c = as-integer #"+" 
			c = as-integer #"-"
		][
			neg?: c = as-integer #"-"
			p: p + unit
			len: len - 1
		]
		m: 0
		n: 0
		f: 0
		z: 0
		value/coefficient: 0
		value/exponent: 0
		value/value: 0
		value: money/convert value

		until [
			c: (string/get-char p unit) - #"0"
			either all [c <= 9 c >= 0][					;-- skip #"'"

				if fractions? [
					f: f - 1
				] 				

				either c = 0 [
					if not leading? [				
						z: z + 1 ; add trailing zeroes, so they can be scaled by the exponent
					]					
				][
					leading?: no
					z: z + 1
					m: n * integer/int-power 10 z

					z: 0

					either neg? [tmp: m - 1][tmp: m]

					if money/overflow? tmp [
						; only trailing zeroes are allowed from now on
						overflow?: yes
						error/value: -2						
						value: money/generate-nan value
						
						return value	
					]
					
					n: m
					m: n + c

					either neg? [tmp: m - 1][tmp: m]

					if money/overflow? tmp [
						; only trailing zeroes are allowed from now on
						overflow?: yes											
						error/value: -2
						value: money/generate-nan value
						
						return value	
					]

					n: m					
				] 
			][
				c: c + #"0"

				case [
					c = as-integer #"." [
						fractions?: yes]
					c = as-integer #"'" [0]				;-- pass-thru
					true				[
						error/value: -1
						len: 1 							;-- force exit
					]
				]
			]
			p: p + unit
			len: len - 1
			zero? len
		]

		value/coefficient: either neg? [0 - n][n]
		value/exponent: z + f
		value: money/pack value

		value
	]
]