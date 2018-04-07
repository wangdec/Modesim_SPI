module Square_wave
(
 output wire [13:0]DA_Data,
 output wire DA_Clock,
 
 input wire Sys_Clock,
 input wire nReset
);
parameter Duration = 10000;    //持续多少个周期
parameter Disable = 65535;    //间隔多少个周期
parameter Max_Clock_Half_Div=5400;   //主时钟为108M，而该值为54则SPI实际时钟为1M.
parameter Min_Clock_Half_Div=54;   //主时钟为108M，而该值为5400则SPI实际时钟为10K.
parameter Max_DA_Data_Bit=6;   //最大的输出位数.
parameter DA_Clock_Half_Div=3;   //DA的输出时钟，3个为18M.

reg Clock_Divide;
reg Clock_Eable;
reg DA_Clock_Temp;

reg [31:0]Divide_Num_clk;
reg [31:0]Divide_Num_clk_Temp;
reg [31:0]Duration_Num_clk;
reg [31:0]Disable_Num_clk;

reg [31:0]DA_Num_clk;
reg [13:0]DA_Data_Temp;

//时钟产生
   always@(negedge Sys_Clock or negedge nReset) 
	 begin
	   if(!nReset)
		 begin
		  DA_Num_clk=0;
		  DA_Clock_Temp=1;
		 end
      else
       begin
		  DA_Num_clk=DA_Num_clk+1'h1;
		  if(DA_Num_clk>=DA_Clock_Half_Div)
		  	begin
			 DA_Clock_Temp=~DA_Clock_Temp;	
			 DA_Num_clk=0;
			end
		 end
	  end
			
			
	always@(negedge Sys_Clock or negedge nReset) 
	 begin
	   if(nReset==0)
		 begin
		  Clock_Eable=1;
		  Divide_Num_clk=0;
		  Clock_Divide=1;
		  Duration_Num_clk=0;
		  Disable_Num_clk=0;
		  Divide_Num_clk_Temp=Min_Clock_Half_Div;
		  DA_Data_Temp={(14){1'b1}};
		 end
		else if(Clock_Eable)    //输出信号计数
		 begin
		  if(Divide_Num_clk[0])
		    Duration_Num_clk=Duration_Num_clk+1'h1;
		  if(Duration_Num_clk<=Duration)
		   begin
			 if(Divide_Num_clk<=Max_Clock_Half_Div && Divide_Num_clk>=Divide_Num_clk_Temp) 
			   begin
				 Clock_Divide=~Clock_Divide;
				 Divide_Num_clk=0;
				 if(Clock_Divide)
				  Divide_Num_clk_Temp=Divide_Num_clk_Temp+Min_Clock_Half_Div;
				end		  
			end 
		  else if(Divide_Num_clk>Max_Clock_Half_Div || Duration_Num_clk>Duration )
	      begin
	       Divide_Num_clk=0;
		    Clock_Divide=0;
		    Duration_Num_clk=0;
		    Disable_Num_clk=0;
		    Divide_Num_clk_Temp=Min_Clock_Half_Div;
			 Clock_Eable=0;
         end
        Divide_Num_clk=Divide_Num_clk+1'h1;		
		 end
		else if(!Clock_Eable)  //暂停输出信号计数
		 begin
		  if(Divide_Num_clk[0])
		    Disable_Num_clk=Disable_Num_clk+1'h1;
		  if(Disable_Num_clk>Disable)
		   begin
			 Clock_Eable=1;
			 Clock_Divide=1;
			 Divide_Num_clk=0;
			end
			Divide_Num_clk=Divide_Num_clk+1'h1;		
		 end
	 end
	 
	 
assign DA_Clock=DA_Clock_Temp;
assign DA_Data=(Clock_Divide)?(DA_Data_Temp>>Max_DA_Data_Bit):{(14){1'b0}};

endmodule