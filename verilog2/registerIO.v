module registerIO #(
	parameter REGISTER_LENGTH = 32
	) (
		
		/*-----------Inputs--------------------------------*/

		input 						clock,  /* clock */
		input       					reset,  /* reset */
		input wire  [ REGISTER_LENGTH-1 : 0] 	input_to_register,

		/*-----------Outputs--------------------------------*/

		output reg [ REGISTER_LENGTH-1 : 0] 	outputRegister  /* read_complete flag */
);

always@(posedge clock)
  begin  
    if (reset) outputRegister <= 0; 
    else outputRegister <= input_to_register;
  end
endmodule





