module msg512Block #(parameter MSG_LENGTH = 55, 
parameter MSG_BIT_LENGTH = 440
) (

    /*-----------Inputs--------------------------------*/

    input                                    clock,  /* clock */
    input                                    reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [ $clog2(MSG_LENGTH)-1:0]    msg_address,
    input  wire [7:0]                        msg_data,
    input  wire [511:0]                      prev_message_vector,
    
    /*-----------Outputs--------------------------------*/

    output reg [7:0]                        msg_write,
    output reg                              message_vector_complete,  /* message formation complete flag */
    output reg [511:0]                      message_vector
);

integer block_bit;
integer length_bit;


reg [ $clog2(MSG_BIT_LENGTH)-1:0] message_bit_length;

always @(posedge clock)
    begin
        if(reset) begin
            message_vector = 0;
            message_vector_complete <= 0;
        end
        else begin
            msg_write <= 0;
	    if(msg_address == 0) message_vector <= 0;
	    else message_vector <= prev_message_vector;
            
	    if(!address_read_complete) for (block_bit = 0 ; block_bit < 8; block_bit = block_bit + 1)
                message_vector[511 - (block_bit + msg_address*8)] <= msg_data[7 - block_bit];
            

	    if(address_read_complete)
		begin
                message_vector[511 - (msg_address*8)] <= 1; // appending 1 bit
                for (length_bit = 0; length_bit < $clog2(MSG_BIT_LENGTH); length_bit = length_bit+1)
                    message_vector[length_bit] <= message_bit_length[length_bit];
		message_vector_complete <= 1;		
		end	               
        end
    end

assign message_bit_length = msg_address*8;

endmodule
