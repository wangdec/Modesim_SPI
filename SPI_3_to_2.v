module SPI_3_to_2
(
 input reg Slave_IN_OUT_In,
 output wire Slave_IN_OUT_Out,
// inout wire Slave_IN_OUT,
 output wire Slave_CLOCK,
 output wire Base_CLOCK,
 
 output wire SPI_SO_To_M,
 
 output wire Control_Test,
 output wire Control_1,
 output wire [23:0]write_data,
 output wire [23:0]read_data,
 output wire Command_Test,
 output wire Control_Command,
 output wire Control_Clock_Delay,
 output wire Slave_CLOCK_Delay_Control,
 
 output wire Slave_OUT_Test,
 
 input wire SPI_SI_Fr_M,
 input wire SPI_SYNC,   
 input wire SPI_CLK,
 input wire Clock_108M,
 input wire nReset
);
parameter SPI_Command_Len = 16;
parameter SPI_Sys_Clock_Half_Div= 27;
parameter Reand_Delay = 1;

reg Slave_IN_R;
reg Slave_OUT;
wire  Slave_IN;
reg SPI_SO_To_M_O;

reg [7:0]Divide_Num_clk;
reg [7:0]num_clk;
reg [7:0]read_num_clk;
reg Write_Read_Flag;
reg [SPI_Command_Len+8:0]Write_Buf;
reg [SPI_Command_Len+8:0]Read_Buf;

reg [4:0]Data_Num;
reg [4:0]Read_Data_Num;

reg Control;    //Control,Control2，Control3为SPI 时钟计数用16+8
reg Control2;   
reg Control3;

reg Control4;   //缓存数据读取控制脚计数
reg Control5;
reg Control_Data_1;

reg Control_Command2;   //Control_Command2,Control_Command3 时钟计数指令长度用16
reg Control_Command3;

reg Control_Clock;
reg Command_Clock;

reg Control6;   
reg Control7;
reg Delay1;   //SPI clock延迟
reg Delay2;

reg [7:0]Clock_Number;      //16+8个固定时钟计数
reg [7:0]Clock_Number2;    //缓存数据读取控制脚计数
reg [7:0]Clock_Number3;   //读命令时16个命令的IO三态控制计数
reg [7:0]Clock_Number4;   //delay计数
reg Clock_Divide;


//判断读写,仅仅支持在一条命令执行完成后sync才拉高的模式，主要就是主控器读取外设时，发完地址命令后sync不能释放，必须持续为低，直到读数据完成后才拉Sync.

//主控器必须是上升沿传数据或者读数据，以下逻辑通过下降沿给output赋值，确保器件在上升沿能获取到数据。

//9266只支持写数据为上升沿，而器件输出数据是在下降沿,即主控器只能是上升沿读数据
//只做支持8位数据

 //写数据
	  always@(posedge SPI_CLK or negedge SPI_SYNC or negedge nReset)    //主控器是正信号
	    begin 
		  if(!nReset)
		   begin
			 num_clk=0;
			 Write_Read_Flag=0;
			 Control=1;
			 Write_Buf={(SPI_Command_Len+8){1'b0}};
			end
		  else if(!SPI_SYNC)
		   begin
			 num_clk=0;
			 Write_Read_Flag=0;
			 Control=1;
			 Write_Buf={(SPI_Command_Len+8){1'b0}};
			end
		  else
		   begin
			 if(num_clk==0)Write_Read_Flag=SPI_SI_Fr_M;
		    if(!Write_Read_Flag)       //0说明是写命令
		     begin
		      if(num_clk<SPI_Command_Len+8)
				 begin
				   if(num_clk==SPI_Command_Len)Control=0;        //control的1->0下降沿触发时钟计数
				    if(num_clk==SPI_Command_Len+7)Control=1;
			  	   Write_Buf[num_clk]= SPI_SI_Fr_M;    //下降沿缓存赋值数据
				  end
				end
		     else if(Write_Read_Flag)                          //1说明是读命令
		      begin
		       if(num_clk<SPI_Command_Len)
			     begin
				   if(num_clk==SPI_Command_Len-1)             //control的1->0下降沿触发时钟计数
					 Control=0;
				   else 
					 Control=1;
				   Write_Buf[num_clk]= SPI_SI_Fr_M;    //下降沿缓存赋值数据
			     end
				end
		    num_clk=num_clk+1'h1;		
		   end
      end

		//Nois读数据	 Nois必须为上升沿取数据，转换模块返回数据可以下降沿给出，才有可能保证第1个上升沿有数据，否则主控器第一个下降沿取不到数据，滞后一个时钟
	  always@(negedge SPI_CLK or negedge SPI_SYNC or negedge nReset)    //主控器是正信号
	    begin 
		  if(!nReset)
			 read_num_clk=0;
		  else if(!SPI_SYNC)
			 read_num_clk=0;
		  else
		   begin
		    if(Write_Read_Flag)                          //1说明是读命令
		      begin
		       if(read_num_clk<SPI_Command_Len+8)
				  begin
				   if(read_num_clk>=SPI_Command_Len)
				    SPI_SO_To_M_O=Read_Buf[read_num_clk];
				  end
				end  
			 read_num_clk=read_num_clk+1'h1;
		   end
      end

	//时钟产生
	always@(negedge Clock_108M or negedge nReset) 
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

	//转换后的SPI时钟控制信号
 	always@(negedge Control or negedge nReset or posedge Control3 ) 
	   begin
		 if(!nReset)
		  Control2=0;
		 else if(Control3)Control2=0;
		 else
		  Control2=1;
		end
		
	always@(posedge Clock_Divide or negedge nReset)   
	 begin
	  if(!nReset)
	   begin
		 Clock_Number=0;
		 Control_Clock=0;
		 Control3=0;
		end
	  else if(!Control2)
	   begin
		 Clock_Number=0;
		 Control_Clock=0;
		 Control3=0;
		end
	  else
	   begin
		 Clock_Number=Clock_Number+1'h1;
		 if(Clock_Number<SPI_Command_Len+9+Reand_Delay)
			 Control_Clock=1;
		 else
		  begin
		   Control_Clock=0;
			Control3=1;
		  end
		end
 	 end	
	
	//获取缓存数据的控制信号
 	always@(negedge Clock_Divide or negedge nReset) 
	 begin
	  if(!nReset)
	   begin
		 Control_Data_1=1;
		 Clock_Number2=0;
		end
	  else if(!Control_Clock)
	   begin
		 Clock_Number2=0;
		 Control_Data_1=1;
		end
	  else
	   begin
		 Clock_Number2=Clock_Number2+1'h1;
		 if(Clock_Number2<SPI_Command_Len+1)
		   Control_Data_1=1;
		 else
			Control_Data_1=0;
		end
	 end		
	
	
	 /*	  
    //如下程序易出现control下降沿时基本与Clock_Divide同步，有时序竞争，以至于Control_Data_1有时会延后一个时钟
	//获取缓存数据的控制信号
 	always@(negedge Control or negedge nReset or posedge Control5 ) 
	   begin
		 if(!nReset)
		  Control4=0;
		 else if(Control5)Control4=0;
		 else
		  Control4=1;
		end
	
	always@(negedge Clock_Divide or negedge nReset) 
	 begin
	  if(!nReset)
	   begin
		 Control5=0;
		 Control_Data_1=0;
		 Clock_Number2=0;
		end
	  else if(!Control4)
	   begin
		 Clock_Number2=0;
		 Control_Data_1=0;
		 Control5=0;
		end
	  else
	   begin
		 Clock_Number2=Clock_Number2+1'h1;
		 if(Clock_Number2<SPI_Command_Len+2)
		   Control_Data_1=1;
		 else
		  begin
			Control5=1;
			Control_Data_1=0;
		  end
		end
	 end	
   */
	//获取读命令时数据的三态控制信号
 	always@(negedge Control or negedge nReset or posedge Control_Command3 ) 
	   begin
		 if(!nReset)
		  Control_Command2=0;
		 else if(Control_Command3)Control_Command2=0;
		 else
		  Control_Command2=1;
		end
	
	always@(posedge Clock_Divide or negedge nReset) 
	 begin
	  if(!nReset)
	   begin
		 Control_Command3=0;
		 Command_Clock=0;
		 Clock_Number3=0;
		end
	  else if(!Control_Command2)
	   begin
		 Clock_Number3=0;
		 Control_Command3=0;
		 Command_Clock=0;
		end
	  else
	   begin
		 Clock_Number3=Clock_Number3+1'h1;
		 if(Clock_Number3<SPI_Command_Len+1)
		   Command_Clock=1;
		 else
		  begin
			Control_Command3=1;
			Command_Clock=0;
		  end
		  
		end
	  	
	 end		
	 
	 	//获取16位字节后延时1个时钟的控制信号
 	always@(negedge Control or negedge nReset or posedge Control7) 
	   begin
		 if(!nReset)
		  Control6=0;
		 else if(Control7)Control6=0;
		 else
		  Control6=1;
		end
	
	always@(posedge Clock_Divide or negedge nReset) 
	 begin
	  if(!nReset)
	   begin
		 Clock_Number4=0;
		 Control7=0;
		 Delay1=0;
		end
	  else if(!Control6)
	   begin
		 Clock_Number4=0;
		 Control7=0;
		 Delay1=0;
		end
	  else
	   begin
		 Clock_Number4=Clock_Number4+1'h1;
		 if(Clock_Number4<SPI_Command_Len+1+Reand_Delay)
		   Delay1=1;
		 else
		  begin
			Control7=1;
			Delay1=0;
		  end
		end
	 end	
	
	 //从bufer写给9266
	always@ (negedge Slave_CLOCK or negedge Control_Clock)
	  begin
	   if(!Control_Clock)
		  Data_Num=0;
		else
		 begin
	     if(Write_Read_Flag==0)       //0说明是写命令
		   begin
			 if(Data_Num<SPI_Command_Len+8)
			  begin
         Slave_OUT=Write_Buf[Data_Num];    //三态
			   Data_Num=Data_Num+1'h1;
	        end
			end
		  else if(Write_Read_Flag==1)                          //1说明是读命令
		   begin
			 if(Data_Num<SPI_Command_Len)
			  begin
				 Slave_OUT=Write_Buf[Data_Num];    //三态
			   Data_Num=Data_Num+1'h1;
	        end
			end
	    end
	  end
	
		 //读取9266数据到buffer中
	always@ (posedge Slave_CLOCK or negedge SPI_SYNC or negedge nReset)
	  begin
	   if(!nReset)
		 begin
		  Read_Data_Num=0;
		  Read_Buf={(SPI_Command_Len+8){1'b0}};
		 end
		else if(!SPI_SYNC)
		 begin
		  Read_Data_Num=0;
		  Read_Buf={(SPI_Command_Len+8){1'b0}};
		 end  
		else if(Write_Read_Flag)                          //1说明是读命令
		 begin 
		   if(Read_Data_Num<SPI_Command_Len+8)
			  begin
			   if(!Control_Command)
//				  Read_Buf[Read_Data_Num]=Slave_IN_OUT;
          Read_Buf[Read_Data_Num]=Slave_IN_OUT_In;
			   Read_Data_Num=Read_Data_Num+1'h1;
	        end
		 end
	  end
 
 	always@(Control_Command)
    begin
	  if(Control_Command)
	    Slave_IN_R<=Slave_OUT;
		else
	    Slave_IN_R<=1'bz;	
	 end
  
	assign Base_CLOCK=Clock_Divide;
	assign Control_1=Control;
	assign write_data=Write_Buf;
	assign read_data=Read_Buf;
	assign SPI_SO_To_M=SPI_SO_To_M_O;

	assign Control_Command=(Write_Read_Flag)?Control_Data_1:{1'b1};
//	  Write_Read_Flag==1                          //1说明是读命令	
//   assign Slave_IN_OUT=Slave_IN_R;
	assign Slave_IN_OUT_Out=Slave_IN_R;
	
	assign Slave_CLOCK=(nReset & Control_Clock & ((~(Delay1&Control_Clock))| Command_Clock))?Clock_Divide:{1'b1};
	assign Slave_CLOCK_Delay_Control=Control_Clock & ((~(Delay1&Control_Clock))| Command_Clock);
	
   assign Control_Test=Control_Clock;	
	assign Command_Test=Command_Clock;
	assign Control_Clock_Delay=Delay1;
	
	assign Slave_OUT_Test=Write_Read_Flag;
endmodule