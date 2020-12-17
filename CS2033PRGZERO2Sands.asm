# goal: read an ASCII number string containing a positive or negative integer and put its integer representation in $v0
# note: does not currently support largest negative integer, -2147483648

.data
    buffer: .space 12		# create space for string (12 is chosen so that every 10 or fewer digit number (both positive and negative) is allowed)

.text

# entry point
main:
    # prepare for input
    li $v0, 8			# load service code for reading a string into $v0
    la $a0, buffer		# load address of input buffer into $ao
    li $a1, 12			# load buffer length into $a1
    syscall			# issue syscall for reading string
    
    # initialize values
    move $t0, $a0		# initialize buffer index
    move $t1, $zero		# initialize accumulator
    li $t2, 1			# initialize place
    li $t3, 1			# initialize sign
    li $t7, 0			# flag for whether number is valid (0 for invalid, 1 for valid), used for identifying these single-character edge-cases (backspace, enter, "-")
    
    # loop through characters
    loop1:
        lbu $t4, 0($t0)		# load character at current index
        
        # check for null byte and newline
        beqz $t4, loop2		# exit loop if null byte is encountered
        beq $t4, 10, loop2	# exit loop if newline encountered
        
        # handle hyphen character
        bne $t4, 45, unsigned	# branch to unsigned if character is not 45 ("-")
        bne $t0, $a0, error 	# branch to error if hyphen is not at first index
	li $t3, -1		# set sign to -1
	addi $t0, $t0, 1	# increment buffer index
	j loop1			# go to next iteration of loop
	unsigned:
        
        # handle non digit character
        bltu $t4, 48, error	# branch to error if character is below 48 ("0")
        bgtu $t4, 57, error	# branch to error if character is above 57 ("9")
        
   	addi $t0, $t0, 1	# increment buffer index
   	j loop1			# begin next iteration of loop
    
    # loop backwards through digits
    loop2:
        subi $t0, $t0, 1	# decrement buffer index
        lbu $t4, 0($t0)		# load character at current index
        
    	# check bounds
    	blt $t0, $a0, exit	# exit loop if outside buffer
    	
    	 # check for negative
        beq $t4, 45, exit	# exit loop if character is 45 ("-")
    	
        # get integer value of digit
        subi $t5, $t4, 48	# subtract 48 ("0") to get integer from character
        
        # calculate contribution
        mul $t5, $t5, $t2	# mutliply value by place
        
        # check for overflow
        bltz $t5, error		# branch to error if overflow occured
        
        # update values
        addu $t1, $t1, $t5	# add scaled value to accumulator
        li $t7, 1		# set flag for valid number found
       
       # check for overflow
        bltz $t1, error		# branch to error if overflow occured
        
        mulu $t2, $t2, 10	# scale place by 10
            
        j loop2		# begin next iteration of loop
    
    exit:
    	beqz $t7, error		# branch to error if input is invalid (backspace, "-", or enter were the only input)
    	mul $v0, $t1, $t3	# multiply accumulator by sign and store in $v0
    	j end			# "return"
    	
    error:
    	li $v0, -1		# load -1 into $v0 as specified
    	j end			# "return"

# used to allow program to drop off bottom, as requested
end:
