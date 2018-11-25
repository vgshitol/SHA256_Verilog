module msg_vector #(parameter MSG_LENGTH = 55
) (

    /*-----------Inputs--------------------------------*/

    input                                    clock,  /* clock */
    input                                    reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [ $clog2(MSG_LENGTH)-1:0]    msg_address,
    input  wire [7:0]                        msg_data,

    /*-----------Outputs--------------------------------*/

    output reg 	                            msg_write,
    output reg                              message_vector_complete,  /* message formation complete flag */
    output reg [511:0]                      message_vector
);

    integer block_bit;

    parameter MSG_BIT_LENGTH = 8 * MSG_LENGTH;
    wire [ $clog2(MSG_BIT_LENGTH)-1:0] message_bit_length;
	reg [ $clog2(MSG_LENGTH)-1:0]   msgAddress1;
	reg enable1;
	reg [ $clog2(MSG_LENGTH)-1:0]   msgAddress2;
	reg enable2;
	reg                              message_vector_complete1;
	reg                              message_vector_complete2;

    always @(posedge clock)
        begin
            if(reset || !enable2)
                begin
                    message_vector <= 0;
                    message_vector_complete <= 0;
                end
            else
                begin
                    for(block_bit = 0; block_bit < 512 ; block_bit = block_bit + 1)
                        begin
                            if((!message_vector_complete) && (block_bit < (msgAddress2+1)*8) && (block_bit >= (msgAddress2)*8)) message_vector[511 - block_bit] <= msg_data[7 - block_bit  + msgAddress2*8];
                            else if(block_bit == message_bit_length) message_vector[511 - block_bit] <= 1; // appending 1 bit
                            else if ((511 - block_bit) <=  ($clog2(MSG_BIT_LENGTH)-1)) message_vector[511 - block_bit] <= message_bit_length[511 - block_bit];
                            else message_vector[511 - block_bit] <= message_vector[511 - block_bit];
                        end
                end
            	message_vector_complete1 <= address_read_complete;
            	message_vector_complete2 <= message_vector_complete1;
            	message_vector_complete <= message_vector_complete2;
            	msg_write <= 0;
		msgAddress1 <= msg_address;
    		enable1 <= enable;	 
		msgAddress2 <= msgAddress1;
    		enable2 <= enable1;
	 
        end

    assign message_bit_length = (msgAddress2+1)*8;

endmodule
