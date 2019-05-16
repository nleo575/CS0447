.data
	buffer:		.space	102
	header:		.space	15
	.align	2
	dibSize:	.space	4
	
	# New line & Space
	newLine:	.asciiz "\n"
	space:		.asciiz " "
	
	# Prompts
	prompt: 	.asciiz "Please enter a filename: "
	fileSize:	.asciiz "The size of the BMP file (bytes): "
	first2:		.asciiz "The first two characters: "
	starting:	.asciiz "The starting address of image data: "
	width: 		.asciiz "Image width (pixels): "
	height: 	.asciiz "Image height (pixels): "
	planes: 	.asciiz "The number of color planes: "
	bpp:		.asciiz "The number of bits per pixel: "
	compMethod:	.asciiz "The compression method: "
	rawSize:	.asciiz "The size of raw bitmap data (bytes): "
	hRes:		.asciiz "The horizontal resolution (pixels/meter): "
	vRes:		.asciiz "The vertical resolution (pixels/meter): "
	numColors:	.asciiz "The number of colors in the color palette: "
	importantColors:.asciiz "The number of important colors used: "
	index0:		.asciiz "The color at index 0 (B G R): "
	index1:		.asciiz "The color at index 1 (B G R): "	
	
.text
	# Prompt the user for the filename
	addi $v0, $0, 4		# Syscall 4: Print string
	la   $a0, prompt	# Set the string to print to prompt
	syscall			# Print "Pleas enter a..."
	
	# Read in filename
	addi $v0, $0, 8		# Syscall 8: Read string
	la   $a0, buffer	# Set the buffer
	addi $a1, $0, 100	# Set the maximum to 100 (size of the buffer)
	syscall
	
	la $t0, buffer       	# Load buffer address into $t0 (will need to incremenet to read chars)
        add $t1, $0, $0    	# Reset $t1 to 0. Will be used to store characters
	
	#Need to test each character for line feed character (ASCII 0x0A (10 in decimal))
lfTest:
	lbu $t1, 0($t0)		# Load next character (1 byte) from buffer into $t1

	beq $t1, 10, endString	# Test for lf, if no lf, then end of string
	addi, $t0, $t0, 1	# Increase counter by 1 (1 char is 1 byte)
	j lfTest

endString:
	sb $0, 0($t0)		# Replace lf char with null 
	
# Open file
	addi $v0, $0, 13	# Syscall 13: Open file
	la   $a0, buffer	# $a0 is the address of filename
	add  $a1, $0, $0	# $a1 = 0
	add  $a2, $0, $0	# $a2 = 0
	syscall			# Open file
	add  $s0, $0, $v0	# Copy the file descriptor to $s0
	
# Read the file header
	addi $v0, $0, 14	# Syscall 14: Read file
	add  $a0, $0, $s0	# $a0 is the file descriptor
	la   $a1, header	# $a1 is the address of a buffer (header)
	addi $a2, $0, 14	# $s2 is the number of bytes to read
	syscall			# Read file
	
# Print first 2 bytes of DIB header
	la   $a0, first2
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The first two..."
	
	la   $s1, header	# Set $s1 to the address of DIB header
	
	addi $v0, $0, 11	# Syscall 11: Print character
	lb   $a0, 0($s1)	# $a0 is the first byte of header
	syscall			# Print a character
	lb   $a0, 1($s1)	# $a0 is the second byte of header
	syscall			# Print a character
	
	jal _newLine
	
# Print out file size
	la   $a0, fileSize
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The size of..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 2($s1)	# $a0 is the first 4-byte integer
	syscall			# Print an integer
	
	jal _newLine
	
	la   $a0, starting
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The starting add..."
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 10($s1)	# $a0 = data offset
	add $s2, $0, $a0	# Copy data offset into $s2
	syscall			# Print an integer
	
	jal _newLine
	
# Read in DIB size
	addi $v0, $0, 14	# Syscall 14: Read file
	add  $a0, $0, $s0	# $a0 is the file descriptor
	la   $a1, dibSize	# $a1 is the address of a buffer (header)
	addi $a2, $0, 4		# $a2 is the number of bytes to read
	syscall			# Read file
		
# Allocate memory to store DIB - DIB size
	addi $v0, $0, 9		# Syscall 9: Allocate heap memory
	lw  $a0, dibSize	# $a0 = DIB size - 4 bytes
	addi $a0, $a0, -4
	syscall			# Allocate memeory
	add  $s3, $0, $v0	# Store address of DIB
	
# Read in DIB 
	addi $v0, $0, 14	# Syscall 14: Read file
	add  $a0, $0, $s0	# $a0 is the file descriptor
	add  $a1, $0, $s3	# $a1 is the address of a buffer ($s3 = DIB)
	lw $a2, dibSize		# $a2 is the number of bytes to read (DIB header - 4)
	addi $a2, $a2, -4
	syscall			# Read file
	
# Print DIB information
	la   $a0, width
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "Image width..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 0($s3)	# $a0 = image width
	syscall			# Print an integer

	jal _newLine

	la   $a0, height
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "Image height..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 4($s3)	# $a0 = image height
	syscall			# Print an integer

	jal _newLine

	la   $a0, planes
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The number of color planes..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lh   $a0, 8($s3)	# $a0 = number of color planes
	syscall			# Print an integer

	jal _newLine

	la   $a0, bpp
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The number of bits..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lh   $a0, 10($s3)	# $a0 = bits per pixel
	syscall			# Print an integer

	jal _newLine

	la   $a0, compMethod
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The compression..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 12($s3)	# $a0 = compression
	syscall			# Print an integer

	jal _newLine

	la   $a0, rawSize
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The size of raw..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 16($s3)	# $a0 = raw size
	syscall			# Print an integer

	jal _newLine

	la   $a0, hRes
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The horizontal..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 20($s3)	# $a0 = horizontal resolution
	syscall			# Print an integer																								

	jal _newLine

	la   $a0, vRes
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The vertical..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 24($s3)	# $a0 = vertical resolution
	syscall			# Print an integer	

	jal _newLine

	la   $a0, numColors
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The number of colors in..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 28($s3)	# $a0 = num colors in color palette
	syscall			# Print an integer	

	jal _newLine
  
 	la   $a0, importantColors
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The number of important..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lw   $a0, 32($s3)	# $a0 = num of important colors
	syscall			# Print an integer	

	add $t0, $0, $a0	# Copy num of important colors into $t0
	jal _newLine

# Print out colors
	# Allocate memory to store colors
	addi $v0, $0, 9		# Syscall 9: Allocate heap memory
	sll $a0, $t0, 2		# $a0 = num colors * 4 (4 bytes per color)	
	syscall			# Allocate memeory
	add  $s4, $0, $v0	# Store address of colors
	
	# Read in colors 
	addi $v0, $0, 14	# Syscall 14: Read file
	add $a2, $0, $a0	# $a2 is the number of bytes to read (still stored in $a0)
	add  $a0, $0, $s0	# $a0 is the file descriptor
	add  $a1, $0, $s4	# $a1 is the address of a buffer ($s4 = colors)
	syscall			# Read file
	
	la   $a0, index0
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The color at index 0..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lbu   $a0, 0($s4)	# $a0 = B color
	syscall			# Print an integer
	
	jal _space
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lbu   $a0, 1($s4)	# $a0 = G color
	syscall			# Print an integer
	
	jal _space

	addi $v0, $0, 1		# Syscall 1: Print integer
	lbu   $a0, 2($s4)	# $a0 = R color
	syscall			# Print an integer
	
	jal _newLine

	la   $a0, index1
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print "The color at index 1..."	
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lbu   $a0, 4($s4)	# $a0 = B color
	syscall			# Print an integer
	
	jal _space
	
	addi $v0, $0, 1		# Syscall 1: Print integer
	lbu   $a0, 5($s4)	# $a0 = G color
	syscall			# Print an integer
	
	jal _space

	addi $v0, $0, 1		# Syscall 1: Print integer
	lbu   $a0, 6($s4)	# $a0 = R color
	add $t7, $0, $a0
	syscall			# Print an integer

	sll $t7, $t7, 24
	sra $s7, $t7, 24
		
# Print image
	# Allocate memory to store image data
	addi $v0, $0, 9		# Syscall 9: Allocate heap memory
	lw   $a0, 16($s3)	# $a0 = raw size of image ($s3 is address of DIB header)	
	syscall			# Allocate memeory
	add  $s5, $0, $v0	# Store address of image data in $s5
	
	# Read in image data 
	addi $v0, $0, 14	# Syscall 14: Read file
	add $a2, $0, $a0	# $a2 is the number of bytes to read (still stored in $a0)
	add  $a0, $0, $s0	# $a0 = file descriptor ($s0)
	add  $a1, $0, $s5	# $a1 is the address of a buffer ($s5 = image data)
	syscall			# Read file

	lw   $s0, 0($s3)	# Get horizontal dimension (columns)
	
	lw   $s1, 4($s3)	# Get vertical dimension (rows)
	lw   $s2, 16($s3)	# Get raw size (bytes)
	
	div $s2, $s1		# Calculate bytes/row
	mflo $s3		# S3 = bytes/row (i.e. width of data (bytes) for 1 row)

	add $s5, $s5, $s2 	# First move addres to end of image data. 
	sub $s5, $s5, $s3	# Then initialize it to the top left pixel of the image
	sw $s5, buffer		# Save this position in the buffer
	
	addi $t7, $0, 8
	mult $t7, $s3
	mflo $t7
	sw $t7, buffer+4	# Save this calculation (row bytes * 8) in the buffer at 2nd word
	
	add $s6, $0, $0		# Will keep track of current index of byte in the current row
				# Will compare later on tow $s3 (bytes/row) to determine how to move pointer)
	addi $t4, $0, 1		# Counter for number of times the memory pointer was moved down 8 rows
printLoop: 
	blez $s1, donePrint	# Printing finised once all rows are printed ($s1 < 0)
	add $s4, $0, $0		# Resets width (pixels) to print
	add $s6, $0, $0		# Reset byte index to 0 for new row
	
	getBytes:	
		bge $s4, $s0 whiteSpace	# No more pixels to print in this row, check if there are more rows to print
		
		addi $s6, $s6, 1	# increase byte counter by 1
		add $t0, $0, $0		# Holds current 8 pixels (byte) of the current row
		add $t1, $0, $0		# Holds next 8 pixels to print for top 4 print heads 
					# 77777777 | 66666666 | 55555555 | 44444444
		add $t2, $0, $0		# Holds next 8 pixels to print for lower 4 print heads 
					# 33333333 | 22222222 | 11111111 | 00000000
		add $t3, $0, $0		# Used for temporary calculations/counters
		
		# $t5 Counts how many rows down the program goes when it loads new bytes
		add $t6, $0 $0		# Counts up to 8 to test whether there are columns left to print
		# $t7 Will be used for temporary calculations
		# $t8 is the printhead
		# $t9 signals the printer to print 1 column, 8 pixels in height

	byteLoop:
		addi $t7, $s1, -1	# Check if there's another row to get data from (there must be @ least 1)
		add $t3, $0, $0		# Resets counter to 0
		add $t5, $0, $0		# Resets counter to 0
		upperHalf:
			beq $t3, 4, lowerHalf	# Loop runs 4 times
			sll $t1, $t1, 8		# Shift left 8 bits to make room for next byte
			ble $t3, $t7, nextUpper	# Check if another remains
			j continue1
			nextUpper:	lbu $t0, 0($s5)		# Get the next byte
					sub $s5, $s5, $s3	# Move memory pointer to next row
					or $t1, $t1, $t0	# Or $t1 with new byte and store in $t1	
					addi $t5, $t5, 1	# 1 row down	
			continue1:	addi $t3, $t3, 1	# Increase counter by 1
		j upperHalf
		
		lowerHalf:
			beq $t3, 8, movePointer	# Loop runs 4 times then moves memory pointer to next column or down 8 rows
			sll $t2, $t2, 8		# Shift left 8 bits to make room for next byte
			ble $t3, $t7, nextLower	# Check if another remains
			j continue2
			
			nextLower:	lbu $t0, 0($s5)		# Get the next byte
					sub $s5, $s5, $s3	# Move memory pointer to next row
					or $t2, $t2, $t0	# Or $t2 with new byte and store in $t2	
					addi $t5, $t5, 1	# 1 row down	
			continue2:	addi $t3, $t3, 1	# Increase counter by 1
		j lowerHalf
		
		movePointer:
		
			addi $t7, $s4, 1	# Check if there's at least 1 more pixel in the row
			bgt  $t7,  $s0, whiteSpace # If no pixels remain in the row, move down 8 rows
						# Otherwise, reset the print head for the next loop
			#Check how many rows you went down to begin with

			add $t3, $0, $0		#Reset Counter to 0
		columnLoop:
			beq $t3, $t5, rightByte		# Loop runs up to 8 times
 				add $s5, $s5, $s3	# Move memory pointer up to previous row	
				addi $t3, $t3, 1	# Increase counter by 1
		j columnLoop
	
		rightByte: # Move memory pointer 1 byte to the right to get next 8 bits
			addi $s5, $s5, 1	# Get next byte to the right
			j loadPrintHead
		
		moveDown: # Reached end of line. Move pointer to beginning of line, 8 lines down

			lw $s5, buffer		# Restore last beginning of line from buffer
			lw $t7, buffer + 4	# Restore 8 lines (bytes) from 2nd word in buffer
			sub $s5, $s5, $t7	# Subtract 8 lines from last starting position
			sw $s5, buffer		# Save updated position to the buffer

			beq $s4, $s0, whiteSpace# No more pixels to print in this row. Print white space until the end

	loadPrintHead:
		
		add $t8, $0, $0		# Reset printhead to 0
			
		beq $t1, 0xffffffff, testT2 # Check for solid white or black 
		beqz  $t1, testT2	    # blocks which can be optomized with a loop
			j continue
	testT2:	beq  $t2, $t1 print8
		beqz $t1, fourth
	continue:
		add $t7, $0, 0x80000000	# Prepare to get 8th bit
		
		and $t3, $t1, $t7	# Get 8th bit
		srl $t3, $t3, 24	# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead
		srl $t7, $t7, 8		# Prepare to get 7th bit
		
		and $t3, $t1, $t7	# Get 7th bit
		srl $t3, $t3, 17	# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead
		srl $t7, $t7, 8		# Prepare to get 6th bit

		and $t3, $t1, $t7	# Get 6th bit
		srl $t3, $t3, 10	# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead
		srl $t7, $t7, 8		# Prepare to get 5th bit
					
		and $t3, $t1, $t7	# Get 5th bit
		srl $t3, $t3, 3		# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead
			
	fourth:	add $t7, $0, 0x80000000
		and $t3, $t2, $t7	# Get 4th bit
		srl $t3, $t3, 28	# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead
		srl $t7, $t7, 8		# Prepare to get 3rd bit

		and $t3, $t2, $t7	# Get 3rd bit
		srl $t3, $t3, 21	# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead
		srl $t7, $t7, 8		# Prepare to get 2nd bit

		and $t3, $t2, $t7	# Get 2nd bit
		srl $t3, $t3, 14	# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead
		srl $t7, $t7, 8		# Prepare to get 1st bit
		
		and $t3, $t2, $t7	# Get 1st bit
		srl $t3, $t3, 7		# Move bit into place
		or $t8, $t8, $t3	# Or bit into printhead	
		
		sll $t1, $t1, 1		# Shift high bits 1 bit to the left for next load
		sll $t2, $t2, 1		# Shift lower bits 1 bit to the left for next load
				
	# Printhead loaded
		xor $t8, $t8, $s7
		print:
			addi $t9, $0, 1		# Set $t9 to 1 (to print)
		wait: 	bne  $t9, $0, wait	# Wait until $t9 is 0
		
		addi $s4, $s4, 1	# Add 1 to columns printed	
		beq $s4, $s0, whiteSpace# If End of line is reached, print white space
		
		# If end of line isn't reached, then print next pixel in $t1/$t2	
		addi $t6, $t6, 1		# Increment counter to check if there is data left in $t1/$t2 to print
		blt $t6, 8, loadPrintHead	# Check if there are any columns left to print in $t1/$t2
		
		j getBytes

print8:
	add $t7, $0, $0
	xor $t8, $s7, $t1
	p8Loop:
		beq $t7, 8, getBytes

		addi $t7, $t7, 1	# Increment
		addi $t9, $0, 1		# Set $t9 to 1 (to print)
	wait2: 	bne  $t9, $0, wait2	# Wait until $t9 is 0

		addi $s4, $s4, 1	# Add 1 to columns printed
		beq $s4, $s0, whiteSpace# Check if end of line reached	
		
		# If end of line isn't reached, then print next pixel in $t1/$t2	
		addi $t6, $t6, 1	# Increment counter to check if there is data left in $t1/$t2 to print
		blt $t6, 8, p8Loop#	 Check if there are any columns left to print in $t1/$t2

	j getBytes
	

# Print white space until the end of line
whiteSpace:	
	addi $t8, $0,0	# Set print head to 0 (white space)
	add $t7, $0, $s0		# $t7 = number of pixels printed
	
	printWhiteSpace:
		bge  $t7, 480, eol
		addi $t7, $t7, 1	# Increment
		addi $t9, $0, 1		# Set $t9 to 1 (to print)
	wait1: 	bne  $t9, $0, wait1	# Wait until $t9 is 0


		j printWhiteSpace	# Jumpt to continue printing white space until the end of the line
	
eol: #End of line reached

	lw $s5, buffer
	lw $t7, buffer + 4
	sub $s5, $s5, $t7
	sw $s5, buffer
	addi $s1, $s1, -8	# Subtract 8 rows from total rows
	j printLoop
	
donePrint:
	# Close file
	add  $v0, $0, 16	# Syscall 16: Close file
	add  $a0, $0, $s0	# $a0 is the file descriptor
	syscall			# Close file
	# Terminate Program
	addi $v0, $0, 10	# Syscall 10: Terminate program
	syscall			# Terminate program

_newLine: la   $a0, newLine
	j printStr

_space: la   $a0, space

printStr:
	add  $v0, $0, 4		# Syscall 4: Print string
	syscall			# Print lf "\n"

	jr $ra
