module counter_h #(
	parameter NUMBER_OF_BLOCKS=8
	) (
		
		/*-----------Inputs--------------------------------*/
		input 						clock,  /* clock */
		input       					reset,  /* reset */
		input       				start,   /* start */
		/*-----------Outputs--------------------------------*/

		output reg [ $clog2(NUMBER_OF_BLOCKS)-1 : 0] 	read_address,  /* read_complete flag */
		output wire read_complete  /* read_complete flag */
);

always@(posedge clock)
  begin  
    if (reset || !start) read_address <= 0;
    else if (start && !read_complete) read_address <= read_address + 1;
    else read_address <= read_address;
  end

assign   read_complete = (NUMBER_OF_BLOCKS-1 == read_address);
endmodule




