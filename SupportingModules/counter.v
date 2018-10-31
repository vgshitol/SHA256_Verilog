/*module************************************
*
* NAME:  counter
*
* DESCRIPTION:
*  downcounter with read_complete flag and synchronous clear
*
* NOTES:
*
* REVISION HISTORY
*    Date     Programmer    Description
*    7/10/97  P. Franzon    ece520-specific version
*
*M*/

/*======Declarations===============================*/

module counter #(parameter UP_COUNT = 1'b1, parameter MAX_MESSAGE_LENGTH = 55)
		(
		
		/*-----------Inputs--------------------------------*/

		input       								clock,  /* clock */
		input       								reset,  /* `reset input' */
		input reg      							   	start,   /* start */
		input reg  [ $clog2(MAX_MESSAGE_LENGTH) : 0] 	msg_length,

		/*-----------Outputs--------------------------------*/

		output reg [ $clog2(MAX_MESSAGE_LENGTH) : 0] 	read_address,  /* read_complete flag */
		output wire read_complete  /* read_complete flag */
		);

// Count Flip-flops with input multiplexor
always@(posedge clock)
  begin  // begin-end not actually need here as there is only one statement
    if (reset) read_address <= 0;
    else if (start && !read_complete) read_address <= read_address + UP_COUNT;
    else read_address <= read_address;
  end

// combinational logic for read_complete flag
assign read_complete = ~|(msg_length - read_address);

endmodule /* counter */




