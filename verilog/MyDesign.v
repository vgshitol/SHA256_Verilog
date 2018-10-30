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
		
	reg next_dut__msg__enable;
	reg [ $clog2(MAX_MESSAGE_LENGTH)-1:0]	next_dut__msg__address;
	reg address_read_complete;
	reg [439:0] message_vector;
	reg [$clog2(439): 0] msg_vec_msb_pnt;
	reg [$clog2(439): 0] msg_vec_lsb_pnt;
	reg [7:0] msg_vec[0:54];
	integer vec_cnt;
 // `include "v564.vh"

    always @(xxx__dut__go or dut__msg__enable)
    begin
	if(!xxx__dut__go && !dut__msg__enable) next_dut__msg__enable = 0;
	else next_dut__msg__enable = 1;
    end

    always @(*)
    begin
	if(!address_read_complete && !dut__msg__enable) next_dut__msg__address = 0;
	else if(!address_read_complete && dut__msg__enable) 
		begin 
		msg_vec_msb_pnt = ((xxx__dut__msg_length - dut__msg__address)*8 - 1) ;
		msg_vec_lsb_pnt =  msg_vec_msb_pnt - 7 ;
		next_dut__msg__address = dut__msg__address + 1;
		end
	else next_dut__msg__address = dut__msg__address;
    end
	
   always @(posedge clk)
	begin
	if(reset) begin 
	dut__msg__address <= 0;
	dut__msg__enable <= 0;
	address_read_complete <= 0;
	end
	else begin
	dut__msg__write <= 0;
	dut__msg__address <= next_dut__msg__address;
	dut__msg__enable <= next_dut__msg__enable;
	msg_vec[dut__msg__address] <= msg__dut__data;
	address_read_complete <= (xxx__dut__msg_length-1 <= dut__msg__address) ? 1 : 0;	
	end
end

always @(address_read_complete)
message_vector = 0;
if(address_read_complete) 
begin
for (i = 0 ; i < 8; i = i + 1)
for (j = 0; j < xxx__dut__msg_length ; j = j+1)
msg_vec[j][i] 
end 
/**

always @(posedge clk)
begin
if(!address_read_complete && dut__msg__enable) 
		begin
		for (vec_cnt=msg_vec_msb_pnt; vec_cnt>= msg_vec_lsb_pnt; vec_cnt=vec_cnt-1) begin
            		message_vector[vec_cnt] <= msg__dut__data[msg_vec_msb_pnt - vec_cnt];
		end
	end
else message_vector[vec_cnt];
end
**/
 //  always @(address_read_complete)
	
 
  // 
  //---------------------------------------------------------------------------

endmodule

