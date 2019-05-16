.data
	buffer:	.space	9 
	comma:.asciiz ", "
	label: 	.asciiz "Label"
	lparen:	.asciiz "("
	mem_a: 	.asciiz "$a"
	mem_at: .asciiz "$at"
	mem_fp: .asciiz "$fp"
	mem_gp: .asciiz "$gp"
	mem_k: 	.asciiz "$k"
	mem_ra: .asciiz "$ra"
	mem_s: 	.asciiz "$s"
	mem_sp: .asciiz "$sp"
	mem_t: 	.asciiz "$t"
	mem_v: 	.asciiz "$v"
	mem_0: 	.asciiz "$zero"
	nl: 	.asciiz "\n"
	prompt: .asciiz "Please enter a machine code (hexadecimal) 00000000 to quit: "
	rparen:	.asciiz ")"
	taskadd: .asciiz "add "
	taskaddi:.asciiz "addi "
	taskand: .asciiz "and "
	taskandi:.asciiz "andi "
	taskbeq: .asciiz "beq "
	taskbne: .asciiz "bne "
	taskinvalid: .asciiz "Invalid"
	taskj:   .asciiz "j Label"
	taskjal: .asciiz "jal Label"
	taskjr:  .asciiz "jr "
	tasklb:  .asciiz "lb "
	tasklh:  .asciiz "lh "
	tasklw:  .asciiz "lw "
	tasknor: .asciiz "nor "
	taskor:  .asciiz "or "
	taskori: .asciiz "ori "
	tasksb:  .asciiz "sb "
	tasksh:  .asciiz "sh "
	tasksll: .asciiz "sll "
	taskslt: .asciiz "slt "
	taskslti:.asciiz "slti "
	tasksrl: .asciiz "srl "
	tasksub: .asciiz "sub "
	tasksw:  .asciiz "sw "


.text 
begin:
	addi $v0, $zero, 4			
	la $a0, prompt		
	syscall			
	addi $v0, $zero, 8
	la $a0, buffer
	addi $a1, $zero, 9	#truncates null terminator
	syscall
	jal	_nl
	la $t1, buffer
	add $t0, $zero, $zero	#incrementer to track conversion 
	add $s0, $zero, $zero	#will hold the converter number
	add $t2, $zero, $zero	#will carry each byte of input to the $s0 register
converterLoop:
	beq $t0, 8, convertDone
	sll $s0, $s0, 4		#shifts $s0 left by one byte for next loop cycle
	lb $t2, 0($t1) 		#carry the character to s0
	slti $t3, $t2, 58	#sets t3 equal to 1 if t2 is a number; if it is letter A - F then the result will be 0
	beq $t3, 1, num
character:
	subi $t2, $t2, 87	#subtracts the proper amount from the character if it is A-F, giving the decimal value of it
	j	store
num:
	subi $t2, $t2, 48	#subtracts the proper amoutn from the character if it is 0 - 9, giving its decimal value
store:
	or $s0, $s0, $t2	#puts the decimal result of the input string character into $s0
	addi $t0, $t0, 1	#increments counter
	addi $t1, $t1, 1	#increments buffer
	j	converterLoop
convertDone:			#result is now in s0!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!BenchMark!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
instructionType:
	beq $s0, $zero, end
	add $t0, $zero, $zero	#resets temp registers
	add $t1, $zero, $zero	#
	add $t2, $zero, $zero	#
	add $t3, $zero, $zero	#
	add $t0, $s0, $zero	#copies s0 to t0 for manipulation
	srl $t0, $t0, 26	#shift t0 bits out until only the top 6 remain (WHICH IS THE OPCODE)
	beq $t0, 0, rType	#branches to rType if opcode is 0
	beq $t0, 2, jTypeDone
	beq $t0, 3, jType
iType:
	beq $t0, 4, taskbeq_
	beq $t0, 5, taskbne_
	beq $t0, 8, taskaddi_
	beq $t0, 10, taskslti_
	beq $t0, 12, taskandi_
	beq $t0, 13, taskori_
	beq $t0, 32, tasklb_
	beq $t0, 33, tasklh_
	beq $t0, 35, tasklw_
	beq $t0, 40, tasksb_
	beq $t0, 41, tasksh_
	beq $t0, 43, tasksw_
	j	nonsense

taskbeq_: 	
	la $a0, taskbeq
	j printstrings 
taskbne_: 	
	la $a0, taskbne
	j printstrings 
taskaddi_: 	
	la $a0, taskaddi
	j printstrings 
taskslti_: 	
	la $a0, taskslti
	j printstrings 
taskandi_: 	
	la $a0, taskandi
	j printstrings 
taskori_: 	
	la $a0, taskori
	j printstrings 
tasklb_: 	
	la $a0, tasklb
	j printstrings 
tasklh_: 	
	la $a0, tasklh
	j printstrings 
tasklw_: 	
	la $a0, tasklw
	j printstrings 
tasksb_: 	
	la $a0, tasksb
	j printstrings 
tasksh_: 	
	la $a0, tasksh
	j printstrings 
tasksw_: 	
	la $a0, tasksw
	j printstrings 
	
	
	
	
rType:
	andi $t4, $s0, 0x3f
	beq $t4, 8, jayAre
	blt $t4, 8, shifty
else:
	beq $t4, 32, taskadd_
	beq $t4, 34, tasksub_
	beq $t4, 36, taskand_
	beq $t4, 37, taskor_
	beq $t4, 39, tasknor_
	beq $t4, 42, taskslt_

taskadd_: 	
	la $a0, taskadd
	j printFunct 
tasksub_:
	la $a0, tasksub
	j printFunct 
taskand_:
	la $a0, taskand
	j printFunct 
taskor_:
	la $a0, taskor
	j printFunct 
tasknor_:
	la $a0, tasknor
	j printFunct 
taskslt_:
	la $a0, taskslt
printFunct:
	addi $v0, $zero, 4
	syscall	
		
	jal _rd
	jal _comma
	jal _rs
	jal _comma
	jal _rt
	jal _nl
	j	begin
jayAre:
	la $a0, taskjr
	addi $v0, $zero, 4
	syscall	
	jal _rs
	jal _nl
	
	j	begin
shifty:
	bne $t4, 0, shiftyR
	la $a0, tasksll
	j shiftNext
shiftyR:la $a0, tasksrl

shiftNext:
	addi $v0, $zero, 4
	syscall	
	
	jal _rd
	jal _comma
	jal _rt
	jal _comma
	jal _shamt
	jal _nl
	j	begin
jType:
	addi $v0, $zero, 4
	la $a0, taskjal
	syscall

	jal _nl
	j	begin
jTypeDone:
	addi $v0, $zero, 4
	la $a0, taskj
	syscall
	
	jal _nl
	j	begin
printstrings:
	addi $v0, $zero, 4
	syscall
	j	registers
nonsense:
	add $v0, $zero, 4
	la $a0, taskinvalid
	syscall
	jal	_nl
	j	begin
registers:
	beq $t0, 4, areEss
	beq $t0, 5, areEss
	blt $t0, 14, areTee
	j	_areTee2
areEss:
	jal	_rs
	jal	_comma
	jal	_rt
	jal	_comma
	jal 	_label
	jal 	_nl
	j	begin
areTee:
	jal	_rt
	jal	_comma
	jal	_rs
	jal	_comma
	jal	_imm
	jal 	_nl
	j	begin
_areTee2:
	jal	_rt
	jal	_comma
	jal	_imm
	addi $v0, $zero, 4
	la $a0, lparen	
	syscall
	jal	_rs
	addi $v0, $zero, 4
	la $a0, rparen	
	syscall
	jal 	_nl
	j	begin
_imm:
	andi $a0, $s0, 0xffff
	sll $a0, $a0, 16
	sra $a0, $a0, 16
	add $v0, $zero, 1
	syscall
	jr $ra
_rd:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	srl $t1, $s0, 11
	andi $a0, $t1, 0x1f
	jal	_regies
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
		
_regies:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	add $t1, $a0, $zero
	
	beq $t1, 0, zero
	beq $t1, 1, one
	beq $t1, 28, twentyEight
	beq $t1, 29, twentyNine
	beq $t1, 30, thirty
	beq $t1, 31, thirtyone
	blt $t1, 4, vee
	blt $t1, 8, aye
	blt $t1, 16 tee1
	blt $t1, 24 ess
	blt $t1, 26, tee2
	blt $t1, 28, kay
	
zero:
	la $a0, mem_0
	j	doneregs
one:
	la $a0, mem_at

	j	doneregs
twentyEight:
	la $a0, mem_gp

	j	doneregs
twentyNine:
	la $a0, mem_sp

	j	doneregs
thirty:
	la $a0, mem_fp

	j	doneregs
thirtyone:
	la $a0, mem_ra

	j	doneregs
	
vee: 
	la $a0, mem_v
	subi $t3, $t1, 2
	j	doneregs2
aye:
	la $a0, mem_a
	subi $t3, $t1, 4
	j	doneregs2
tee1:
	la $a0, mem_t
	subi $t3, $t1, 8
	j	doneregs2
ess:
	la $a0, mem_s
	subi $t3, $t1, 16
	j	doneregs2
tee2:
	la $a0, mem_t
	subi $t3, $t1, 24
	j	doneregs2
kay:
	la $a0, mem_k
	subi $t3, $t1, 26
	j	doneregs2
doneregs:
	add $v0, $zero, 4
	syscall
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
doneregs2:
	add $v0, $zero, 4
	syscall
	
	add $v0, $zero, 1
	add $a0, $t3, $zero
	syscall	

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
_rs:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	srl $t1, $s0, 21
	andi $a0, $t1, 0x1f
	jal	_regies
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4	
	jr $ra
_rt:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	srl $t1, $s0, 16
	andi $a0, $t1, 0x1f
	jal	_regies

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
		
_shamt:
	srl $t1, $s0, 6
	andi $a0, $t1, 0x1f
	add $v0, $zero, 1
	syscall
	jr $ra	
	
_comma:
	addi $v0, $zero, 4
	la $a0, comma	
	syscall
	jr	$ra
_label:
	addi $v0, $zero, 4
	la $a0, label	
	syscall
	jr	$ra
_nl:
	add $v0, $zero, 4
	la $a0, nl
	syscall
	jr	$ra
	
end:
	addi $v0, $zero, 10
	syscall
