module counter #(
	parameter MAX_MESSAGE_LENGTH = 55
	) (
		
		/*-----------Inputs--------------------------------*/

		input 						clock,  /* clock */
		input       					reset,  /* reset */
		input wire      				start,   /* start */
		input wire  [ $clog2(MAX_MESSAGE_LENGTH) : 0] 	msg_length,

		/*-----------Outputs--------------------------------*/

		output reg [ $clog2(MAX_MESSAGE_LENGTH) : 0] 	read_address,  /* read_complete flag */
		output wire read_complete  /* read_complete flag */
);

always@(posedge clock)
  begin  
    if (reset) read_address <= 0;
    else if (start && !read_complete) read_address <= read_address + 1;
    else read_address <= read_address;
  end

assign read_complete = ~|(msg_length - read_address);

endmodule




