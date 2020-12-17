# goal: read a 32 bit integer multiplicand and multiplier and perform multiplication using booths algorithm

.data
    multiplicand: .asciiz	"\nEnter multiplicand: "
    multiplier: .asciiz		"\nEnter multiplier: "
    invalidmsg: .asciiz		"\nInvalid: input is not an integer"
    overflowmsg: .asciiz	"\nOverflow: input magnitude too large"
    newline: .asciiz		"\n"
    space: .asciiz		" "
    x: .asciiz			"x"
    smallbar: .asciiz		"----------------------------------"
    bigbar: .asciiz		"----------------------------------------------------------------"
    buffer: .space 12		# create space for string (12 is chosen so that every 10 or fewer digit number (both positive and negative) is allowed)

.text

# entry point
main:
    # prompt user to enter multiplicand
    la $a0, multiplicand	# load address of multiplicand prompt into $a0
    jal printstr		# print the prompt
    
    # read multiplicand input
    la $a0, buffer		# load address of input buffer into $ao
    li $a1, 12			# load buffer length into $a1
    jal readint 		# read multiplicand
    move $s0, $v0		# put multiplicand in $s0

    # prompt user to enter multiplier
    la $a0, multiplier		# load address of multiplier prompt into $a0
    jal printstr		# print the prompt
    
    # read multiplier input
    la $a0, buffer		# load address of input buffer into $ao
    li $a1, 12			# load buffer length into $a1
    jal readint			# read multiplier
    move $s1, $v0		# put multiplier in $s1
    
    # perform multiplication using booth's algorithm
    move $a0, $s0		# put multiplicand in $a0
    move $a1, $s1		# put multipier in $a1
    jal booths			# run booth's algorithm
    
    j exit			# terminate program

# prompts user for input and returns its integer value in $v0 assuming address of buffer to be in $a0 and length to be in $a1
readint:
    # prepare for input
    li $v0, 8			# load service code for reading a string into $v0
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
        bne $t0, $a0, invalid 	# branch to error if hyphen is not at first index
	li $t3, -1		# set sign to -1
	addi $t0, $t0, 1	# increment buffer index
	j loop1			# go to next iteration of loop
	unsigned:
        
        # handle non digit character
        bltu $t4, 48, invalid	# branch to error if character is below 48 ("0")
        bgtu $t4, 57, invalid	# branch to error if character is above 57 ("9")
        
   	addi $t0, $t0, 1	# increment buffer index
   	j loop1			# begin next iteration of loop
    
    # loop backwards through digits
    loop2:
        subi $t0, $t0, 1	# decrement buffer index
        lbu $t4, 0($t0)		# load character at current index
        
    	# check bounds
    	blt $t0, $a0, end	# exit loop if outside buffer
    	
    	 # check for negative
        beq $t4, 45, end	# exit loop if character is 45 ("-")
    	
        # get integer value of digit
        subi $t5, $t4, 48	# subtract 48 ("0") to get integer from character
        
        # calculate contribution
        mul $t5, $t5, $t2	# mutliply value by place
        
        # check for overflow
        bltz $t5, overflow	# branch to error if overflow occured
        
        # update values
        addu $t1, $t1, $t5	# add scaled value to accumulator
        li $t7, 1		# set flag for valid number found
       
       # check for overflow
        bltz $t1, overflow	# branch to error if overflow occured
        
        mulu $t2, $t2, 10	# scale place by 10
            
        j loop2			# begin next iteration of loop
    
    # return final result
    end:
    	beqz $t7, invalid	# branch to error if input is invalid (backspace, "-", or enter were the only input)
    	mul $v0, $t1, $t3	# multiply accumulator by sign and store in $v0
    	jr $ra			# return
    
    # print invalid input message and terminate program
    invalid:
    	la $a0, invalidmsg	# load address of invalid input string
    	jal printstr		# print the string
    	j exit			# exit program
    
    # print overflow message and terminate program
    overflow:
    	la $a0, overflowmsg	# load address of overflow input string
    	jal printstr		# print the string
    	j exit			# exit program

# prints string to console assuming address of string in $a0
printstr:
    li $v0, 4			# load service code for printing string into $v0
    syscall            		# issue syscall
    jr $ra			# return

# multiplies integers in $a0 and $a1 using booth's algorithm and stores result in $v0 (lo) and $v1 (hi)
booths:    
    # initialize values
    move $t0, $a1		# put multiplier in lower bits of product
    move $t1, $zero		# put zero in upper bits of product
    move $t2, $zero		# put zero in hidden bit
    move $t3, $a0		# save multiplicand
    move $t4, $zero		# put zero in counter
    
    
    # print newline
    li $v0, 4		        # load service code for printing string
    la $a0, newline		# load address of newline string into $a0
    syscall			# issue syscall
    
    # print space
    li $v0, 4		        # load service code for printing string
    la $a0, space		# load address of space string into $a0
    syscall			# issue syscall

    # print another space
    li $v0, 4		        # load service code for printing string
    la $a0, space		# load address of space string into $a0
    syscall			# issue syscall
    
    # print multiplicand
    li $v0, 35			# load service code for printing binary
    move $a0, $t3		# move multiplicand into $a0 for printing
    syscall			# issue syscall
    
    # print newline
    li $v0, 4		        # load service code for printing string
    la $a0, newline		# load address of newline string into $a0
    syscall			# issue syscall
    
    # print x
    li $v0, 4		        # load service code for printing string
    la $a0, x			# load address of x string into $a0
    syscall			# issue syscall
    
    # print space
    li $v0, 4		        # load service code for printing string
    la $a0, space		# load address of space string into $a0
    syscall			# issue syscall
    
    # print multiplier
    li $v0, 35			# load service code for printing binary
    move $a0, $t0		# move multiplier into $a0 for printing
    syscall			# issue syscall	
    
    # print newline
    li $v0, 4		        # load service code for printing string
    la $a0, newline		# load address of newline string into $a0
    syscall			# issue syscall
    
    # print small bar
    li $v0, 4		        # load service code for printing string
    la $a0, smallbar		# load address of small bar string into $a0
    syscall			# issue syscall
    
    # loop through booth's algorithm
    loop3:
        beq $t4, 32, done	# check for final iteration
        
        # look at LSB of product and hidden bit (00, 11, 01, or 10)
        andi $t5, $t0, 1	# get least significant bit from product
        beq $t5, $t2, skip	# skip if LSB equals hidden bit (11 or 00)
        beq $t5, $zero, endrun	# end of run of 1s (01)
        
        startrun:
            sub $t1, $t1, $t3	# subtract multiplicand from upper bits of product
            j skip		# skip step for ending a run
        endrun:
            add $t1, $t1, $t3   # add multiplicand to upper bits of product
            
        skip:
       	    # save most significant bit of product to allow for sign restoration
            srl $t6, $t1, 31	# get sign bit from product
            sll $t6, $t6, 31	# move sign bit of product back into place
            
            # save least significant bit of upper product bits for sign restoration of lower bits
            andi $t7, $t1, 1    # get least significant bit of upper product bits
            sll $t7, $t7, 31	# move LSB of upper product bits into MSB
            
            # shift product right 1 bit
            srl $t0, $t0, 1	# shift lower bits of product right 1 bit
            add $t0, $t0, $t7 	# restore MSB of lower product bits
            srl $t1, $t1, 1	# shift upper bits of product right 1 bit
            add $t1, $t1, $t6	# restore sign bit of product
            move $t2, $t5	# move LSB of product into hidden bit
        
        print: 
            # print newline
            li $v0, 4		# load service code for printing string
            la $a0, newline	# load address of newline string into $a0
            syscall		# issue syscall
        
            # print upper bits of product
            li $v0, 35		# load service code for printing binary
            move $a0, $t1	# move upper bits of product into $a0 for printing
            syscall		# issue syscall
        
            # print lower bits of product
            li $v0, 35		# load service code for printing binary
            move $a0, $t0	# move lower bits of product into $a0 for printing
            syscall		# issue syscall
    
        addi $t4, $t4, 1 	# increment iteration counter
        j loop3			# begin next iteration of loop	
    	
    done:
        # print newline
        li $v0, 4		# load service code for printing string
        la $a0, newline		# load address of newline string into $a0
        syscall			# issue syscall
    
        # print big bar
    	li $v0, 4		# load service code for printing string
    	la $a0, bigbar		# load address of big bar string into $a0
    	syscall			# issue syscall
    	
    	# print newline
        li $v0, 4		# load service code for printing string
        la $a0, newline		# load address of newline string into $a0
        syscall			# issue syscall
    
        # print upper bits of product
        li $v0, 35		# load service code for printing binary
        move $a0, $t1		# move upper bits of product into $a0 for printing
        syscall			# issue syscall
        
        # print lower bits of product
        li $v0, 35		# load service code for printing binary
        move $a0, $t0		# move lower bits of product into $a0 for printing
        syscall			# issue syscall    	
    
        move $v0, $t0		# put lower bits of product in $v0
        move $v1, $t1		# put upper bits of product in $v1
        jr $ra			# return

# terminates program
exit:
    li $v0, 10              	# load service code for terminating program
    syscall                 	# issue syscall
