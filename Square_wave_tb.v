module Square_wave_tb  ; 

parameter DA_Clock_Half_Div  = 3 ;
parameter Disable  = 65535 ;
parameter Max_DA_Data_Bit  = 6 ;
parameter Max_Clock_Half_Div  = 5400 ;
parameter Duration  = 10000 ;
parameter Min_Clock_Half_Div  = 54 ; 
parameter  DA_Data_Step=2;
  wire    DA_Clock   ; 
  reg    nReset   ; 
  reg    Sys_Clock   ; 
  wire  [13:0]  DA_Data   ; 
  Square_wave    #( Duration , Disable  , Max_Clock_Half_Div  , Min_Clock_Half_Div ,Max_DA_Data_Bit,  DA_Clock_Half_Div,DA_Data_Step )
   DUT  ( 
       .DA_Clock (DA_Clock ) ,
      .nReset (nReset ) ,
      .Sys_Clock (Sys_Clock ) ,
      .DA_Data (DA_Data ) ); 
      
 initial 
  begin
   fork
    #5 nReset=0;
    #20 nReset=1;
   join
    
   #30 Sys_Clock = 1'b0;
   forever #5  Sys_Clock = !Sys_Clock;
  end     


endmodule

