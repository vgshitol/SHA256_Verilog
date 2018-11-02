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

    wire w_16_complete;

    wire [2095:0]                     intermediate_w_vector;

    `include "w64_16.sv"
    `include "w64_1663.v"

    w64_16 u0(.clock(clk), .reset(reset), .enable(enable), .w_index_complete(w_index_complete),
        .w_vector_index(w_vector_index), .message_vector(message_vector),
        .prev_w_vector(prev_w_vector) , .w_16_complete(w_16_complete), .w_vector(intermediate_w_vector));

    w64_1663 u1(.clock(clk), .reset(reset), .enable(w_16_complete), .w_index_complete(w_index_complete),
        .w_vector_index(w_vector_index), .prev_w_vector(intermediate_w_vector) , .w_vector_complete(w_vector_complete),
        .w_vector(w_vector));


endmodule
