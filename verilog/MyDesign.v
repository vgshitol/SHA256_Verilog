//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// DUT

module MyDesign #(parameter OUTPUT_LENGTH       = 8,
                  parameter MAX_MESSAGE_LENGTH  = 55,
                  parameter NUMBER_OF_Ks        = 64,
                  parameter NUMBER_OF_Hs        = 8 ,
                  parameter SYMBOL_WIDTH        = 8  )
(

    //---------------------------------------------------------------------------
    // Control
    //
    output reg                                   dut__xxx__finish     ,
    input  wire                                  xxx__dut__go         ,
    input  wire  [ $clog2(MAX_MESSAGE_LENGTH)-1:0] xxx__dut__msg_length ,

    //---------------------------------------------------------------------------
    // Message memory interface
    //
    output reg  [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   dut__msg__address  ,  // address of letter
    output reg                                      dut__msg__enable   ,
    output reg                                      dut__msg__write    ,
    input  wire [7:0]                               msg__dut__data     ,  // read each letter

    //---------------------------------------------------------------------------
    // K memory interface
    //
    output reg  [ $clog2(NUMBER_OF_Ks)-1:0]     dut__kmem__address  ,
    output reg                                  dut__kmem__enable   ,
    output reg                                  dut__kmem__write    ,
    input  wire [31:0]                          kmem__dut__data     ,  // read data

    //---------------------------------------------------------------------------
    // H memory interface
    //
    output reg  [ $clog2(NUMBER_OF_Hs)-1:0]     dut__hmem__address  ,
    output reg                                  dut__hmem__enable   ,
    output reg                                  dut__hmem__write    ,
    input  wire [31:0]                          hmem__dut__data     ,  // read data


    //---------------------------------------------------------------------------
    // Output data memory
    //
    output reg  [ $clog2(OUTPUT_LENGTH)-1:0]    dut__dom__address  ,
    output reg  [31:0]                          dut__dom__data     ,  // write data
    output reg                                  dut__dom__enable   ,
    output reg                                  dut__dom__write    ,


    //-------------------------------
    // General
    //
    input  wire                 clk             ,
    input  wire                 reset

);


    //---------------------------------------------------------------------------
    //
    //<<<<----  YOUR CODE HERE    ---->>>>


    wire msg_address_read_complete;
    wire message_vector_complete;
    wire [511:0] message_vector;

    wire hash_address_complete;
    wire [255:0] hash_vector;
    wire hash_vector_complete;

    wire k_address_complete;

    wire [31:0] cur_k_value;
    wire [31:0] cur_w_value;

    wire wk_vector_enable;
    wire wk_vector_index_complete;
    wire [255:0] updated_hash;
    wire hash_complete;

    wire [$clog2(NUMBER_OF_Hs)-1:0]   hash_output_vector_index;  // index of hash
    wire hash_output_address_complete;

    reg go;
    reg finish;
    reg msgEnable;
    reg [5:0] 	msgLength;
    reg [5:0]   msgAddress;  // address of letter
    reg                                     msgWrite;
    reg [7:0]                               msgData;  // read each letter

    reg 					hashEnable;
    reg [2:0]   	hashAddress;  // address of letter
    reg                                     hashWrite;
    reg [31:0]                              hashData;  // read each letter

    reg 					kEnable;
    reg [5:0]   	kAddress;  // address of letter
    reg                                     kWrite;
    reg [31:0]                              kData;  // read each letter

    reg 					outputEnable;
    reg [2:0]   	outputAddress;  // address of letter
    reg                                     outputWrite;
    reg [31:0]                              outputData;  // read each letter

    /**Register All Inputs and Outputs **/
    /**Inputs **/
    registerIO1 registerGO(.clock(clk), .input_to_register(xxx__dut__go), .outputRegister(go));

    registerIO6 registerMSGLength(.clock(clk), .input_to_register(xxx__dut__msg_length), .outputRegister(msgLength));
    registerIO8 registerMSGData(.clock(clk), .input_to_register(msg__dut__data), .outputRegister(msgData));

    registerIO32 registerHashData(.clock(clk), .input_to_register(hmem__dut__data), .outputRegister(hashData));

    registerIO32  registerKData(.clock(clk), .input_to_register(kmem__dut__data), .outputRegister(kData));

    registerIO32  registerOutputData(.clock(clk), .input_to_register(outputData), .outputRegister(dut__dom__data));

    /**Outputs**/
    registerIO1  registerMSGEnable(.clock(clk), .input_to_register(msgEnable), .outputRegister(dut__msg__enable));
    registerIO6  registerMSGAddress(.clock(clk),  .input_to_register(msgAddress), .outputRegister(dut__msg__address));
    registerIO1  registerMSGWrite(.clock(clk), .input_to_register(msgWrite), .outputRegister(dut__msg__write));

    registerIO1  registerHashEnable(.clock(clk),.input_to_register(hashEnable), .outputRegister(dut__hmem__enable));
    registerIO3  registerHashAddress(.clock(clk),  .input_to_register(hashAddress), .outputRegister(dut__hmem__address));
    registerIO1  registerHashWrite(.clock(clk), .input_to_register(hashWrite), .outputRegister(dut__hmem__write));

    registerIO1  registerKEnable(.clock(clk),  .input_to_register(kEnable), .outputRegister(dut__kmem__enable));
    registerIO6  registerKAddress(.clock(clk),  .input_to_register(kAddress), .outputRegister(dut__kmem__address));
    registerIO1  registerKWrite(.clock(clk),  .input_to_register(kWrite), .outputRegister(dut__kmem__write));

    registerIO1 registerOutputEnable(.clock(clk), .input_to_register(outputEnable), .outputRegister(dut__dom__enable));
    registerIO3 registerOutputAddress(.clock(clk),  .input_to_register(outputAddress), .outputRegister(dut__dom__address));
    registerIO1 registerOutputWrite(.clock(clk),  .input_to_register(outputWrite), .outputRegister(dut__dom__write));

    registerIO1 registerFINISH(.clock(clk), .input_to_register(finish), .outputRegister(dut__xxx__finish));

    /** Creating Message Vector **/
    go msgSignal(.clock(clk), .reset(reset), .start(go), .restart(finish), .enable(msgEnable));

    counter #(.MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)) msgCounter (.clock(clk), .reset(reset), .start(msgEnable), .msg_length(msgLength), .read_address(msgAddress), .read_complete(msg_address_read_complete));

    msg_vector #(.MSG_LENGTH(MAX_MESSAGE_LENGTH)) msgBlock (.clock(clk), .reset(reset), .enable(msgEnable), .address_read_complete(msg_address_read_complete), .msg_address(msgAddress),
                                                            .msg_data(msgData), .msg_write(msgWrite), .message_vector(message_vector), .message_vector_complete(message_vector_complete));

    /** Creating Hash Vector **/
    go hashSignal (.clock(clk), .reset(reset), .start(go), .restart(finish),  .enable(hashEnable));

    counter_h #(.NUMBER_OF_BLOCKS(NUMBER_OF_Hs)) Hcounter (.clock(clk), .reset(reset), .start(hashEnable), .read_address(hashAddress), .read_complete(hash_address_complete));

    hash #(.HASH_LENGTH(NUMBER_OF_Hs)) hashBlock (.clock(clk), .reset(reset), .enable(hashEnable), .address_read_complete(hash_address_complete), .hash_address(hashAddress), .hash_write(hashWrite),
                                                  .hash_data(hashData) , .hash_vector_complete(hash_vector_complete), .hash_vector(hash_vector));

    /** Creating K Vector **/
    wEn wkSignal(.clock(clk), .reset(reset), .start1(message_vector_complete), .start2(hash_vector_complete),  .restart(finish), .enable(kEnable));

    counter_wk #(.MAX_MESSAGE_LENGTH(NUMBER_OF_Ks)) wkCounter (.clock(clk), .reset(reset), .start(kEnable), .read_address(kAddress), .read_complete(k_address_complete));

    k_vector #(.K_LENGTH(NUMBER_OF_Ks)) kBlock (.clock(clk), .reset(reset), .enable(kEnable), .address_read_complete(k_address_complete), .k_write(kWrite),
                                                .k_data(kData) , .cur_k_value(cur_k_value));

    /** Creating the W Vector**/
    w64 #(.W_LENGTH(NUMBER_OF_Ks)) wBlock (.clock(clk), .reset(reset), .enable(kEnable), .w_vector_index(kAddress), .w_index_complete(k_address_complete), .message_vector(message_vector),
                                           .cur_w(cur_w_value));

    /** Processing Hash Update**/
    msgEn hashUpdateSignal(.clock(clk), .reset(reset), .start(kEnable),  .restart(finish), .enable(wk_vector_enable));

    counter_hashupdate #(.MAX_MESSAGE_LENGTH(NUMBER_OF_Ks)) hashUpdateCounter (.clock(clk), .reset(reset), .start(wk_vector_enable), .read_complete(wk_vector_index_complete));

    hash_update #(.WK_LENGTH(NUMBER_OF_Ks)) hashUpdate (.clock(clk), .reset(reset), .enable(wk_vector_enable), .wk_index_complete(wk_vector_index_complete) ,
                                                        .prev_hash(hash_vector) , .hash_complete(hash_complete) , .updated_hash(updated_hash) , .cur_k(cur_k_value), .cur_w(cur_w_value));

    /** Storing the Hash Vector **/
    msgEn storeHashSignal(.clock(clk), .reset(reset), .start(hash_complete), .restart(finish),  .enable(outputEnable));

    counter_h #(.NUMBER_OF_BLOCKS(NUMBER_OF_Hs)) storeHashCounter (.clock(clk), .reset(reset), .start(outputEnable), .read_address(hash_output_vector_index), .read_complete(hash_output_address_complete));

    store_hash #(.HASH_LENGTH(NUMBER_OF_Hs)) hashStore (.clock(clk), .reset(reset), .enable(outputEnable), .address_read_complete(hash_output_address_complete), .h_address(hash_output_vector_index), .hash_vector(updated_hash), .h_write(outputWrite),
                                                        .h_data(outputData) , .h_vector_complete(finish), .h_output_address(outputAddress));

endmodule

module counter_hashupdate #(
    parameter MAX_MESSAGE_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input 						clock,  /* clock */
    input       					reset,  /* reset */
    input wire      				start,   /* start */
    /*-----------Outputs--------------------------------*/

    output wire read_complete  /* read_complete flag */
);

    reg [ $clog2(MAX_MESSAGE_LENGTH)-1 : 0] 	read_address;  /* read_complete flag */

    always@(posedge clock)
        begin
            if (reset || !start) read_address <= 0;
            else if (start && !read_complete) read_address <= read_address + 1;
            else read_address <= read_address;
        end

    assign read_complete = (MAX_MESSAGE_LENGTH-1 == read_address);

endmodule

module go (

    /*-----------Inputs--------------------------------*/

    input       clock,  /* clock */
    input 	    reset,		// resets
    input wire  start,  /* Go message Signal*/
    input wire restart,
    /*-----------Outputs--------------------------------*/

    output reg enable  /* zero flag */
);

    always @(posedge clock)
        begin
            enable <= 0;
            if(reset) enable <= 0;
            else enable <= (start || enable) && !restart;
        end

endmodule

module registerIO1 (
    /*-----------Inputs--------------------------------*/
    input 						clock,  /* clock */
    input wire 	input_to_register,

    /*-----------Outputs--------------------------------*/
    output reg	outputRegister  /* read_complete flag */
);

    always@(posedge clock)
        begin
            outputRegister <= input_to_register;
        end
endmodule

module registerIO3 (
    /*-----------Inputs--------------------------------*/
    input 						clock,  /* clock */
    input wire  [ 2 : 0] 	input_to_register,

    /*-----------Outputs--------------------------------*/
    output reg [ 2 : 0] 	outputRegister  /* read_complete flag */
);

    always@(posedge clock)
        begin
            outputRegister <= input_to_register;
        end
endmodule

module registerIO6 (
    /*-----------Inputs--------------------------------*/
    input 						clock,  /* clock */
    input wire  [5:0] 	input_to_register,

    /*-----------Outputs--------------------------------*/
    output reg [5:0] 	outputRegister  /* read_complete flag */
);

    always@(posedge clock)
        begin
            outputRegister <= input_to_register;
        end
endmodule

module registerIO8 (
    /*-----------Inputs--------------------------------*/
    input 						clock,  /* clock */
    input wire  [7:0] 	input_to_register,

    /*-----------Outputs--------------------------------*/
    output reg [7:0] 	outputRegister  /* read_complete flag */
);

    always@(posedge clock)
        begin
            outputRegister <= input_to_register;
        end
endmodule

module registerIO32 (
    /*-----------Inputs--------------------------------*/
    input 						clock,  /* clock */
    input wire  [ 31: 0] 	input_to_register,

    /*-----------Outputs--------------------------------*/
    output reg [ 31 : 0] 	outputRegister  /* read_complete flag */
);

    always@(posedge clock)
        begin
            outputRegister <= input_to_register;
        end
endmodule

module msgEn (
    /*-----------Inputs--------------------------------*/
    input       clock,  /* clock */
    input 	    reset,		// resets
    input wire  start,  /* Go message Signal*/
    input wire restart,
    /*-----------Outputs--------------------------------*/
    output reg enable  /* zero flag */
);

    always @(posedge clock)
        begin
            enable <= 0;
            if(reset) enable <= 0;
            else enable <= (start && !restart);
        end

endmodule

module counter #(
    parameter MAX_MESSAGE_LENGTH = 55
) (
    /*-----------Inputs--------------------------------*/
    input 						clock,  /* clock */
    input       					reset,  /* reset */
    input wire    					start,   /* start */
    input wire  [ $clog2(MAX_MESSAGE_LENGTH)-1 : 0] 	msg_length,

    /*-----------Outputs--------------------------------*/
    output reg [ $clog2(MAX_MESSAGE_LENGTH)-1 : 0] 	read_address,  /* read_complete flag */
    output reg read_complete  /* read_complete flag */
);

    always@(posedge clock)
        begin
            read_address <= 0;
            if (reset || !start) begin 
		read_address <= 0;      
		read_complete <= 0;
	    end
            else if (start && !read_complete) 
		begin
		read_address <= read_address+1;
		read_complete <= (msg_length-1 == read_address);
		end        	
	    else 
		begin
		read_address <= read_address;
		read_complete <= read_complete;
		end       
	end

     
endmodule

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
            else if(!message_vector_complete2)
                begin
                    for(block_bit = 0; block_bit < 512 ; block_bit = block_bit + 1)
                        begin
                            if((block_bit < (msgAddress2+1)*8) && (block_bit >= (msgAddress2)*8)) message_vector[511 - block_bit] <= msg_data[7 - block_bit  + msgAddress2*8];
                            else if(block_bit == message_bit_length) message_vector[511 - block_bit] <= 1; // appending 1 bit
                            else if ((511 - block_bit) <=  ($clog2(MSG_BIT_LENGTH)-1)) message_vector[511 - block_bit] <= message_bit_length[511 - block_bit];
                            else message_vector[511 - block_bit] <= message_vector[511 - block_bit];
                        end
                end
	    else message_vector <= message_vector;

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

module counter_h #(
    parameter NUMBER_OF_BLOCKS=8
) (

    /*-----------Inputs--------------------------------*/
    input 						clock,  /* clock */
    input       					reset,  /* reset */
    input       				start,   /* start */
    /*-----------Outputs--------------------------------*/

    output reg [ $clog2(NUMBER_OF_BLOCKS)-1 : 0] 	read_address,  /* read_complete flag */
    output wire read_complete  /* read_complete flag */
);

    always@(posedge clock)
        begin
            if (reset || !start) read_address <= 0;
            else if (start && !read_complete) read_address <= read_address + 1;
            else read_address <= read_address;
        end

    assign   read_complete = (NUMBER_OF_BLOCKS-1 == read_address);
endmodule

module hash #(parameter HASH_LENGTH = 8
) (

    /*-----------Inputs--------------------------------*/

    input                                    clock,  /* clock */
    input                                    reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [ $clog2(HASH_LENGTH)-1:0]   hash_address,
    input  wire [31:0]                       hash_data,

    /*-----------Outputs--------------------------------*/

    output reg 	                            hash_write,
    output reg                              hash_vector_complete,  /* hash formation complete flag */
    output reg [255:0]                      hash_vector
);

    integer block_bit;

    reg                              hash_vector_complete1;  /* hash formation complete flag */
    reg                              hash_vector_complete2;  /* hash formation complete flag */

    reg                              enable1;
    reg                              enable2;

    reg [ $clog2(HASH_LENGTH)-1:0]   hash_address1;
    reg [ $clog2(HASH_LENGTH)-1:0]   hash_address2;



    always @(posedge clock)
        begin
            if(reset || !enable2)
                begin
                    hash_vector <= 0;
                    hash_vector_complete <= 0;
                end
            else if(!hash_vector_complete)
                begin
                    hash_vector <= hash_vector;
                    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                        hash_vector[block_bit + hash_address2*32] <= hash_data[block_bit];
                end
            else hash_vector <= hash_vector;

            hash_address1 <= hash_address;
            hash_address2 <= hash_address1;

            hash_write <= 0;

            hash_vector_complete1 <= address_read_complete;
            hash_vector_complete2 <= hash_vector_complete1;
            hash_vector_complete  <= hash_vector_complete2;

            enable1 <= enable;
            enable2 <= enable1;
        end

endmodule

module wEn (

    /*-----------Inputs--------------------------------*/

    input       clock,  /* clock */
    input 	    reset,		// resets
    input wire  start1,  /* Go message Signal*/
    input wire  start2,  /* Go message Signal*/
    input wire restart,
    /*-----------Outputs--------------------------------*/

    output reg enable  /* zero flag */
);

    always @(posedge clock)
        begin
            enable <= 0;
            if(reset) enable <= 0;
            else enable <= start1 && start2 && !restart;
        end

endmodule

module counter_wk #(
    parameter MAX_MESSAGE_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input 						clock,  /* clock */
    input       					reset,  /* reset */
    input wire      				start,   /* start */
    /*-----------Outputs--------------------------------*/

    output reg [ $clog2(MAX_MESSAGE_LENGTH)-1 : 0] 	read_address,  /* read_complete flag */
    output wire read_complete  /* read_complete flag */
);

    always@(posedge clock)
        begin
            if (reset || !start) read_address <= 0;
            else if (start && !read_complete) read_address <= read_address + 1;
            else read_address <= read_address;
        end

    assign read_complete = (MAX_MESSAGE_LENGTH-1 == read_address);

endmodule

module k_vector #(parameter K_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [31:0]                       k_data,

    /*-----------Outputs--------------------------------*/

    output reg                              k_write,
    output reg [31:0]			    cur_k_value
);

    integer block_bit;
    integer length_bit;

    reg                              k_vector_complete;  /* hash formation complete flag */
    reg                              k_vector_complete1;
    reg                              k_vector_complete2;
    reg                              enable1;
    reg                              enable2;

    always @(posedge clock)
        begin
            if(reset || !enable2) begin
                cur_k_value <= 0;
                k_vector_complete <= 0;
            end
            else begin
                if(!k_vector_complete) for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        cur_k_value[block_bit] <= k_data[block_bit];
                    end
            end
            k_write <= 0;

            k_vector_complete1 <= address_read_complete;
            k_vector_complete2 <= k_vector_complete1;
            k_vector_complete  <= k_vector_complete2;

            enable1 <= enable;
            enable2 <= enable1;

        end

endmodule

module w64 #(parameter W_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              w_index_complete,
    input  wire [511:0]                      message_vector,
    input  wire [ $clog2(W_LENGTH)-1:0]      w_vector_index,

    /*-----------Outputs--------------------------------*/

    output reg [31:0]			            cur_w
);

    reg                              w_vector_complete;  /* message formation complete flag */
    reg [2047:0]                     w_vector;
    integer unsigned block_bit;
    reg  [31:0] s0w_r1;
    reg  [31:0] s0w_r2;
    reg  [31:0] s0w_r3;
    reg  [31:0] s0word;
   // reg  [63:0] double_s0word;
    reg  [31:0] sigma0_s0word;

    reg  [31:0] s1w_r1;
    reg  [31:0] s1w_r2;
    reg  [31:0] s1w_r3;
    reg  [31:0] s1word;
  //  reg  [63:0] double_s1word;
    reg  [31:0] sigma1_s1word;

    reg  [31:0] word16;
    reg  [31:0] word7;
    wire [31:0] new_word;

    integer word_16_bit;
    integer word_bit;

    reg                              w_vector_complete1;
    reg                              w_vector_complete2;

    reg                              enable1;
    reg                              enable2;

    reg [ $clog2(W_LENGTH)-1:0]      w_vector_index1;
    reg [ $clog2(W_LENGTH)-1:0]      w_vector_index2;

    always @(posedge clock)
        begin

            cur_w <= cur_w;
            if(reset || !enable2) 
		begin
			cur_w <= 0;
            	end
            else if(enable2 && !w_vector_complete )
                begin
                    if(w_vector_index2 < 16)
                    begin
                       if(w_vector_index2 == 0) cur_w[31:0] <= message_vector[511:480];
		    else if(w_vector_index2 == 1) cur_w[31:0] <= message_vector[479:448];
		    else if(w_vector_index2 == 2) cur_w[31:0] <= message_vector[447:416];
		    else if(w_vector_index2 == 3) cur_w[31:0] <= message_vector[415:384];
		    else if(w_vector_index2 == 4) cur_w[31:0] <= message_vector[383:352];
		    else if(w_vector_index2 == 5) cur_w[31:0] <= message_vector[351:320];
		    else if(w_vector_index2 == 6) cur_w[31:0] <= message_vector[319:288];
		    else if(w_vector_index2 == 7) cur_w[31:0] <= message_vector[287:256];
		    else if(w_vector_index2 == 8) cur_w[31:0] <= message_vector[255:224];
		    else if(w_vector_index2 == 9) cur_w[31:0] <= message_vector[223:192];
		    else if(w_vector_index2 == 10) cur_w[31:0] <= message_vector[191:160];
		    else if(w_vector_index2 == 11) cur_w[31:0] <= message_vector[159:128];
      		    else if(w_vector_index2 == 12) cur_w[31:0] <= message_vector[127:96];
      		    else if(w_vector_index2 == 13) cur_w[31:0] <= message_vector[95:64];
      		    else if(w_vector_index2 == 14) cur_w[31:0] <= message_vector[63:32];
      		    else if(w_vector_index2 == 15) cur_w[31:0] <= message_vector[31:0];
		    else cur_w <= 0;
                             
		    end
                    else
     	               begin
     	               cur_w <= new_word;
                        end
                end

	    w_vector <= w_vector;
            if(reset || !enable2) 
		begin
			w_vector <=0;
	    	end
            else if(enable2 && !w_vector_complete && (w_vector_index2 < 16))
                begin
		    w_vector[31:0] <= message_vector[511:480];
		    w_vector[63:32] <= message_vector[479:448];
		    w_vector[95:64] <= message_vector[447:416];
		    w_vector[127:96] <= message_vector[415:384];
		    w_vector[159:128] <= message_vector[383:352];
		    w_vector[191:160] <= message_vector[351:320];
		    w_vector[223:192] <= message_vector[319:288];
		    w_vector[255:224] <= message_vector[287:256];
		    w_vector[287:256] <= message_vector[255:224];
		    w_vector[319:288] <= message_vector[223:192];
		    w_vector[351:320] <= message_vector[191:160];
		    w_vector[383:352] <= message_vector[159:128];
      		    w_vector[415:384] <= message_vector[127:96];
      		    w_vector[447:416] <= message_vector[95:64];
      		    w_vector[479:448] <= message_vector[63:32];
      		    w_vector[511:480] <= message_vector[31:0];
      		end                          
            else if(enable2 && !w_vector_complete)
                begin                
                    w_vector[w_vector_index2*32 +: 32] <= new_word;           
                end

            w_vector_complete1 <= w_index_complete;
            w_vector_complete2 <= w_vector_complete1;
            w_vector_complete <= w_vector_complete2;

            w_vector_index1 <= w_vector_index;
            w_vector_index2 <= w_vector_index1;

            enable1 <= enable;
            enable2 <= enable1;
        end

    always @(*)
        begin
            if(enable2 && !w_vector_complete && w_vector_index2 >= 16)
                begin
		            s0word = w_vector[(w_vector_index2-15)*32 + 31 -: 32];
                    s0w_r1 = {s0word[6:0], s0word[31:7]};
                    s0w_r2 = {s0word[17:0], s0word[31:18]};
                    s0w_r3[28:0] = s0word[31:3];
                    s0w_r3[31:29] = 0;
                    sigma0_s0word = (s0w_r1 ^ s0w_r2) ^ s0w_r3;
                end
            else 
		begin 
		    s0word = 0;
		    s0w_r1 = 0;
                    s0w_r2 = 0;
                    s0w_r3 = 0;
		    sigma0_s0word = 0;
		end
        end

    always @(*)
        begin
            if(enable2 && !w_vector_complete && w_vector_index2 >= 16)
                begin   
                    s1word = w_vector[(w_vector_index2-2)*32 +31 -: 32];
                    s1w_r1 ={s1word[16:0], s1word[31:17]};
                    s1w_r2 = {s1word[18:0], s1word[31:19]};
                    s1w_r3[21:0] = s1word[31:10];
                    s1w_r3[31:22] = 0;
                    sigma1_s1word = s1w_r1 ^ s1w_r2 ^ s1w_r3;
                end
            else begin
		s1word = 0;
	        s1w_r1 = 0;
                s1w_r2 = 0;
                s1w_r3 = 0;
                sigma1_s1word = 0;
		end
        end

    always @(*)
        begin
            if(enable2 && !w_vector_complete && w_vector_index2 >= 16)
                begin
                   word16 = w_vector[(w_vector_index2-16)*32 +: 32];
                   word7 = w_vector[(w_vector_index2-7)*32 +: 32];
                end
            else 
		begin 
			word16 = 0; 
			word7 = 0; 
		end
        end

    assign new_word = (sigma0_s0word + sigma1_s1word) + (word16 + word7);


endmodule

module hash_update #(parameter WK_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  wire                             enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                             wk_index_complete,
    input  wire [255:0]                     prev_hash,
    input  wire [31:0]  		            cur_w,
    input  wire [31:0]  		            cur_k,

    /*-----------Outputs--------------------------------*/

    output reg                              hash_complete,  /* message formation complete flag */
    output reg [255:0]                      updated_hash
);


    reg [31:0] h0;
    reg [31:0] h1;
    reg [31:0] h2;
    reg [31:0] h3;
    reg [31:0] h4;
    reg [31:0] h5;
    reg [31:0] h6;
    reg [31:0] h7;

    reg [31:0] a;
    reg [31:0] b;
    reg [31:0] c;
    reg [31:0] d;
    reg [31:0] e;
    reg [31:0] f;
    reg [31:0] g;
    reg [31:0] h;
    wire [31:0] w;
    wire [31:0] k;

    reg [31:0] summation0_output;
   // reg [63:0] a_n;
    reg [31:0] a_r1;
    reg [31:0] a_r2;
    reg [31:0] a_r3;


    reg [31:0] summation1_output;
    reg [63:0] e_n;
    reg [31:0] e_r1;
    reg [31:0] e_r2;
    reg [31:0] e_r3;

    reg [31:0] major_output;
    reg [31:0] m1;
    reg [31:0] m2;
    reg [31:0] m3;

    reg [31:0] choice_output;
    reg [31:0] c1;
    reg [31:0] c2;

    wire [31:0] ms0;
    wire [31:0] cs1;
    wire [31:0] t1;
    wire [31:0] t2;

    reg [31:0] a_new;
    reg [31:0] b_new;
    reg [31:0] c_new;
    reg [31:0] d_new;
    reg [31:0] e_new;
    reg [31:0] f_new;
    reg [31:0] g_new;
    reg [31:0] h_new;

    reg                              hash_complete1;
    reg                              hash_complete2;

    reg                              enable1;
    reg                              enable2;
    always @(posedge clock)
        begin
            if(reset) begin
                updated_hash <= 0;
            end
            else if(!enable2) begin
                updated_hash <= prev_hash;
            end
            else if(!hash_complete)
                begin
                            updated_hash[32*0 +: 32] <= a_new;
                            updated_hash[32*1 +: 32] <= b_new;
                            updated_hash[32*2 +: 32] <= c_new;
                            updated_hash[32*3 +: 32] <= d_new;
                            updated_hash[32*4 +: 32] <= e_new;
                            updated_hash[32*5 +: 32] <= f_new;
                            updated_hash[32*6 +: 32] <= g_new;
                            updated_hash[32*7 +: 32] <= h_new;
                      
                end
            else updated_hash <= updated_hash;

            hash_complete1 <= wk_index_complete;
            hash_complete2 <= hash_complete1;
            hash_complete <= hash_complete2;

            enable1 <= enable;
            enable2 <= enable1;
        end

    always @(*)
        begin
            if(!hash_complete)
                begin
                            a = updated_hash[32*0 +: 32];
                            b = updated_hash[32*1 +: 32];
                            c = updated_hash[32*2 +: 32];
                            d = updated_hash[32*3 +: 32];
                            e = updated_hash[32*4 +: 32];
                            f = updated_hash[32*5 +: 32];
                            g = updated_hash[32*6 +: 32];
                            h = updated_hash[32*7 +: 32];
                end
            else
                begin
                    a = 0;
                    b = 0;
                    c = 0;
                    d = 0;
                    e = 0;
                    f = 0;
                    g = 0;
                    h = 0;
                end
        end

    assign w = (hash_complete) ? 0 : cur_w;
    assign k = (hash_complete) ? 0 : cur_k;

    always @(*)
        begin
            if(enable2 && !hash_complete)
                begin
                    //a_n = {a, a};
                    a_r1 = {a[1:0], a[31:2]};// >> 2;
                    a_r2 = {a[12:0], a[31:13]}; //a_n >> 13;
                    a_r3 = {a[21:0], a[31:22]}; //a_n >> 22;
                    summation0_output = a_r1 ^ a_r2 ^ a_r3;
                end
            else 
		begin
		    a_r1 = 0;
                    a_r2 = 0;
                    a_r3 = 0;
		    summation0_output = 0;
		end
        end

    always @(*)
        begin
            if(enable2 && !hash_complete)
                begin
                   // e_n = {e, e};
                    e_r1 = {e[5:0], e[31:6]}; //e_n >> 6;
                    e_r2 = {e[10:0], e[31:11]}; //e_n >> 11;
                    e_r3 = {e[24:0], e[31:25]}; //e_n >> 25;
                    summation1_output = e_r1 ^ e_r2 ^ e_r3;
                end
		
            else 
		begin
		    e_r1 = 0;
                    e_r2 = 0;
                    e_r3 = 0;
			summation1_output = 0;
		end
        end

    always @(*)
        begin
            if(enable2 && !hash_complete)
                begin
                    m1 = a & b;
                    m2 = a & c;
                    m3 = b & c;
                    major_output = m1 ^ m2 ^ m3;
                end
            else begin
		m1 = 0;
		m2 = 0;
		m3 = 0;		
		major_output = 0;
		end
        end

    always @(*)
        begin
            if(enable2 && !hash_complete)
                begin
                    c1 = e & f;
                    c2 = (~e) & g;
                    choice_output = c1 ^ c2;
                end
            else 
		begin
		c1 = 0;
		c2 = 0;
		choice_output = 0;
		end
        end

    assign t2 = summation0_output + major_output;
    assign t1 = (summation1_output + choice_output) + (w + k) + h;

    always @(*)
        begin
                    h0 = prev_hash[32*0 +: 32];
                    h1 = prev_hash[32*1 +: 32];
                    h2 = prev_hash[32*2 +: 32];
                    h3 = prev_hash[32*3 +: 32];
                    h4 = prev_hash[32*4 +: 32];
                    h5 = prev_hash[32*5 +: 32];
                    h6 = prev_hash[32*6 +: 32];
                    h7 = prev_hash[32*7 +: 32];
         
            if(!hash_complete2)
                begin
                    a_new = t1 + t2;
                    b_new = a;
                    c_new = b;
                    d_new = c;
                    e_new = t1 + d;
                    f_new = e;
                    g_new = f;
                    h_new = g;
                end
            else if(!hash_complete)
                begin
                    a_new = t1 + t2 + h0;
                    b_new = a + h1;
                    c_new = b + h2;
                    d_new = c + h3;
                    e_new = t1 + d + h4;
                    f_new = e + h5;
                    g_new = f + h6;
                    h_new = g + h7;
                end
            else
                begin
                    a_new = a;
                    b_new = b;
                    c_new = c;
                    d_new = d;
                    e_new = e;
                    f_new = f;
                    g_new = g;
                    h_new = h;
                end
        end

endmodule

module store_hash #(parameter HASH_LENGTH = 8
) (

    /*-----------Inputs--------------------------------*/

    input                                    clock,  /* clock */
    input                                    reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [ $clog2(HASH_LENGTH)-1:0]   h_address,
    input  wire [255:0]                      hash_vector,

    /*-----------Outputs--------------------------------*/
    output reg [31:0]                        h_data,
    output reg	                             h_write,
    output reg                               h_vector_complete,  /* hash formation complete flag */
    output reg [ $clog2(HASH_LENGTH)-1:0]    h_output_address
);

  
    reg [ $clog2(HASH_LENGTH)-1:0]   hash_address1;
    reg [ $clog2(HASH_LENGTH)-1:0]   hash_address2;
    reg                              h_vector_complete1;
    reg                              h_vector_complete2;
    reg                              enable1;
    reg                              enable2;
    always @(posedge clock)
        begin
            if(reset || !enable2) begin
                h_vector_complete <= 0;
                h_write <= 0;
                h_output_address <= 0;
            end
            else if(!h_vector_complete)
                begin
                    h_write <= 1;
                        h_data <= hash_vector[hash_address2*32 +: 32];
                    	h_output_address <= hash_address2;
                end
	    else
		begin
		  h_data <= h_data;
		  h_output_address <= h_output_address;
	          h_write <= 0;
		end

            h_vector_complete1 <= address_read_complete;
            h_vector_complete2 <= h_vector_complete1;
            h_vector_complete <= h_vector_complete2;

            hash_address1 <= h_address;
            hash_address2 <= hash_address1;
            enable1 <= enable;
            enable2 <= enable1;
        end
endmodule



