.data
inBuf:		.space	80		# input 
st_prompt:	.asciiz			"Enter a new input line. \n"
outBuf:		.space 	80		# char types for  input line



	.text

newLine:
	jal	getline			
	lb	$t0, inBuf($0)		# $t0 = inBuf(0)
	beq	$t0, '#', leave
	
	li	$t0, 0			# i = 0
	
forLoop:
	bge	$t0, 80, endLoop	# (i>=80) using for loop
	lb	$t1, inBuf($t0)		# key = inBuf(i)
	beq	$t1, '#', endLoop	# end loop when key = #
	
	jal	lin_search		# key in $t1, return in $a0

	addi	$a0, $a0, 0x30		# #a0: char(return value)
	sb	$a0, outBuf($t0)	# store char in outbuf
	
	addi	$t0, $t0, 1		# increment i by 1
	b	forLoop
	
	
endLoop:
	li	$v0, 4		 # print inBuf
	la 	$a0, inBuf
	syscall
	
	li 	$t8, '6'	# add 6 to outBuf
	sb	$t8, outBuf($t0)
    
    	li 	$v0, 4		#print outbuf
	la 	$a0, outBuf
	syscall

	
	li	$v0, 11		#print a new line after outbuf
	li 	$a0, 0x0a
	syscall
	
	#clear inBuf
	li $t7, 0 	#i=0
	li $t6, 0
	
clearInBuf: 
	bge	$t7, 80, newLine	# (i>=80) done with loop
	sb	$t6, inBuf($t7)		# 0 = inBuf(i)
	sb 	$t6, outBuf($t7)	# outBuf(i) == 0
	addi	$t7, $t7, 1		#increment i by 1
	b clearInBuf
	#b newLine
	
leave:  

	li $v0, 10
	syscall
	

  # lin_search
	#argument: key - $t1
	#return char type: in $a0

lin_search:
	li	$a0, -1			# index = -1
	li	$s0, 0			# i = 0
chkChar:
	bge	$s0, 75, ret
	
	sll	$s0, $s0, 3		# C index i to byte offset in multiples of 8
	lb	$s1, Tabchar($s0)	# $s1 - Tabchar(i, 0)
	sra	$s0, $s0, 3		# restore to C index

	bne	$s1, $t1, nextChar
	
	sll	$s0, $s0, 3
	lw	$a0, Tabchar+4($s0)	# index = Tabchar(i, 1)
	sra	$s0, $s0, 3

	b	ret
	
nextChar:
	addi	$s0, $s0, 1		# incriment i by 1
	b	chkChar

ret:	jr	$ra
	
	
getline: 
	la	$a0, st_prompt		# prompt for new line
	li	$v0, 4
	syscall

	la	$a0, inBuf		# read new line
	li	$a1, 80	
	li	$v0, 8
	syscall

	jr	$ra

.data
Tabchar:	 .word	0x0a,6 	#LF
.word	' ',	5
.word	'#',	6
.word	'$',	4
.word	'(',	4	
.word	')',	4	
.word	'*',	3	
.word	 '+',	3	
.word	',',	4	
.word	'-',	3	
.word	'.',	4	
.word	'/',	3	
.word	'0',	1
.word	'1',	1	
.word	'2',	1	
.word	'3',	1	
.word	'4',	1	
.word	'5',	1	
.word	'6',	1	
.word	'7',	1	
.word	'8',	1	
.word	'9',	1	
.word	':',	4	
.word	'A',	2
.word   'B',	2	
.word	'C',	2	
.word	'D',	2	
.word	'E',	2	
.word	'F',	2	
.word	'G',	2	
.word	'H',	2	
.word	'I',	2	
.word	'J',	2	
.word	'K',	2
.word	'L',	2	
.word	'M',	2	
.word	'N',	2	
.word	'O',	2	
.word	'P',	2	
.word	'Q',	2	
.word	'R',	2	
.word	'S',	2	
.word	'T',	2	
.word	'U',	2
.word	'V',	2	
.word	'W',	2	
.word	'X',	2	
.word	'Y',	2
.word	'Z',	2
.word	'a',	2	
.word	'b',	2	
.word	'c',	2	
.word	'd',	2	
.word	'e',	2	
.word	'f',	2	
.word	'g',	2	
.word	'h',	2	
.word	'i',	2	
.word   'j',	2	
.word	'k',	2
.word	'l',	2	
.word	'm',	2	
.word	'n',	2	
.word	'o',	2	
.word	'p',	2	
.word	'q',	2	
.word	'r',	2	
.word	's',	2	
.word	't',	2	
.word	'u',	2
.word	'v',	2	
.word	'w',	2	
.word	'x',	2	
.word	'y',	2
.word	'z',	2
