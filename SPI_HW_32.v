module SPI_HW_32
(
 inout wire SPI_IN_OUT,
 output wire SPI_CLK,
 output wire SPI_SYNC,
 
 output reg SPI_MOSI,
 input wire SPI_MISO,

 input wire [31:0]Command,
 input wire [31:0]Write_Data,
 input wire nCS,
 input wire nWrite,
 input wire nRead,
 input wire [7:0]Command_Byte,
 input wire [7:0]Data_Byte,

 output reg Read_WaitRequest,       //H时表示读命令等待，L时为数据准备好了
 output reg [31:0]Read_Data,
 
 input wire Sys_Clock,
 input wire nReset
);
parameter SPI_3_Or_2 = 1;   //1标识为3线，0标识为2线
parameter Read_Delay = 2;    //SPI每8个时钟后的延时个数
reg [7:0]SPI_Command_Len;       //一般为16
reg [7:0]SPI_Data_Len;         //一般为8
parameter SPI_Sys_Clock_Half_Div=27;   //SPI时钟的半分频数，如主时钟为108M，而该值为27则SPI实际时钟为2M.

reg [SPI_Command_Len-1:0]Command_Buf;
reg [SPI_Data_Len-1:0]Data_Buf;
reg [7:0]Divide_Num_clk;
reg Clock_Divide;

//设计支持正时钟，上升沿对外部器件读写数据,MSB模式

//主控器发出读写指令和数据，模块缓存数据，并准备开始对外部器件操作

always @(posedge Sys_Clock or negedge nReset or posedge nCS)
	begin
	 if(!nReset)
	  begin
      SPI_Data_Len=8;
	   SPI_Command_Len=16;
		
	  end
    else if(nCS)     //nCS为高时数据清零
	  begin
	   
		
	  end
	 else
	  begin
	   SPI_Data_Len=Data_Byte;
	   SPI_Command_Len=Command_Byte;
	  
	  
	   if(!nWrite)
		begin


		end
	  end		
	end


//SPI时钟产生
	always@(negedge Sys_Clock or negedge nReset) 
	 begin
	   if(nReset==0)
		 begin
		  Divide_Num_clk=0;
		  Clock_Divide=1;
		 end
		else
		 begin
		  Divide_Num_clk=Divide_Num_clk+1'h1;
		  if(Divide_Num_clk>=SPI_Sys_Clock_Half_Div)
		   begin
		    Divide_Num_clk=0;
			 Clock_Divide=~Clock_Divide;
		   end
		 end
	 end

	 

endmodule