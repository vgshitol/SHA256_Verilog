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
	`include "../SupportingModules/msgEn.sv"
	`include "../SupportingModules/msg512Block.sv"
	`include "../SupportingModules/w64.v"		
	reg address_read_complete;
	reg message_vector_complete;
	reg w_vector_enable;
	reg [511:0] message_vector;
	parameter W_LENGTH = 64;
	reg  [ $clog2(W_LENGTH)-1:0]   w_vector_index;  // index of w
	reg w_vector_index_complete;
	reg [2095:0] w_vector;
	reg w_vector_complete;

/** Creating the Initial 512 Bit Block **/
	msgEn u0(.clock(clk), .reset(reset), .start(xxx__dut__go), .enable(dut__msg__enable));
	counter #(.MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)) u1(.clock(clk), .reset(reset), .start(dut__msg__enable), .msg_length(xxx__dut__msg_length), .read_address(dut__msg__address), .read_complete(address_read_complete));
	msg512Block #(.MSG_LENGTH(MAX_MESSAGE_LENGTH)) u2(.clock(clk), .reset(reset), .enable(dut__msg__enable), .address_read_complete(address_read_complete), .msg_address(dut__msg__address), .msg_write(dut__msg__write), .msg_data(msg__dut__data) , .prev_message_vector(message_vector), .message_vector_complete(message_vector_complete), .message_vector(message_vector));

/** Creating the W Vector**/
	msgEn u3(.clock(clk), .reset(reset), .start(address_read_complete), .enable(w_vector_enable));
	counter #(.MAX_MESSAGE_LENGTH(W_LENGTH)) u4(.clock(clk), .reset(reset), .start(w_vector_enable), .msg_length(W_LENGTH), .read_address(w_vector_index), .read_complete(w_vector_index_complete));
	w64 #(.W_LENGTH(W_LENGTH)) u5(.clock(clk), .reset(reset), .enable(w_vector_enable), .w_vector_index(w_vector_index), .w_index_complete(w_vector_index_complete), .message_vector(message_vector), .prev_w_vector(w_vector), .w_vector_complete(w_vector_complete), .w_vector(w_vector));
 
endmodule

