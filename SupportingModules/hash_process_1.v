module hash_process_1 #(parameter WK_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              wk_index_complete,
    input  reg [ $clog2(WK_LENGTH):0]       wk_vector_index,
    input  reg [255:0]                      prev_hash,
    input  reg [2095:0]                     w_vector,
    input  reg [2095:0]                     k_vector,

    /*-----------Outputs--------------------------------*/

    output reg                              hash_complete,  /* message formation complete flag */
    output reg [2095:0]                     updated_hash
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
    reg [31:0] w;
    reg [31:0] k;

    reg [31:0] summation0_output;
    reg [63:0] a_new;
    reg [31:0] a_r1;
    reg [31:0] a_r2;
    reg [31:0] a_r3;


    reg [31:0] summation1_output;
    reg [63:0] e_new;
    reg [31:0] e_r1;
    reg [31:0] e_r2;
    reg [31:0] e_r3;

    reg [31:0] major_output;
    reg [31:0] m1;
    reg [31:0] m2;
    reg [31:0] m3;

    reg [31:0] next_choice_output;
    reg [31:0] c1;
    reg [31:0] c2;

    wire [31:0] ms0;
    wire [31:0] cs1;
    wire [31:0] ms0cs1;
    wire [31:0] cs1wkd;

    wire [31:0] a_new;
    wire [31:0] b_new;
    wire [31:0] c_new;
    wire [31:0] d_new;
    wire [31:0] e_new;
    wire [31:0] f_new;
    wire [31:0] g_new;
    wire [31:0] h_new;

    always @(posedge clock)
        begin
            if(reset || !enable) begin
            end
            else begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        hash_vector[block_bit + 8*0] <= a_new;
                        hash_vector[block_bit + 8*1] <= b_new;
                        hash_vector[block_bit + 8*2] <= c_new;
                        hash_vector[block_bit + 8*3] <= d_new;
                        hash_vector[block_bit + 8*4] <= e_new;
                        hash_vector[block_bit + 8*5] <= f_new;
                        hash_vector[block_bit + 8*6] <= g_new;
                        hash_vector[block_bit + 8*7] <= h_new;
                    end
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

    always @(*)
    begin
        if(enable && !w_index_complete)
            begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
		    begin
                    	w[block_bit] = w_vector[block_bit + (wk_vector_index)*32];
		    	k[block_bit] = k_vector[block_bit + (wk_vector_index)*32];
		    end
            end
        else w = 0; k = 0;
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
                a_new = {a, a};
                a_r1 = a_new >> 2;
		a_r2 = a_new >> 13;
		a_r3 = a_new >> 22;
                summation0_output = a_r1 + a_r2 + a_r3;
            end
        else summation0_output = 0;
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
                e_new = {e, e};
                e_r1 = e_new >> 2;
		e_r2 = e_new >> 13;
		e_r3 = e_new >> 22;
                summation1_output = e_r1 + e_r2 + e_r3;
            end
        else summation1_output = 0;
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
              m1 = a^b;
	      m2 = a^c;
  	      m3 = b^c;
	      major_output = m1 + m2 + m3;
            end
        else major_output = 0;
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
              c1 = e^f;
    	      c2 = e^g;
    	      choice_output = c1 + c2;
            end
        else choice_output = 0;
    end

    assign ms0 = summation0_output + major_output;
    assign cs1 = summation1_output + choice_output;
 
    assign ms0cs1 = ms0 + cs1;
    assign cs1wkd = (cs1 + w) + (k + d);

    assign a_new = ms0cs1 + a;
    assign b_new = a + b;
    assign c_new = b + c;
    assign d_new = c + d;
    assign e_new = cs1wkd + e;
    assign f_new = e + f;
    assign g_new = f + g;
    assign h_new = g + h;

endmodule
