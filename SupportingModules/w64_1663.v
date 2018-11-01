module w64_1663 #(parameter W_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              w_index_complete,
    input  reg [ $clog2(W_LENGTH):0]        w_vector_index,
    input  reg [2095:0]                     prev_w_vector,

    /*-----------Outputs--------------------------------*/

    output reg                              w_vector_complete,  /* message formation complete flag */
    output reg [2095:0]                     w_vector
);

    integer block_bit;
    reg  [31:0] s0w_r1;
    reg  [31:0] s0w_r2;
    reg  [31:0] s0w_r3;
    reg  [31:0] s0word;
    reg  [63:0] double_s0word;
    reg  [31:0] sigma0_s0word;
    
    reg  [31:0] s1w_r1;
    reg  [31:0] s1w_r2;
    reg  [31:0] s1w_r3;
    reg  [31:0] s1word;
    reg  [63:0] double_s1word;
    reg  [31:0] sigma1_s1word;

    reg  [31:0] word16;
    reg  [31:0] word7;
    reg  [31:0] new_word;

    always @(posedge clock)
        begin
            w_vector <= prev_w_vector;
            if(reset || !enable) w_16_complete <= 0;
            else begin
                if(enable && !w_index_complete)
                    begin
                        for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                            w_vector[block_bit + w_vector_index*32] <= new_word[block_bit];
                    end
            end

            w_vector_complete <= ~|(64 - w_vector_index);
        end

    always @(*)
    begin
        if(enable && !w_index_complete)
            begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    s0word[block_bit] = w_vector[block_bit + (w_vector_index-15)*32];

                double_s0word = {s0word, s0word};
                s0w_r1 = double_s0word >> 7;
                s0w_r2 = double_s0word >> 18;
                s0w_r3 = s0word >> 3;
                sigma0_s0word = s0w_r1 + s0w_r2 + s0w_r3;
            end
        else sigma0_s0word = 0;
    end

    always @(*)
        begin
            if(enable && !w_index_complete)
                begin
                    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                        s1word[block_bit] = w_vector[block_bit + (w_vector_index-2)*32];

                    double_s0word = {s0word, s0word};
                    s1w_r1 = double_s1word >> 17;
                    s1w_r2 = double_s1word >> 19;
                    s1w_r3 = s1word >> 10;
                    sigma1_s1word = s1w_r1 + s1w_r2 + s1w_r3;
                end
            else sigma1_s1word = 0;
        end

    always @(*)
        begin
            if(enable && !w_index_complete)
                begin
                    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                        word16[block_bit] = w_vector[block_bit + (w_vector_index-16)*32];
                    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                        word7[block_bit] = w_vector[block_bit + (w_vector_index-7)*32];
                end
            else word16 = 0; word7 = 0;

            new_word = (sigma0_s0word + sigma1_s1word) + (word16 + word7);
        end


endmodule
