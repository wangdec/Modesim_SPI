module SPI_HW_32
(
 inout wire SPI_IN_OUT,
 output wire SPI_CLK,
 output wire SPI_SYNC,
 
 output reg SPI_MOSI,
 input wire SPI_MISO,

 input wire [31:0]Address,
 input wire [31:0]Write_Data,
 input wire nCS,
 input wire nWrite,
 input wire nRead,
 input wire [3:0]nByte,

 output reg nRead_WaitRequest,       //1->0=Top Module can Read data� from buffer. when nCS=1, this sign must pull up to 1.
 output reg [31:0]Read_Data,
 
 input wire Sys_Clock,
 input wire nReset
);
parameter SPI_3_Or_2 = 1;   //1= SPI 3; 0=SPI 2.
parameter SPI_Clock_Pority = 1;   //1 is Native; 0 is Passive.
parameter SPI_Edge= 1;   //1 is posedge; 0 is negedge
parameter Write_Delay = 2;    //SPI Ready delay clock number.
parameter Read_Delay = 2;    //SPI Ready delay clock number.
parameter SPI_Command_Len=16;       //16=every of SPI device Command is 16 bit.
parameter SPI_Data_Len=8;         //8=every of SPI device data is 8 bit.
parameter SPI_Sys_Clock_Half_Div=27;   //27=spi clock half divide number is 27, when sysclock is 108MHz, SPI clock will is 2Mhz
parameter SPI_Read_Pority = 1;   //1=read 1,write 0; 0=read 0, write 1.

reg [31:0]Command_Buf[7:0];
reg [31:0]Data_Buf[7:0];
reg [7:0]Command_Buf_Num;
reg [7:0]Data_Buf_Num;

reg [7:0]Command_Buf_Num_1;
reg [7:0]Data_Buf_Num_1;
reg Flag_Command_End;
reg Flag_Data_End;

reg [7:0]Divide_Num_clk;
reg Clock_Divide;
reg [31:0]Read_Write;

reg SPI_Clock_Control;
reg [31:0]SPI_Clock_Num_2;
reg [31:0]SPI_Clock_Num_T;
reg [31:0]SPI_Clock_Com_Num_cyc;
reg Flag_command;


//设计支持正时钟，上升沿对外部器件读写数据,MSB模式

//主控器发出读写指令和数据，模块缓存数据，并准备开始对外部器件操作

always @(posedge Sys_Clock or negedge nReset or posedge nCS)
	begin
	 if(!nReset)
	  begin
     Command_Buf_Num=0;
		 Data_Buf_Num=0;
		 Command_Buf_Num_1=0;
		 Data_Buf_Num_1=0;
		 Flag_Command_End=0;
		 Flag_Data_End=0;
	  end
    else if(nCS)     //nCS为高时数据清零
	  begin
		 Command_Buf_Num_1=0;
		 Data_Buf_Num_1=0;
		 Flag_Command_End=0;
		 Flag_Data_End=0;
	  end
	 else
	  begin
	   case(Address)
	     1: 
	      Command_Buf_Num=Write_Data>>({(32){1'b1}}>>(32-nByte*8));
	     2: 
	      begin
	       Command_Buf[Command_Buf_Num_1]=Write_Data>>({(32){1'b1}}>>(32-nByte*8));
	       if(Command_Buf_Num_1==0)
	         begin
	          if(!nRead)
	           begin
	            if(SPI_Read_Pority)
	             Command_Buf[0]=32'h80000000 | Command_Buf[0];
	            else
	             Command_Buf[0]=32'h7FFFFFFF & Command_Buf[0]; 
	           end
	          else if(!nWrite) 
	           begin
	            if(SPI_Read_Pority)
	             Command_Buf[0]=32'h7FFFFFFF & Command_Buf[0];
	            else
	             Command_Buf[0]=32'h80000000 | Command_Buf[0]; 
	           end
	         end
	       Command_Buf_Num_1=Command_Buf_Num_1+1;
	       if(Command_Buf_Num_1>=Command_Buf_Num)
	        Flag_Command_End=1;
	      end
	     3:
	      Data_Buf_Num=Write_Data>>({(32){1'b1}}>>(32-nByte*8));
	     4:
	      begin
	       Data_Buf[Data_Buf_Num_1]=Write_Data>>({(32){1'b1}}>>(32-nByte*8));
	       Data_Buf_Num_1=Data_Buf_Num_1+1;
	       if(Data_Buf_Num_1>=Data_Buf_Num)
	        Flag_Data_End=1;
	      end
	     default:
	      begin
	       Data_Buf_Num_1=0;
	       Command_Buf_Num_1=0;
	      end
	    endcase
	  end		
	end


//SPI Clock
	always@(negedge Sys_Clock or negedge nReset) 
	 begin
	   if(!nReset)
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

 always@(negedge Clock_Divide or negedge nReset  or negedge Flag_Data_End)
  begin
   if(!nReset)
		 begin
      SPI_Clock_Control=0;
      
      SPI_Clock_Num_T=0;
      SPI_Clock_Com_Num_cyc=0;
      Flag_command=1;
		 end
   else if(!Flag_Data_End) 
    begin
      SPI_Clock_Control=0;
      
      SPI_Clock_Num_T=0;
      SPI_Clock_Com_Num_cyc=0;
      Flag_command=1;
    end
   else
    begin
     Read_Write=Command_Buf[0];
     if(Read_Write[0]^SPI_Read_Pority)     //Read
      begin
       if(Flag_command)               //write commad cycle
        begin
         if(SPI_Clock_Com_Num_cyc<SPI_Command_Len)
          SPI_Clock_Control=1;
         else if(SPI_Clock_Com_Num_cyc<SPI_Command_Len+Write_Delay)
          SPI_Clock_Control=0;
         else
          begin
           SPI_Clock_Com_Num_cyc=0;
           SPI_Clock_Num_T=SPI_Clock_Num_T+1;
           if(SPI_Clock_Num_T<=Command_Buf_Num)
            SPI_Clock_Control=1;
           else
            begin
              Flag_command=0;
              SPI_Clock_Com_Num_cyc=0;
              SPI_Clock_Num_T=0;
            end
          end
        end 
       else         //read data cycle
        begin
         if(SPI_Clock_Com_Num_cyc<SPI_Data_Len)
          SPI_Clock_Control=1;
         else if(SPI_Clock_Com_Num_cyc<SPI_Data_Len+Read_Delay)
          SPI_Clock_Control=0;
         else
          begin
           SPI_Clock_Com_Num_cyc=0;
           SPI_Clock_Num_T=SPI_Clock_Num_T+1;
           if(SPI_Clock_Num_T<=Data_Buf_Num)
            SPI_Clock_Control=1;
           else
            begin
              Flag_command=1;
              SPI_Clock_Com_Num_cyc=0;
              SPI_Clock_Num_T=0;
            end
          end
        end 
      end
     else                            //write
      begin
       if(Flag_command)               //write commad cycle
        begin
         if(SPI_Clock_Com_Num_cyc<SPI_Command_Len)
          SPI_Clock_Control=1;
         else if(SPI_Clock_Com_Num_cyc<SPI_Command_Len+Write_Delay)
          SPI_Clock_Control=0;
         else
          begin
           SPI_Clock_Com_Num_cyc=0;
           SPI_Clock_Num_T=SPI_Clock_Num_T+1;
           if(SPI_Clock_Num_T<=Command_Buf_Num)
            SPI_Clock_Control=1;
           else
            begin
              Flag_command=0;
              SPI_Clock_Com_Num_cyc=0;
              SPI_Clock_Num_T=0;
            end
          end
        end 
       else         //write data cycle
        begin
         if(SPI_Clock_Com_Num_cyc<SPI_Data_Len)
          SPI_Clock_Control=1;
         else if(SPI_Clock_Com_Num_cyc<SPI_Data_Len+Write_Delay)
          SPI_Clock_Control=0;
         else
          begin
           SPI_Clock_Com_Num_cyc=0;
           SPI_Clock_Num_T=SPI_Clock_Num_T+1;
           if(SPI_Clock_Num_T<=Data_Buf_Num)
            SPI_Clock_Control=1;
           else
            begin
              Flag_command=1;
              SPI_Clock_Com_Num_cyc=0;
              SPI_Clock_Num_T=0;
            end
          end
        end 
      end
    end
  end  
  
  	 
assign SPI_CLK=SPI_Clock_Control?Clock_Divide:(SPI_Clock_Pority?1:0);
endmodule