module msg512Block #(parameter MSG_LENGTH = 55
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              address_read_complete,
    input  reg [ $clog2(MSG_LENGTH)-1:0]	msg_address,
    input  reg [7:0]                        msg_write,
    input  reg [7:0]                        msg_data,

    /*-----------Outputs--------------------------------*/

    output reg                              message_vector_complete,  /* message formation complete flag */
    output reg [511:0]                      message_vector
);

integer block_bit;
integer length_bit;

always @(posedge clock)
    begin
        if(reset) begin
            message_vector = 0;
            message_vector_complete <= 0;
        end
        else begin
            msg_write <= 0;
            message_vector = 0;
            if(!address_read_complete)for (block_bit = 0 ; block_bit < 8; block_bit = block_bit + 1)
                message_vector[511 - (block_bit + msg_address*8)] <= msg_data[7 - block_bit];
            else
                message_vector[511 - (8 + msg_address*8)] <= 1; // appending 1 bit

            if(enable)
                for (length_bit = 0; length_bit <=  $clog2(MSG_LENGTH); length_bit = length_bit+1)
                    message_vector[length_bit] <= xxx__dut__msg_length[length_bit];

            message_vector_complete <= 1;
        end
    end

endmodule
