module w64 #(parameter W_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              w_index_complete,
    input  reg [ $clog2(W_LENGTH):0]        w_vector_index,
    input  reg [511:0]                      message_vector,
    input  reg [2095:0]                     prev_w_vector,
    
    /*-----------Outputs--------------------------------*/

    output reg                              w_vector_complete,  /* message formation complete flag */
    output reg [2095:0]                     w_vector
);

integer block_bit;
    reg w_r7;

always @(posedge clock)
    begin
        if(reset || !enable) begin
            w_vector = 0;
            w_vector_complete <= 0;
        end
        else begin
	        if(w_vector_index == 0) w_vector <= 0;
	        else w_vector <= prev_w_vector;
            
	        if(!w_index_complete && w_vector_index < 16)
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    w_vector[block_bit + w_vector_index*32] <= message_vector[511-32 + block_bit - w_vector_index*32];

            else if(!w_index_complete && w_vector_index >= 16)
            begin
                for (block_bit = 0 ; block_bit < 8; block_bit = block_bit + 1)
                w_vector[block_bit + w_vector_index*8] <= message_vector[504 + block_bit - w_vector_index*8];
            end

            if(w_index_complete) w_vector_complete <= 1;
        end
    end

    asssign w_r7 = 
endmodule