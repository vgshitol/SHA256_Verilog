module registerIO8 (
		
		/*-----------Inputs--------------------------------*/

		input 						clock,  /* clock */
		input       					reset,  /* reset */
		input wire  [7:0] 	input_to_register,

		/*-----------Outputs--------------------------------*/

		output reg [7:0] 	outputRegister  /* read_complete flag */
);

always@(posedge clock)
  begin  
    if (reset) outputRegister <= 0; 
    else outputRegister <= input_to_register;
  end
endmodule





