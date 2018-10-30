/*module************************************
*
* NAME:  counter
*
* DESCRIPTION:
*  downcounter with zero flag and synchronous clear
*
* NOTES:
*
* REVISION HISTORY
*    Date     Programmer    Description
*    7/10/97  P. Franzon    ece520-specific version
*
*M*/

/*======Declarations===============================*/

module counter #(parameter DEC_COUNT = 1'b1)
		(
		
		/*-----------Inputs--------------------------------*/

		input       clock,  /* clock */
		input [6:0] in,  /* input initial count */
		input       latch,  /* `latch input' */
		input       dec,   /* decrement */

		/*-----------Outputs--------------------------------*/

		output wire zero  /* zero flag */
		);


/*----------------Nets and Registers----------------*/
reg [3:0] value;       /* current count value */

// Count Flip-flops with input multiplexor
always@(posedge clock)
  begin  // begin-end not actually need here as there is only one statement
    if (latch) value <= in;
    else if (dec && !zero) value <= value - DEC_COUNT;  
  end

// combinational logic for zero flag
assign zero = ~|value;

endmodule /* counter */




