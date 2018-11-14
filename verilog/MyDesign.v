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
            input  wire  [ $clog2(MAX_MESSAGE_LENGTH):0] xxx__dut__msg_length ,

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
	`include "../SupportingModules/counter.v"
	`include "../SupportingModules/msgEn.v"
	`include "../SupportingModules/msg512Block.v"
	`include "../SupportingModules/w64.v"		
	`include "../SupportingModules/hash.v"		
	`include "../SupportingModules/k_vector.v"		
	`include "../SupportingModules/hash_process_1.v"	
	`include "../SupportingModules/store_hash.v"	
	
	reg address_read_complete;
	reg message_vector_complete;
	reg [511:0] message_vector;
	
	
/** Creating the Initial 512 Bit Block **/
	msgEn u0(.clock(clk), .reset(reset), .start(xxx__dut__go), .enable(dut__msg__enable));
	counter #(.MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)) u1(.clock(clk), .reset(reset), .start(dut__msg__enable), .msg_length(xxx__dut__msg_length), .read_address(dut__msg__address), .read_complete(address_read_complete));
	msg512Block #(.MSG_LENGTH(MAX_MESSAGE_LENGTH)) u2(.clock(clk), .reset(reset), .enable(dut__msg__enable), .address_read_complete(address_read_complete), .msg_address(dut__msg__address), 
.msg_write(dut__msg__write), .msg_data(msg__dut__data) , .prev_message_vector(message_vector), .message_vector_complete(message_vector_complete), .message_vector(message_vector));

	reg [$clog2(NUMBER_OF_Hs)-1:0]   hash_vector_index;  // index of hash
	reg hash_address_complete;
	reg [255:0] hash_vector;
	reg hash_vector_complete;

/** Creating Hash Vector **/
	msgEn u3(.clock(clk), .reset(reset), .start(xxx__dut__go), .enable(dut__hmem__enable));
	counter #(.MAX_MESSAGE_LENGTH(NUMBER_OF_Hs)) u4(.clock(clk), .reset(reset), .start(dut__hmem__enable), .msg_length(NUMBER_OF_Hs), .read_address(dut__hmem__address), .read_complete(hash_address_complete));
	hash #(.HASH_LENGTH(NUMBER_OF_Hs)) u5(.clock(clk), .reset(reset), .enable(dut__hmem__enable), .address_read_complete(hash_address_complete), .hash_address(dut__hmem__address), .hash_write(dut__hmem__write), 
.hash_data(hmem__dut__data) , .prev_hash_vector(hash_vector), .hash_vector_complete(hash_vector_complete), .hash_vector(hash_vector));

	reg k_address_complete;
	reg k_vector_complete;
	reg [31:0] cur_k_value;

/** Creating K Vector **/
	msgEn u6(.clock(clk), .reset(reset), .start(message_vector_complete && hash_vector_complete), .enable(dut__kmem__enable));
	counter #(.MAX_MESSAGE_LENGTH(NUMBER_OF_Ks)) u7(.clock(clk), .reset(reset), .start(dut__kmem__enable), .msg_length(NUMBER_OF_Ks), .read_address(dut__kmem__address), .read_complete(k_address_complete));
	k_vector #(.K_LENGTH(NUMBER_OF_Ks)) u8(.clock(clk), .reset(reset), .enable(dut__kmem__enable), .address_read_complete(k_address_complete), .k_address(dut__kmem__address), .k_write(dut__kmem__write), 
.k_data(kmem__dut__data) , .k_vector_complete(k_vector_complete), .cur_k_value(cur_k_value));

	reg [2047:0] w_vector;
	reg w_vector_complete;
	reg [31:0] cur_w_value;

/** Creating the W Vector**/
	w64 #(.W_LENGTH(NUMBER_OF_Ks)) u9(.clock(clk), .reset(reset), .enable(dut__kmem__enable), .w_vector_index(dut__kmem__address), .w_index_complete(k_address_complete), .message_vector(message_vector), 
.prev_w_vector(w_vector), .w_vector_complete(w_vector_complete), .w_vector(w_vector), .cur_w(cur_w_value));


	reg  [ $clog2(NUMBER_OF_Ks)-1:0]   wk_vector_index;  // index of w
	reg wk_vector_enable;
	reg wk_vector_index_complete;
	reg [255:0] updated_hash;
	reg hash_complete;

/** Processing Word and K Vector**/
	msgEn u10(.clock(clk), .reset(reset), .start(dut__kmem__enable), .enable(wk_vector_enable));
	counter #(.MAX_MESSAGE_LENGTH(NUMBER_OF_Ks)) u11(.clock(clk), .reset(reset), .start(wk_vector_enable), .msg_length(NUMBER_OF_Ks), .read_address(wk_vector_index), .read_complete(wk_vector_index_complete));
	hash_process_1 #(.WK_LENGTH(NUMBER_OF_Ks)) u12 (.clock(clk), .reset(reset), .enable(wk_vector_enable), .wk_index_complete(wk_vector_index_complete) , .wk_vector_index(wk_vector_index),
.prev_hash(hash_vector) , .hash_complete(hash_complete) , .updated_hash(updated_hash) , .cur_k(cur_k_value), .cur_w(cur_w_value));

	reg [$clog2(NUMBER_OF_Hs)-1:0]   hash_output_vector_index;  // index of hash
	reg hash_output_address_complete;
	reg hash_store_complete;
/** Storing the Hash Vector **/
	msgEn u13(.clock(clk), .reset(reset), .start(hash_complete), .enable(dut__dom__enable));
	counter #(.MAX_MESSAGE_LENGTH(SYMBOL_WIDTH)) u14(.clock(clk), .reset(reset), .start(dut__dom__enable), .msg_length(SYMBOL_WIDTH), .read_address(hash_output_vector_index), .read_complete(hash_output_address_complete));
	store_hash #(.HASH_LENGTH(NUMBER_OF_Hs)) u15(.clock(clk), .reset(reset), .enable(dut__dom__enable), .address_read_complete(hash_output_address_complete), .h_address(hash_output_vector_index), .hash_vector(updated_hash), .h_write(dut__dom__write), 
.h_data(dut__dom__data) , .h_vector_complete(dut__xxx__finish), .h_output_address(dut__dom__address));
endmodule

