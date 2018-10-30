module test_major;
	reg		clock100 = 0 ;
	reg		reset = 0;
	reg 	[31:0] 	a = 32'h01234567;
	reg 	[31:0] 	b = 32'h12345678;
	reg 	[31:0] 	c = 32'h23456789;
	wire	[31:0] 	major_output;
	
	initial	//following block executed only once
	  begin
		//$dumpfile("count.vcd"); // waveforms in this file.. 
  		//$dumpvars; // saves all waveforms
		#10 reset = 0;		// wait 10 ns
		#10 reset = 1; 		// wait 10 ns
		#100 $finish;		//finished with simulation
  	end
	always #5 clock100 = ~clock100;	// 10ns clock

	// instantiate modules -- call this counter u1
	 major u1( .clock(clock100), .reset(reset), .a(a), .b(b) , .c(c),
			.major_output(major_output));
endmodule  /*test_sigma0*/

