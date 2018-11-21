module msg512Block #(parameter MSG_LENGTH = 55, 
parameter MSG_BIT_LENGTH = 440
) (

    /*-----------Inputs--------------------------------*/

    input  wire                                  clock,  /* clock */
    input  wire                                  reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [ $clog2(MSG_LENGTH)-1:0]    msg_address,
    input  wire [7:0]                        msg_data,
    input  wire  [ $clog2(MSG_LENGTH)-1:0]   msg_length ,
    
    /*-----------Outputs--------------------------------*/

    output reg                              msg_write,
    output reg                              message_vector_complete,  /* message formation complete flag */
    output reg [511:0]                      message_vector
);

integer block_bit;
integer length_bit;


reg [ $clog2(MSG_BIT_LENGTH)-1:0] message_bit_length;

always @(posedge clock)
    begin
        if(reset || !enable) 
	begin
            message_vector <= 0;
            message_vector_complete <= 0;
	    message_bit_length <= 0;	
        end
        else 
	begin
		for(block_bit = 0; block_bit < 512 ; block_bit = block_bit + 1)
		begin
		message_vector <= message_vector;
	    	if(!address_read_complete) message_vector[511 - block_bit] <= msg_data[7 - block_bit + msg_address*8];
		
		else if(address_read_complete) message_vector[511 - block_bit] <= message_vector[511 - block_bit];
		else message_vector[511 - block_bit] <= 0;
		end	               
        end
        msg_write <= 0;
        message_bit_length <= msg_length*8;
	message_vector_complete <= address_read_complete;
     end

 

endmodule
