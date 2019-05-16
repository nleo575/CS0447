##########################################################
# @author Nicolas Leo, nll21
# CS 447 spring 2018 
# Project 1: Floating-point operations w/o FP instructions 
##########################################################
.text
wait:	beq $t9, $0, wait # Wait until $t9 is not zero (1)

#@args
#	$a0 will hold operand A
#	$a1 will hold operand B
#@return
#	$v0 contains the result of A+B and A−B. 
#		A − B is in the upper 16-bit and A+B is in the lower 16-bits |A - B| |A + B|
#
#	$v1 contains the result of A × B and A/B. 
#		A/B is in the upper 16-bit and A × B in the lower 16-bits |A/B||A x B|
#
# 	$a2 contains the result of sqrt(|A|)
	
	add $s0, $0, $a0 #Get operand A from $a0
	add $s1, $0, $a1 #Get operand A from $a1
	#$s2 will hold lower 16 bits of paired operations (A+B)(AxB)
	#$s3 will holder higher 16 bits of paired opeartions (A-B)(A/B)
	add $s4, $0, $a0 #Store backup of operand A, later will store abs(A) in this register
	add $s5, $0, $a1 #Store backup of operand B, later will store abs(B) in this register	
#addition
	add $s2, $s0, $s1	# Add the two operands $s2 = A + B
#subtraction
	sub $s3, $s0, $s1	# Subtract the two operands $s3 = A - B
	# Prepare result in $v0: A + B | A - B
	add $v0, $0, $s3 	#Puts subtraction ($s3) result into $v0
	sll $v0, $v0, 16 	#Shift left 16 to accomodate result of addition
	andi $s2, $s2, 0xffff
	or $v0, $v0, $s2
	
################
# Multiplication
################
	# $s0 has (A) and $s1 has (B)
	
	add $s2, $0, $0	# Will hold the results of multiplication
	# $t0 will hold temporary integers
	# $t1 will be a shift counter
	
	#Check if A or B or Both are negative, if they are, flip to positive to prevent overflow
	slti $t0, $s0, 0	# If A < 0, then $t0 = 1, else 0
	slti $t1, $s1, 0	# If B < 0, then $t0 = 1, else 0
	add $t2, $t0, $t1	# Adds results of comparisons
	
	bne $t2, 0, flip	# Will need to make operands positive to prevent overflow
	
multLoop:
	beq  $s1, 0, multResult	# Jump to point to setup result of calculation if there are no more digits in multiplier	
	
	andi $t0, $s1, 1	#Stores LSB in $t0 
	beq $t0, $0, lsb0	#Branches if LSB is 0
	
	#If LSB is 1 then continue until no more significant bits
	sllv $t0, $s0, $t1	
	add $s2, $s2, $t0	#Keeps running total of the calculation
	addi $t1, $t1, 1	#Incremements shift counter by 1
	
	srl  $s1, $s1, 1	#Shifts multiplier one bit to the right
	j multLoop			#Goes back to beginning of multiplication loop
	
lsb0:
	addi $t1, $t1, 1	#Incremements shift counter by 1
	srl  $s1, $s1, 1	#Shifts multiplier one bit to the right
	j multLoop			#Goes back to beginning of multiplication loop	

flip:
	beq $t0, 0, flipB
	
	# Makes A into a positive number
	xori $s0, $s0, 0xffffffff #Flips the bits
	addi $s0, $s0, 1	# Adds 1 (two's complement)
	add $s4, $s0, $0	# Stores a copy of flipped B for later use
flipB:
	beq $t1, 0, resetTregs
	xori $s1, $s1, 0xffffffff #Flips the bits if B is negative
	addi $s1, $s1, 1	# Adds 1 (two's complement)
	add $s5, $s1, $0	# Stores a copy of flipped B for later use
	
resetTregs:		
	add $t0, $0, $0		# Resets temp int.
	add $t1, $0, $0 	# Resets counter to 0
	add $t2, $0, $0
	j multLoop
		
multResult:	
	#check if A or B were negative, if one was, flip result
	slti $t0, $a0, 0	# If A < 0, then $t0 = 1, else 0
	slti $t1, $a1, 0	# If B < 0, then $t0 = 1, else 0
	add $t2, $t0, $t1	# Adds results of comparisons
	
	bne $t2, 1, multEnd	# Will need to negate answer if one of operands was negative

	xori $s2, $s2, 0xffffffff #Flips the bits
	addi, $s2, $s2, 1	# Adds 1 (two's complement)
	
multEnd:
	srl $s2, $s2, 8		# Need to convert multiplication answer to Q16.8
	add $v1, $0, $s2	# Copy result of multiplication into $v1
	
##########
# Divison
##########
	add $s0, $s4, $0	# Restores abs(A) to $s0 register (Dividend)
	add $s1, $s5, $0	# Restores abs(B) to $s1 register (Divisor)	
	add $s2, $0, $0		# Will hold the quotient 1
	add $s3, $0, $0		# Will hold the remainder 1
	# $s4 currently holds abs(A)
	# $s5 currently holds abs(B)
	
	add $t0, $0, $0		# $t0 will hold temporary integers & results of bitwise comparisons
	# $t1 stores temp copy of Dividend. Will perform calculations on this then update A ($s0) if successful
	add $t2, $0, $0		# $t2 will be shift counter for quotient. 
				#Tells how many times dividend can be halved and still be >= divisor

	beq $s0, 0, sqrt	# No need to run loop if dividend is 0 
	beq $s1, 0, sqrt	# No Need to run loop if divisor is 0 (divide by 0 is undefined)
	
divLoop:
	slt $t0, $s0, $s1	# Checks if A < B (i.e. dividend < divisor). If True, division finished
	bne  $t0, 0, divResult	# If $t0 = 1, Division finished. Jump to result section ($s0 will contain remainder if any)
	
	add $t1, $s0, $0	# Stores temp copy of Dividend in $t1, Will perform calculations on this 
	
shiftInner: # Check if A/2 is still >= B. If so, continue loop. If not, A = A - B. 	
	srl $t1, $t1, 1		# A = A >> 1
	slt $t0, $t1, $s1	# Checks if (A >> 1) < B (i.e. dividend/2 < divisor). If false, increase quotient shift
	beq  $t0, 0, canShift	#  B <= (A >> 1)
	# if $t0 = 1, then (A >> 1) < B, shift counter ($t2) will not increase and quotient will only increase by 1. 
	
	addi $t0, $0, 1		# Hold 1, since B can go into A at least 1 time, if not more
	sllv $t0, $t0, $t2	# 1 x 2^($t2)
 	add $s2, $s2, $t0	# Quotient1 += (1 << $t2)
 	
	add $t0, $0, $s1	# Hold B
	sllv $t0, $t0, $t2	#  B x 2^($t2)
	
	sub $s0, $s0,$t0 	# A = A - (B<<$t2)
	
	add $t2, $0, $0		# Resets shift counter to 0
	j divLoop		#Goes back to beginning of division loop

canShift:
	addi $t2, $t2, 1	# Increase shift counter by 1
	j shiftInner

divResult:
	add $s6, $0, $0		# Will hold quotient2
	beq $s0, 0, divEnd1	# Branches to divEnd if there is no remainder ($s0 == 0)

	sll $s0, $s0, 8		# Shift remainder << 8 to rerun division
	
#Beginning of second division loop (for Remainder<<8 /B)
	# $s1 Still hold abs(B) from prior divisiion
	# $s4 currently holds abs(A)
	# $s5 currently holds abs(B)

	add $t0, $0, $0		# $t0 will hold temporary integers & results of bitwise comparisons
	# $t1 stores temp copy of Dividend. Will perform calculations on this then update A ($s0) if successful
	add $t2, $0, $0		# $t2 will be shift counter for quotient. 
				#Tells how many times dividend can be halved and still be >= divisor
					
divLoop2: # Divides Remainder<<8 (if there is one) by B, so R/B
	slt $t0, $s0, $s1	# Checks if A < B (i.e. dividend < divisor). If True, division finished
	bne  $t0, 0, divEnd1	# If $t0 = 1, Division finished. Jump to result section ($s0 will contain remainder if any)
	
	add $t1, $s0, $0	# Stores temp copy of Dividend in $t1, Will perform calculations on this 
	
shiftInner2: # Check if A/2 is still >= B. If so, continue loop. If not, A = A - B. 	
	srl $t1, $t1, 1		# A = A >> 1
	slt $t0, $t1, $s1	# Checks if (A >> 1) < B (i.e. dividend/2 < divisor). If false, increase quotient shift
	beq  $t0, 0, canShift2	#  B <= (A >> 1)
	# if $t0 = 1, then (A >> 1) < B, shift counter ($t2) will not increase and quotient will only increase by 1. 
	
	addi $t0, $0, 1		# Hold 1, since B can go into A at least 1 time, if not more
	sllv $t0, $t0, $t2	# 1 x 2^($t2)
 	add $s6, $s6, $t0	# Quotient2 += (1 << $t2)
 	
	add $t0, $0, $s1	# Hold B
	sllv $t0, $t0, $t2	#  B x 2^($t2)
	sub $s0, $s0, $t0 	# A = A - (B<<$t2)
	
	add $t2, $0, $0		# Resets shift counter to 0
	j divLoop2		#Goes back to beginning of division loop
	
canShift2:
	addi $t2, $t2, 1	# Increase shift counter by 1
	j shiftInner2

divEnd1:
	sll $s2, $s2, 8	  	#Shifts result up 8 to accomodate Q2
	or $s2, $s2, $s6	#Combines quotient 1 w/quotient 2 in lower half of register
	
	#check if A or B were negative, if one was, flip result
	slti $t0, $a0, 0	# If A < 0, then $t0 = 1, else 0
	slti $t1, $a1, 0	# If B < 0, then $t0 = 1, else 0
	add $t0, $t0, $t1	# Adds results of comparisons
	
	bne $t0, 1, divEnd2	# Will need to negate answer if one of operands was negative

	xori $s2, $s2, 0xffffffff #Flips the bits of combined quotient
	addi, $s2, $s2, 1	  # Adds 1 (two's complement)

divEnd2:	
	sll $s2, $s2, 16	#Shifts result << 16 to allign for combination with multiplication
	andi $v1, $v1, 0x0000ffff
	or $v1, $v1, $s2	#Combines division (upper half of $s2) with multiplication (lower 1/2 of $v1)

#############
# Sqaure root
#############
sqrt:
	add $a2, $0, $0		# $a2 holds the result of the square root
	add $t0, $0, $0		# Remainder 
	add $t1, $0, $0		# Temporary result
	add $t2, $0, $0		# 2 most significant unused bits of |A| 
	add $t3, $0, $0 	# Loop counter
	addi $t4, $0, 14	# Shift amount 
	add $t5, $0, $0		# Holds temporary calculations
	add $t6, $0, $0		# Holds temporary calculations
	
sqrtLoop:
	beq $t3, 12, done	# Loop will run 12 times

	sll $t0, $t0, 2		# Remainder = Remainder << 2	
		
	# Get 2 most significant unused bits
	srlv $t2, $s4, $t4	# Shift |A| >> by $t4 times
	and $t2, $t2, 3		# Get two left most sig. unused bits (2LMSUB)

	add $t0, $t0, $t2	# Remainder = Remainder << 2 + 2LMSUB
	
	sll $t1, $a2, 2		# Temp result = Current result << 2
	addi $t5, $t1, 1	# $t5 = Temp result + 1
	
	sll $a2, $a2, 1		# new Result = Current Result << 1	

	slt $t6, $t5, $t0	# Check if result of calculation < Remainder
	beq $t6, 1, calcLessOrEqualRem	
	bne $t5, $t0, doneComparison # Calcluation is > Remainder otherwise
calcLessOrEqualRem:
	
	sub $t0, $t0, $t5	# new Remainder = current Remainder - (tempResult + 1)
	add $a2, $a2, 1		# Add 1 to the new Result
	
doneComparison:	#tempResult+1 > REmainder, therefore Remainder is unchanced			
	
	addi $t3, $t3, 1	# Incremement loop cunter
	addi $t4, $t4, -2	# Decrease shift counter by 2
	
	bne $t3, 8 ,sqrtLoop	# After loops, there there won't be any useful digits left in $s4 
	# which holds the abs(A), shift counter will be negative too which poses a problem
	add $s4, $0, $0		# Set $s4 to 0 in oder to compensate.
	
	j sqrtLoop
done:
	
	add $t9, $0, $0 #Signals that cacluations are completed. Set $t9 back to 0
	j wait	#Go back to wait
