module registerIO1 (
		/*-----------Inputs--------------------------------*/
		input 						clock,  /* clock */
		input       					reset,  /* reset */
		input wire 	input_to_register,

		/*-----------Outputs--------------------------------*/
		output reg	outputRegister  /* read_complete flag */
);

always@(posedge clock)
  begin  
    if (reset) outputRegister <= 0; 
    else outputRegister <= input_to_register;
  end
endmodule





