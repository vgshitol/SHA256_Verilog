module test_summation1;
	reg		clock100 = 0 ;
	reg		reset = 0;
	reg 	[31:0] 	a = 32'habcdef01;
	wire	[31:0] 	summation1_output;
	
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
	 summation1 u1( .clock(clock100), .reset(reset), .a(a),
			.summation1_output(summation1_output));
endmodule  /*test_sigma0*/

