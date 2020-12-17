# goal: load 0010 0000 0000 0001 0100 1001 0010 0100 into $t0 and print
lui $t1, 8193 		# load upper 16 bits (8193 decimal = 0010 0000 0000 0001 binary)
ori $t1, $t1, 18724 	# insert lower 16 bits (18724 decimal = 0100 1001 0010 0100 binary)
li $v0, 35		# load service code for printing binary into $v0
add $a0, $t1, $zero	# put number in argument register $a0 for printing
syscall			# issue syscall to perform printing