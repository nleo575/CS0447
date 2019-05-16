.text

	add $s0, $0, $0		#Current column
	add $s1, $0, $0		#Current row
	add $s2, $0, $0		#Current cell
	add $s3, $0, $0		#Current cell
	add $s4, $0, $0		#Current cell

#Print inital board
	add $a0, $0, $0		#Reinitialize $a0
	add $t0, $0, $0		#Counter for columns
	add $t1, $0, $0		#Counter for total cells printed
	addi $t2, $0, 0xffff8000#Starting memory address of game data
	addi $v0, $0, 1		#Syscall 1: Print int
printCol:
	beq $t1, 81, gameSetup
	beq $t0, 9, nextRow
	
	
	lb $a0, 0($t2)
	syscall
	add $t0, $t0, 1	#Increase row count by 1
	add $t1, $t1, 1	#Increase cell count by 1
	add $t2, $t2, 1	#Prime to read next byte from memory
	
	j printCol
nextRow:
	add $t0, $0, $0	#Reset column counter to 0
	addi $v0, $0, 11#Syscall 11: Print char
	addi $a0, $0, 0x0A #11 = new line char (line feed)
	syscall 	#Print "\n"
	
	addi $v0, $0, 1	#Back to printing ints
	j printCol

gameSetup:
	addi $s0, $0, 0xffff8000 #Memory pointer
	add $s1, $0, $0	#Row
	add $s2, $0, $0	#Column
	#$s3 = Boolean for answer
	#$S4 = i counter/guess/guess
	
	add $t0, $0, $0	#For temp calcs
	
	jal _solveSodoku
	j end
	
_solveSodoku:
	addi $sp, $sp, -24
	sw $ra, 0($sp)	#Backup SP
	sw $s0, 4($sp)	#Backup Memory pointer
	sw $s1, 8($sp)	#Backup Row
	sw $s2, 12($sp)	#Backup Column
	sw $s3, 16($sp)	#Backup Boolean
	sw $s4, 20($sp)	#Backup i counter/guess
	
	add $s3, $0, $0	#Boolean for answer
	addi $s4, $0, 1	#i counter/guess/guess
	
	bne $s1, 8, notR8C9#if (r == 8 && c == 9)
	bne $s2, 9, notR8C9
	#Else $s2 = 9 and return true
	addi $v0, $0, 1
	
	lw $ra, 0($sp)	#Restore SP
	lw $s0, 4($sp)	#Restore Memory pointer
	lw $s1, 8($sp)	#Restore Row
	lw $s2, 12($sp)	#Restore Column
	lw $s3, 16($sp)	#Restore Boolean
	lw $s4, 20($sp)	#Restore i counter/guess
	addi $sp, $sp, 24
	jr $ra
		
notR8C9:

	bne $s2, 9, notC9#if (c == 9)
	
	addi $s1, $s1, 1#r=r+1
	add $s2, $0, $0	#c = 0
notC9:	

	lb $t0, 0($s0) #Load the byte at the memory pointer
	
	#if(data @ row r col c !=0)
	beqz  $t0, is0
	addi $s0, $s0, 1#Move to next cell
	addi $s2, $s2, 1#Col=col+1
	
	jal _solveSodoku	# return _solveSodoku(r, c+1)
	
	lw $ra, 0($sp)	#Restore SP
	lw $s0, 4($sp)	#Restore Memory pointer
	lw $s1, 8($sp)	#Restore Row
	lw $s2, 12($sp)	#Restore Column
	lw $s3, 16($sp)	#Restore Boolean
	lw $s4, 20($sp)	#Restore i counter/guess
	addi $sp, $sp, 24
	jr $ra
	
is0:	#else
	beq $s4, 10, doneLoop

	#Check if i/guess is in the row
	add $a0, $0, $s2#Current column
	add $a1, $0, $s0#Current memory pointer
	add $a2, $0, $s4#Current guess
	jal _checkRow
	beqz  $v0, conflict

	#Check if i/guess is in the col
	add $a0, $0, $s1#Current row
	add $a1, $0, $s0#Current memory pointer
	add $a2, $0, $s4#Current guess
	jal _checkColumn
	beqz  $v0, conflict

	#Check if i/guess is in the subgrid
	add $a0, $0, $s1#Current row
	add $a1, $0, $s2#Current column
	add $a2, $0, $s0#Current memory pointer
	add $a3, $0, $s4#Current guess
	jal _checkSubgrid
	beqz  $v0, conflict
	
	#Else no conflict with row, col, or subgrid
	sb $s4, 0($s0)	#put i into the cell at row r column c;
	
	addi $s0, $s0, 1#Move memory pointer to next cell
	addi $s2, $s2, 1#Increase column 	
	jal _solveSodoku	
	add $s3, $0, $v0#p (boolean) = _solveSudoku(r, c + 1);
	
	bne $s3, 1, conflict2
	
	addi $v0, $0, 1	#return true
	
	lw $ra, 0($sp)	#Restore SP
	lw $s0, 4($sp)	#Restore Memory pointer
	lw $s1, 8($sp)	#Restore Row
	lw $s2, 12($sp)	#Restore Column
	lw $s3, 16($sp)	#Restore Boolean
	lw $s4, 20($sp)	#Restore i counter/guess
	addi $sp, $sp, 24
	jr $ra
	
conflict2:
	#Restore C and move back a cell
	addi $s0, $s0, -1#Move memory pointer back 1 cell
	addi $s2, $s2, -1
	sb $0, 0($s0)	#put i into the cell at row r column c;
conflict:
	addi $s4, $s4, 1#Increment i counter/guess
	j is0
doneLoop:
	sb $0, 0($s0)	#Put 0 back to the cell @ row r col c
	add $v0, $0, $0 #Return false
	
	lw $ra, 0($sp)	#Restore SP
	lw $s0, 4($sp)	#Restore Memory pointer
	lw $s1, 8($sp)	#Restore Row
	lw $s2, 12($sp)	#Restore Column
	lw $s3, 16($sp)	#Restore Boolean
	lw $s4, 20($sp)	#Restore i counter/guess
	addi $sp, $sp, 24
	jr $ra
	
#Checks if the row already contains the number
#Arguments:
#	$a0: Current col in row
#	$a1: Current memory location
#	$a2: Number to check
#Return:
#	$v0: 0 or 1. 0=number in $a0 already exists in the current column
_checkRow:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#Move memory pointer to beginning of the row
	sub $a1, $a1, $a0
	add $t0, $0, $0	#Loop counter
	add $t1, $0, $0	#Used for temp calculations
checkRowLoop:
	beq $t0, 9, notInRow
	
	lb $t1, 0($a1)
	beq $t1, $a2, inRow

	addi $a1, $a1, 1	#Move the memory pointer to the right 1 cell in the grid
	addi $t0, $t0, 1	#Increase the counter
	j checkRowLoop

notInRow:
	addi $v0, $0, 1	#Number not in the row
	j doneCheckRow
inRow:
	add $v0, $0, $0	#Number found in the row
	
doneCheckRow:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	

#Checks if the column already contains the number
#Arguments:
#	$a0: Current row
#	$a1: Current memory location
#	$a2: Number to check
#Return:
#	$v0: 0 or 1. 0=number in $a0 already exists in the current column
_checkColumn:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#Move memory pointer to beginning of the row
	addi $t0, $0, 9
	mult $a0, $t0
	mflo $a0
	sub $a1, $a1, $a0
	add $t0, $0, $0		#Loop counter
	add $t1, $0, $0		#Used for temp calculations
checkColLoop:
	beq $t0, 9, notInCol
	
	lb $t1, 0($a1)
	beq $t1, $a2, inCol

	addi $a1, $a1, 9	#Move the memory pointer down 1 row
	addi $t0, $t0, 1	#Increase the counter
	j checkColLoop

notInCol:
	addi $v0, $0, 1	#Number not in the column
	j doneCheckCol
inCol:
	addi $v0, $0, 0	#Number found in the column
	
doneCheckCol:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#Checks if the guess is already in the subgrid
#Arguments:
#	$a0: Current row
#	$a1: Current column
#	$a2: Current memory location
#	$a3: Number to check
#Return:
#	$v0: 0 or 1. 0=number already exists in the current column
_checkSubgrid:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#Check the column of the subgrid
	beq $a0, 0, subCol	#1st row of subgrid
	beq $a0, 3, subCol	#1st row of subgrid
	beq $a0, 6, subCol	#1st row of subgrid

	beq $a0, 1, subR2	#2nd row of subgrid	
	beq $a0, 4, subR2	#2nd row of subgrid
	beq $a0, 7, subR2	#2nd row of subgrid
	
	#Else 3rd row of the subgrid
	addi $a2, $a2, -18	#Move pointer up 2 rows
	j subCol
	
subR2: #Left column 3rd row of subgrid
	addi $a2, $a2, -9	#Move pointer up 1 row

subCol:			
	beq $a1, 0, searchGrid	#Left column of subgrid
	beq $a1, 3, searchGrid	#Left column of subgrid
	beq $a1, 6, searchGrid	#Left column of subgrid
	
	beq $a1, 1, midCol	#Middle column of subgrid
	beq $a1, 4, midCol	#Middle column of subgrid
	beq $a1, 7, midCol	#Middle column of subgrid

	#Else right column of the subgrid
	add $a2, $a2, -2	#Move pointer 2 columns to the left
	j searchGrid
	
			
midCol: #Middle column of the subgrid
	add $a2, $a2, -1	#Move pointer one column to the left
	
searchGrid:
	add $t0, $0, $0		#$t0 will hold value of the cells in the subgrid
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 1st cell of subgrid
	
	#Move to 2nd subcell
	addi $a2, $a2, 1
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 2nd cell of subgrid
	
	#Move to 3rd subcell
	addi $a2, $a2, 1
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 3rd cell of subgrid
	
	#Move to 6th subcell
	addi $a2, $a2, 9
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 6th cell of subgrid
	
	#Move to 5th subcell
	addi $a2, $a2, -1
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 5th cell of subgrid

	#Move to 4th subcell
	addi $a2, $a2, -1
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 4th cell of subgrid
	
	#Move to 7th subcell
	addi $a2, $a2, 9
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 7th cell of subgrid
	
	#Move to 8th subcell
	addi $a2, $a2, 1
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 8th cell of subgrid
	
	#Move to 9th subcell
	addi $a2, $a2, 1
	lb $t0, 0($a2)
	beq $t0, $a3, inGrid	#Value $a3 is in 3rd cell of subgrid
	
	#Else value not in the subgrid
	addi $v0, $0, 1		#Return true since the value isn't in the subgrid alread	
	j doneSubGrid
	
inGrid:
	add $v0, $0, $0	#Return false since the value is in the subgrid already

doneSubGrid:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

end: # Terminate Program

	addi $v0, $0, 10	# Syscall 10: Terminate program
	syscall			# Terminate program