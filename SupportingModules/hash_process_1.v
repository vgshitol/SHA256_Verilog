module w64_16 #(parameter W_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              w_index_complete,
    input  reg [ $clog2(W_LENGTH):0]        w_vector_index,
    input  reg [255:0]                      hash_vector,
    input  reg [2095:0]                     prev_w_vector,

    /*-----------Outputs--------------------------------*/

    output reg                              w_complete,  /* message formation complete flag */
    output reg [2095:0]                     w_vector
);

    integer block_bit;
    reg [31:0] a;
    reg [31:0] b;
    reg [31:0] c;
    reg [31:0] d;
    reg [31:0] e;
    reg [31:0] f;
    reg [31:0] g;
    reg [31:0] h;


    always @(posedge clock)
        begin
            if(reset || !enable) begin
                w_vector = 0;
                w_complete <= 0;
            end
            else begin
                if(w_vector_index == 0) w_vector <= 0;
                else w_vector <= prev_w_vector;



                w_complete <= ~|(63 - w_vector_index);

            end
        end

    always @(*)
    begin
        if(!w_index_complete)
            begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        a <= hash_vector[block_bit + 8*0];
                        b <= hash_vector[block_bit + 8*1];
                        c <= hash_vector[block_bit + 8*2];
                        d <= hash_vector[block_bit + 8*3];
                        e <= hash_vector[block_bit + 8*4];
                        f <= hash_vector[block_bit + 8*5];
                        g <= hash_vector[block_bit + 8*6];
                        h <= hash_vector[block_bit + 8*7];
                    end
            end
    end
endmodule
