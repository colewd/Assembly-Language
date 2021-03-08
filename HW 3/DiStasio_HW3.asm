.data

inBuf:	.space 	80		#space for 80 chars
TOKEN:	.byte	' ' : 8		# .word 0,0
Tokens:	.byte	' ': 120	# 10*(2-word Token, type)
st_prompt:	.asciiz		"Please enter new input line. \n"
errmsg:		.asciiz		"Sorry, there was an error.\n"
TYPE:	.space	4		#save type
Tablehead:	.asciiz		"TOKEN Token Type\n"

		
		.text		
newLine:
		
		jal	getline
		
		la	$s1, Q0		#s1 = current
		li	$s0, 1		#s0 = T =1
		
		li	$t0, 0 		#$t0 = inBuf 
		li	$t1, 0		#Token table 

nextState:	lw	$s2, 0($s1)	#s2=act 1
		jalr	$v1, $s2	# Save return address in $v1 

		sll	$s0, $s0, 2	# Multiply by 4 
		add	$s1, $s1, $s0
		sra	$s0, $s0, 2	#Reset T
		lw 	$s1, 0($s1)
		b	nextState
			
outLine:	# print token table
		# clear inBuf and token table
		
		jal	printToken
			li	$t7, 0
			li 	$t6, 0 
		jal	clearInbuf
		jal	clearTokens
		b newLine

getline: 
	la	$a0, st_prompt		# Prompt for new  line
	li	$v0, 4
	syscall

	la	$a0, inBuf		# read new line
	li	$a1, 80	
	li	$v0, 8
	syscall

	jr	$ra

#curChar =Get next char, T=ChType(curChar) 

ACT1: 
	
	lb 	$a3, inBuf($t0)	#$a0 = inBuf[i]
	jal 	lin_search
	addi 	$t0, $t0, 1 	#increment i
	jr	$v1

	

	
#
# current char in $a0
# TOKEN=curChar, TokSpace=7
#get next char, and char type 


ACT2: 
	li 	$t3, 0	                #token index
	li	$t6, 7			#tokenspace is 7
	addi	$s5, $s0, 0x30		#change token to char type
	sb	$s5, TYPE		#save in type
	

#curret char in a0
#TOKEN=TOKEN+curChar, TokSpace=TokSpace-1 
	

ACT3: 
	sb 	$a3, TOKEN($t3)	#token = token+currchar
	addi	$t3, $t3, 1	#increment i
	sub	$t6, $t6, 1	#tokspace --
	
	jr	$v1
	
ERR: 
	li 	$s0, 7
	jr 	$v1
	
ACT4: #Save token int TOKENS

	lw $s4, TOKEN
	sw $s4, Tokens($t1)
	
	lw $s4, TOKEN+4
	sw $s4, Tokens+4($t1)
	
	lb $s4, TYPE
	sb $s4, Tokens+8($t1)
	
	li $s4, '\n'
	sb $s4, Tokens+11($t1)
	addi	$t1, $t1, 12


	b clearToken
	jr $v1
	
RETURN:	sb $s4, Tokens($t1)
	b outLine

ERROR:
	la 	$a0, errmsg
	li	$v0, 4
	syscall
	
	li $v0, 10
	syscall

#arument in a0
# return in a1

lin_search: 
	li	$s0, -1			#index = -1
	li	$s3, 0			#set i to 0

chkChar:
	bge	$s3, 75, ret
	
	sll	$s3, $s3, 3		#C index i to byte, offset by multiples of 8
	lb	$t2, Tabchar($s3)	#$s1 - Tabchar(i, 0)
	sra	$s3, $s3, 3		#restore to C index

	bne	$t2, $a3, nextChar	#
	
	sll	$s3, $s3, 3
	lw	$s0, Tabchar+4($s3)	#index = Tabchar(i, 1)
	sra	$s3, $s3, 3

	b	ret
	
nextChar:
	addi	$s3, $s3, 1		#increment i
	b	chkChar

ret:	jr	$ra
	
printToken:
	la 	$a0, Tablehead
	li	$v0, 4
	syscall
	
	la	$a0, Tokens		 #print Tokens
	li 	$v0, 4
	syscall
	
	addi $a0, $0, 0xA 
        addi $v0, $0, 0xB 
        syscall

	jr $ra
	
clearToken:
	li	$t6, ' '
	li	$t7, 0
	clearLoopTwo:	bge	$t7, 8, doneLoopTwo
			sb	$t6, TOKEN($t7)
			addi 	$t7, $t7, 1
			b clearLoopTwo
			
	doneLoopTwo: jr	$v1
	
clearTokens:
	li	$t6, ' '
	li	$t7, 0
	clearLoop:	bge	$t7, 120, doneLoop
			sb	$t6, Tokens($t7)
			addi 	$t7, $t7, 1
			b clearLoop
			
	doneLoop: jr	$ra

clearInbuf:
		bge 	$t6, 80, done
		sb	$t7, inBuf($t6)
		addi 	$t6, $t6, 1
		b clearInbuf
done: jr $ra	


	
		.data
STAB:
Q0:     .word  ACT1
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q10  # T7

Q1:     .word  ACT2
        .word  Q2   # T1
        .word  Q5   # T2
        .word  Q3   # T3
        .word  Q3   # T4
        .word  Q0   # T5
        .word  Q4   # T6
        .word  Q10  # T7

Q2:     .word  ACT1
        .word  Q6   # T1
        .word  Q7   # T2
        .word  Q7   # T3
        .word  Q7   # T4
        .word  Q7   # T5
        .word  Q7   # T6
        .word  Q10  # T7

Q3:     .word  ACT4
        .word  Q0   # T1
        .word  Q0   # T2
        .word  Q0   # T3
        .word  Q0   # T4
        .word  Q0   # T5
        .word  Q0   # T6
        .word  Q10  # T7

Q4:     .word  RETURN
        .word  Q4   # T1
        .word  Q4   # T2
        .word  Q4   # T3
        .word  Q4   # T4
        .word  Q4   # T5
        .word  Q4   # T6
        .word  Q10  # T7

Q5:     .word  ACT1
        .word  Q8   # T1
        .word  Q8   # T2
        .word  Q9   # T3
        .word  Q9   # T4
        .word  Q9   # T5
        .word  Q9   # T6
        .word  Q10  # T7

Q6:     .word  ACT3
        .word  Q2   # T1
        .word  Q2   # T2
        .word  Q2   # T3
        .word  Q2   # T4
        .word  Q2   # T5
        .word  Q2   # T6
        .word  Q10  # T7

Q7:     .word  ACT4
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q10   # T7

Q8:     .word  ACT3
        .word  Q5   # T1
        .word  Q5   # T2
        .word  Q5   # T3
        .word  Q5   # T4
        .word  Q5   # T5
        .word  Q5   # T6
        .word  Q10  # T7

Q9:     .word  ACT4
        .word  Q1  # T1
        .word  Q1  # T2
        .word  Q1  # T3
        .word  Q1  # T4
        .word  Q1  # T5
        .word  Q1  # T6
        .word  Q10  # T7

Q10:    .word  ERROR 
        .word  Q4   # T1
        .word  Q4   # T2
        .word  Q4   # T3
        .word  Q4   # T4
        .word  Q4   # T5
        .word  Q4   # T6
        .word  Q4  # T7
        
Tabchar:	 .word	0x0a,6 	#LF
.word	' ',	5
.word	'#',	5
.word	'$',	4
.word	'(',	4	
.word	')',	4	
.word	'*',	3	
.word   '+',	3	
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
