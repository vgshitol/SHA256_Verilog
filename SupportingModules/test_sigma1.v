module test_sigma1;
	reg		clock100 = 0 ;
	reg		reset = 0;
	reg 	[31:0] 	word = 32'habcdef01;
	wire	[31:0] 	sigma1_output;   
	
	initial	//following block executed only once
	  begin
		#10 reset = 0;		// wait 10 ns
		#10 reset = 1; 		// wait 10 ns
		#100 $finish;		//finished with simulation
  	end
	always #5 clock100 = ~clock100;	// 10ns clock

	// instantiate modules -- call this counter u1
	 sigma1 u1( .clock(clock100), .reset(reset), .word(word), 
			.sigma1_output(sigma1_output));
endmodule  /*test_sigma1*/

