module SPI_3_to_2_tb  ; 

parameter Reand_Delay  = 1 ;
parameter SPI_Command_Len  = 16 ;
parameter SPI_Sys_Clock_Half_Div  = 27 ; 
  reg    SPI_SYNC   ; 
  wire    Control_Test   ; 
  reg    nReset   ; 
  reg    Clock_108M   ; 
  reg    SPI_SI_Fr_M   ; 
  wire    Control_Clock_Delay   ; 
  wire    SPI_SO_To_M   ; 
  wire    Slave_CLOCK_Delay_Control   ; 
  reg    Slave_IN_OUT_In   ; 
  wire    Slave_CLOCK   ; 
  wire    Control_Command   ; 
  wire    Slave_OUT_Test   ; 
  wire    Control_1   ; 
  wire  [23:0]  write_data   ; 
  reg    SPI_CLK   ; 
  wire  [23:0]  read_data   ; 
  wire    Base_CLOCK   ; 
  wire    Command_Test   ; 
  wire    Slave_IN_OUT_Out   ; 
  SPI_3_to_2    #( Reand_Delay , SPI_Command_Len , SPI_Sys_Clock_Half_Div  )
   DUT  ( 
       .SPI_SYNC (SPI_SYNC ) ,
      .Control_Test (Control_Test ) ,
      .nReset (nReset ) ,
      .Clock_108M (Clock_108M ) ,
      .SPI_SI_Fr_M (SPI_SI_Fr_M ) ,
      .Control_Clock_Delay (Control_Clock_Delay ) ,
      .SPI_SO_To_M (SPI_SO_To_M ) ,
      .Slave_CLOCK_Delay_Control (Slave_CLOCK_Delay_Control ) ,
      .Slave_IN_OUT_In (Slave_IN_OUT_In ) ,
      .Slave_CLOCK (Slave_CLOCK ) ,
      .Control_Command (Control_Command ) ,
      .Slave_OUT_Test (Slave_OUT_Test ) ,
      .Control_1 (Control_1 ) ,
      .write_data (write_data ) ,
      .SPI_CLK (SPI_CLK ) ,
      .read_data (read_data ) ,
      .Base_CLOCK (Base_CLOCK ) ,
      .Command_Test (Command_Test ) ,
      .Slave_IN_OUT_Out (Slave_IN_OUT_Out ) ); 



initial 
  begin
   Clock_108M = 1'b0;
   forever #5  Clock_108M = !Clock_108M;
  end

reg [7:0]data_number;
reg [7:0]index;
reg [SPI_Command_Len+7:0]data_write[2:0];
reg [SPI_Command_Len+7:0]data_temp;


always@(negedge SPI_CLK or negedge SPI_SYNC)
begin
 if(!SPI_SYNC) 
   begin
    SPI_SI_Fr_M=1;
    data_number=0;
    index=index+1;
   end
 else
  begin
   if(index>=3)index=0;
   if(data_number<SPI_Command_Len+8)
    begin
     data_temp=data_write[index];
     SPI_SI_Fr_M=data_temp[data_number];
     data_number=data_number+1'h1; 
    end
  end
end



initial   //clock, uint: 10ns==100MHz
  begin
//   $readmenb("SPICOMD.dat",data_write);
   data_write[0]=24'h013;
   data_write[1]=24'h036;
   data_write[2]=24'h055;
   nReset=1;
   data_number=0;
   index=0;
   SPI_CLK=1;
   SPI_SYNC=0;
   SPI_SI_Fr_M=1;

   fork
    #5 nReset=0;
    #20 nReset=1;
   join
  
   #500 SPI_SYNC=1;
   #5000 SPI_CLK=0;
   #500  SPI_CLK=1;   
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;    //8???
   
   
   #5000  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;    //?8???
   
   
   #5000  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;
   #500  SPI_CLK=0;
   #500  SPI_CLK=1;    //?8???
   
   #5000  SPI_SYNC=0;

  end
  
endmodule

