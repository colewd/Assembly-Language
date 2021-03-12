.data

TOKEN:		.word 	0x20202020:3	# 2-word TOKEN & its TYPE
tokArray:	.word	0x20202020:60	# initializing with blanks
symbol:		.word	0x20202020:4
SymTab:		.word 	0x20202020:80	#initialize symbol table with blanks, 16 bytes *10 rows
saveReg:        .word   0:3


inBuf:		.space	80

st_prompt:	.asciiz			"Enter a new input line. \n"
st_error:	.asciiz			"An error has occurred. \n"	
tableHead:	.asciiz 		"  TOKEN        TYPE\n"
DDError:	.asciiz 		"Double Definition Error. \n"

.text

# Main
#
#	read input 
#	call scanner driver
#	clear buffers
#
#  	Global Registers
#	  $t5: index to inBuf in bytes
#	  $s0: char type, T
#	  $s1: next state Qx
#  	  $s3: index to the new char space in TOKEN
#  	  $a3: index to tokArray in 12 bytes per entry
#	  $t9: LOC, initialized at 0x400
#	  $t4: Tokens Index
#	  $t8: SymTab Index


	li 	$t9, 0x400 			#initialize LOC to 
	li	$t8, 0				#SymTab Index
newline:
	jal	getline				# get new input string
	
	li	$t5,0				# $t5: index to inBuf
	li	$a3,0				# $a3: index to tokArray
	
						# State table driver
	la	$s1, Q0				# initial state Q0
driver:	lw	$s2, 0($s1)			# get action routine
	jalr	$v1, $s2			# execute action

	sll	$s0, $s0, 2			# compute byte offset of T
	add	$s1, $s1, $s0			# locate next state
	la	$s1, ($s1)
	lw	$s1, ($s1)			# next State in $s1
	sra	$s0, $s0, 2			# reset $s0 for T
	b	driver				# go to next state
	

start:	la	$t2, tokArray+8($0)		# t2= tokArray type
	li	$t3, '6'			# t3 = 6
	beq	$t2, $t3, exit 			# if token is type 6 (#) exit
	li	$t4, 0				# tokens index = 0
	b nextTok
	
nextTok:
	lb 	$t2, tokArray+12($0)		# Check next token
	bne 	$t2, ':', operator		# if it is not equal to : goto operator
	
	lw 	$t3, tokArray($t4)		# t3= tokenArray (i)
	sw 	$t3, symbol($0)			# symbol = tokenArray(i)
	
	lw 	$t3, tokArray+4($t4)		# t3= tokenArray (i)
	sw 	$t3, symbol+4($0)		# symbol = tokenArray(i)
	lw	$t3, symbol			# t3= symbol
	
	
	li	$s7, 1				# s7 = def (1)
	jal	VARIABLE			# go to Variable
	addi 	$t4, $t4, 24			# i +=2
	
chkVar:
	la 	$t2, tokArray+8($t4)		#t2 = tokArray Type (i)
						#li	$t3, '6'		
	bne	$t2, 6, dump			#if t3 != 6, goto dump
	beq 	$a2, 0, nextVar 		#if a2== 0 goto nextcheck
	bne	$t2, 2, nextVar			# if t2!= 2 goto nextVAR
	lw 	$t3, tokArray($t4)		# t3= =tokArray(i)
	sw 	$t3, symbol($0)			# symbol(0) = t3
	lw 	$t3, tokArray+4($t4)		# t3= tokenArray+4 (i)
	sw 	$t3, symbol+4($0)		# symbol = tokenArray(i)
	lw	$t3, symbol			# t3= symbol
	li	$s7, 0				#s7 = 0
	jal VARIABLE
	
nextVar: 
	lw 	$t3, tokArray($t4)
	beq 	$t3, ',', yes			# if t3 = ,-- goto yes
	li	$a2, 0				# a2= 0
	b 	update2			

yes:	li 	$a2, 1				#isComma = true
update2:addi 	$t4, $t4, 12			#tokArray counter++
	b chkVar

	

VARIABLE:
	li	$t0, 0		 		#SymTab index
	lw 	$t1, SymTab($0)  		#t1= symtab(i)
	
	while:	bge 	$t0, 144, ret1		#if t0 >= 144, goto ret1
		bne 	$t1, $t3, update1	#if t1!= t2, goto update1
		b 	done1 			#index in $t0
			
	update1: addi 	$t0, $t0, 16		#t0++
		lw 	$t1, SymTab($t0)	#SymTab(i) = $t1
		b 	while
	ret1: 	li 	$t0, -1
	
done1: bge 	$t0, 0, else1			#if t0>= 0 goto else1
	ori 	$s7, $s7, 0x4			#s7 =  s7 | 0x4
	lw	$t3, symbol($0)			#t3 = symbol
	sw 	$t3, SymTab($t8)		#store symbol
	lw	$t3, symbol+4($0)	
	sw 	$t3, SymTab+4($t8)	
	sw 	$s7, SymTab+12($t8)		#store defn
	li	$t2, '\n'			#put a new line at the end of each line in symtab
	sb 	$t2, SymTab+15($t8)
	addi 	$t0, $t0, 1			#i++
	add	$t0, $t0, $t8			#update t0
	addi 	$t8, $t8, 16			#update symTab index
	b 	ret2
	
else1: 	lw 	$s4, SymTab+12($t0)		#s4 = oldstatus
	andi 	$t6, $s4, 0x2 			#t6= newStatus
	and 	$s4, $s4, 0x1
	sll 	$s4, $s4, 1
	or 	$s4, $t6, $s4
	or 	$s7, $s4, $s7
	sw 	$s7, SymTab+12($t0)
	
	
ret2:
						#newStatus is in s7, symIndex in  t0

la $s6, retVar

la 	$s5, symACTS
sll	$s7, $s7, 2
add 	$s5, $s5, $s7
jr 	$s5

retVar: jr $ra
	
hex2char:
                				# save registers
                sw      $t0, saveReg($0)        # hex digit to process
                sw      $t1, saveReg+4($0)      # 4-bit mask
                sw      $t9, saveReg+8($0)

               					# initialize registers
                li      $t1, 0x0000000f 	# $t1: mask of 4 bits
                li      $t9, 3                  # $t9: counter limit

nibble2char:
                and      $t0, $a0, $t1          # $t0 = least significant 4 bits of $a0

               					# convert 4-bit number to hex char
                bgt     $t0, 9, hex_alpha       # if ($t0 > 9) goto alpha
               					# hex char '0' to '9'
                addi    $t0, $t0, 0x30          # convert to hex digit
                b       collect

hex_alpha:
                addi    $t0, $t0, -10           # subtract hex # "A"
                addi    $t0, $t0, 0x61          # convert to hex char, a..f

               					# save converted hex char to $v0
collect:
                sll     $v0, $v0, 8             # make a room for a new hex char
                or      $v0, $v0, $t0           # collect the new hex char

                				# loop counter bookkeeping
                srl     $a0, $a0, 4             # right shift $a0 for the next digit
                addi    $t9, $t9, -1            # $t9--
                bgez    $t9, nibble2char

               					# restore registers
                lw      $t0, saveReg($0)
                lw      $t1, saveReg+4($0)
                lw      $t9, saveReg+8($0)
                jr      $ra		
		
symACTS:
b symACT0
b symACT1
b symACT2
b symACT3
b symACT4
b symACT5

symACT0:
	lw $s5, SymTab+8($t0) 			#old contents of SymTab Value in $s6
	sw $t9, SymTab+8($t0)
	jr $s6
symACT1:
	lw $s5, SymTab+8($t0) 			#old contents of SymTab Value in $s6
	sw $t9, SymTab+8($t0)
	jr $s6
symACT2:
	lw $s5, SymTab+8($t0) 			#old contents of SymTab Value in $s6
	jr $s6
symACT3:
	la	$a0, DDError			
	li	$v0, 4
	syscall
	
	li $s5, -1
	jr $s6
	
symACT4:
	sw $t9, SymTab+8($t0)
	li $s5, -1
	jr $s6
symACT5:
	sw $t9, SymTab+8($t0)
	li $s5, 0
	jr $s6
	
char2hex:
               					# save registers
                sw      $t0, saveReg($0)        # hex digit to process
                sw      $t1, saveReg+4($0)      # 4-bit mask
                sw      $t9, saveReg+8($0)
                
                li      $v0, 0
                li      $t1, 3
                li      $t0, 0
iterloop:
                bge     $t0, 4, hexdone
                add     $t0, $t0, $a0
                lb      $t9, SymTab($t0)
                sub     $t0, $t0, $a0
                subi    $t9, $t9, 0x30
                sll     $t1, $t1, 2
                sllv    $t9, $t9, $t1
                srl     $t1, $t1, 2
                add     $v0, $v0, $t9
                addi    $t0, $t0, 1
                addi    $t1, $t1, -1
                b iterloop
hexdone:
               				 	# restore registers
                lw      $t0, saveReg($0)
                lw      $t1, saveReg+4($0)
                lw      $t9, saveReg+8($0)
                jr      $ra

dump:	
	jal	clearInBuf			
	jal	clearTokArray			
	la 	$a0, SymTab
	li	$v0, 4
	syscall
	addi 	$t9, $t9, 4
	jal 	clearSym
	b 	newline


####################### STATE ACTION ROUTINES #####################

# ACT1:
#	$t5: Get next char
#	T = char type

ACT1: 
	lb	$a0, inBuf($t5)			# $a0: next char
	jal	lin_search			# $s0: T (char type)
	addi	$t5, $t5, 1			# $t5++
	jr	$v1
	
# ACT2:
#	save char to TOKEN for the first time
#	save char type as Token type
#	set remaining token space

ACT2:
	li	$s3, 0				# initialize index to TOKEN char 
	sb	$a0, TOKEN($s3)			# save 1st char to TOKEN
	addi	$t0, $s0, 0x30			# T in ASCII
	sb	$t0, TOKEN+10($s3)		# save T as Token type
	li	$t0, '\n'
	sb	$t0, TOKEN+11($s3)		# NULL to terminate an entry
	addi	$s3, $s3, 1
	jr 	$v1
	
# ACT3:
#	collect char to TOKEN
#	update remaining token space

ACT3:
	bgt	$s3, 7, lenError		# TOKEN length error
	sb	$a0, TOKEN($s3)			# save char to TOKEN
	addi	$s3, $s3, 1			# $s3: index to TOKEN
	jr	$v1	
lenError:
	li	$s0, 7				# T=7 for token length error
	jr	$v1
					
#  ACT4:
#	move TOKEN to tokArray

ACT4:
	lw	$t0, TOKEN($0)			# get 1st word of TOKEN
	sw	$t0, tokArray($a3)		# save 1st word to tokArray
	lw	$t0, TOKEN+4($0)		# get 2nd word of TOKEN
	sw	$t0, tokArray+4($a3)		# save 2nd word to tokArray
	lw	$t0, TOKEN+8($0)		# get Token Type
	sw	$t0, tokArray+8($a3)		# save Token Type to tokArray
	addi	$a3, $a3, 12			# update index to tokArray
	
	jal	clearTok			# clear TOKEN
	jr	$v1



#  RETURN:

RETURN:
	sw	$zero, tokArray($a3)		# force NULL into tokArray
	b	start				

#  ERROR:

ERROR:
	la	$a0, st_error			# print error 
	li	$v0, 4
	syscall
	b	dump


############################### BOOK-KEEPING FUNCTIONS #########################

#  clearTok:

clearTok:
	li	$t1, 0x20202020
	sw	$t1, TOKEN($0)
	sw	$t1, TOKEN+4($0)
	sw	$t1, TOKEN+8($0)
	jr	$ra

#  printline:

printline:
	la	$a0, inBuf			# inBuf address
	li	$v0,4
	syscall
	jr	$ra

#  printTokArray:

printTokArray:
	la	$a0, tableHead			# table heading
	li	$v0, 4
	syscall

	la	$a0, tokArray			# print tokArray
	li	$v0, 4
	syscall

	jr	$ra

#  clearInBuf:

clearInBuf:
	li	$t0,0
loopInB:
	bge	$t0, 80, doneInB
	sw	$zero, inBuf($t0)		# clear inBuf to 0x0
	addi	$t0, $t0, 4
	b	loopInB
doneInB:
	jr	$ra
	
#Clear Symbol

clearSym:
	li	$t1, 0x20202020
	sw	$t1, symbol($0)
	sw	$t1, symbol+4($0)
	sw	$t1, symbol+8($0)
	sw	$t1, symbol+12($0)
	jr	$ra

# clearTokArray:

clearTokArray:
	li	$t0, 0
	li	$t1, 0x20202020			# intialized with blanks
loopCTok:
	bge	$t0, $a3, doneCTok
	sw	$t1, tokArray($t0)		# clear
	sw	$t1, tokArray+4($t0)		#  3-word entry
	sw	$t1, tokArray+8($t0)		#  in tokArray
	addi	$t0, $t0, 12
	b	loopCTok
doneCTok:
	jr	$ra
	
#  getline:

getline: 
	la	$a0, st_prompt			# Prompt to enter a new line
	li	$v0, 4
	syscall

	la	$a0, inBuf			# read a new line
	li	$a1, 80	
	li	$v0, 8
	syscall
	
	jr	$ra

#  lin_search:
#	Linear search of Tabchar
#   	$a0: char key
#   	$s0: char type, T

lin_search:
	li	$t0,0				# index to Tabchar
	li	$s0, 7				# return value, type T
loopSrch:
	lb	$t1, Tabchar($t0)
	beq	$t1, 0x7F, charFail
	beq	$t1, $a0, charFound
	addi	$t0, $t0, 8
	b	loopSrch

charFound:
	lw	$s0, Tabchar+4($t0)		# return char type
charFail:
	jr	$ra
	
operator: 					# do nothing with operator
	addi 	$t4, $t4, 12
	li	 $a2, 1 			#isComma = TRUE
	
exit:
	li $v0, 10
	syscall

	
	
	.data

STAB:
Q0:     .word  ACT1
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q1:     .word  ACT2
        .word  Q2   # T1
        .word  Q5   # T2
        .word  Q3   # T3
        .word  Q3   # T4
        .word  Q0   # T5
        .word  Q4   # T6
        .word  Q11  # T7

Q2:     .word  ACT1
        .word  Q6   # T1
        .word  Q7   # T2
        .word  Q7   # T3
        .word  Q7   # T4
        .word  Q7   # T5
        .word  Q7   # T6
        .word  Q11  # T7

Q3:     .word  ACT4
        .word  Q0   # T1
        .word  Q0   # T2
        .word  Q0   # T3
        .word  Q0   # T4
        .word  Q0   # T5
        .word  Q0   # T6
        .word  Q11  # T7

Q4:     .word  ACT4
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q5:     .word  ACT1
        .word  Q8   # T1
        .word  Q8   # T2
        .word  Q9   # T3
        .word  Q9   # T4
        .word  Q9   # T5
        .word  Q9   # T6
        .word  Q11  # T7

Q6:     .word  ACT3
        .word  Q2   # T1
        .word  Q2   # T2
        .word  Q2   # T3
        .word  Q2   # T4
        .word  Q2   # T5
        .word  Q2   # T6
        .word  Q11  # T7

Q7:     .word  ACT4
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q8:     .word  ACT3
        .word  Q5   # T1
        .word  Q5   # T2
        .word  Q5   # T3
        .word  Q5   # T4
        .word  Q5   # T5
        .word  Q5   # T6
        .word  Q11  # T7

Q9:     .word  ACT4
        .word  Q1  # T1
        .word  Q1  # T2
        .word  Q1  # T3
        .word  Q1  # T4
        .word  Q1  # T5
        .word  Q1  # T6
        .word  Q11 # T7

Q10:	.word	RETURN
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q11:    .word  ERROR 
	.word  Q4  # T1
	.word  Q4  # T2
	.word  Q4  # T3
	.word  Q4  # T4
	.word  Q4  # T5
	.word  Q4  # T6
	.word  Q4  # T7
	
	
Tabchar: 
	.word ' ', 5
 	.word '#', 6
 	.word '$', 4 
	.word '(', 4
	.word ')', 4 
	.word '*', 3 
	.word '+', 3 
	.word ',', 4 
	.word '-', 3 
	.word '.', 4 
	.word '/', 3 

	.word '0', 1
	.word '1', 1 
	.word '2', 1 
	.word '3', 1 
	.word '4', 1 
	.word '5', 1 
	.word '6', 1 
	.word '7', 1 
	.word '8', 1 
	.word '9', 1 

	.word ':', 4 

	.word 'A', 2
	.word 'B', 2 
	.word 'C', 2 
	.word 'D', 2 
	.word 'E', 2 
	.word 'F', 2 
	.word 'G', 2 
	.word 'H', 2 
	.word 'I', 2 
	.word 'J', 2 
	.word 'K', 2
	.word 'L', 2 
	.word 'M', 2 
	.word 'N', 2 
	.word 'O', 2 
	.word 'P', 2 
	.word 'Q', 2 
	.word 'R', 2 
	.word 'S', 2 
	.word 'T', 2 
	.word 'U', 2
	.word 'V', 2 
	.word 'W', 2 
	.word 'X', 2 
	.word 'Y', 2
	.word 'Z', 2

	.word 'a', 2 
	.word 'b', 2 
	.word 'c', 2 
	.word 'd', 2 
	.word 'e', 2 
	.word 'f', 2 
	.word 'g', 2 
	.word 'h', 2 
	.word 'i', 2 
	.word 'j', 2 
	.word 'k', 2
	.word 'l', 2 
	.word 'm', 2 
	.word 'n', 2 
	.word 'o', 2 
	.word 'p', 2 
	.word 'q', 2 
	.word 'r', 2 
	.word 's', 2 
	.word 't', 2 
	.word 'u', 2
	.word 'v', 2 
	.word 'w', 2 
	.word 'x', 2 
	.word 'y', 2
	.word 'z', 2

	.word 0x7F, 0
