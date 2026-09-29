module BOARD_MANAGEMENT (	
    output reg I2C_READY,
    input clk_50,
    input reset_n,

    // device i2c interface
    inout I2C_SCL,
    inout I2C_SDA,

    // board info and control
    output signed [15:0] FPGA_Temperature,  // unit: C
    output signed[15:0] Board_Temperature,  // unit: C
    output signed[15:0] Board2_Temperature, // unit: C
    output [15:0] Fan_Speed,                // unit: RPM

    input         Auto_Fan_Speed,      // 1: enable audo speed control.0: user specify fan speed
    input  [15:0] Set_Fan_Speed  ,     // used when Auto_Fan_Speedis low

	
//-------------------------

	//FAN IC      
	output reg [ 7:0] TACH0, 
	output reg [ 7:0] TACH1, 
	output reg [ 7:0] DAC,
	output reg [ 7:0] ALARM,
		
	//--TEMP
	output            TEMP_BUSY, 
	output reg 			TEMP_VALID,	
	//442A
	output reg signed [ 7:0] A_LOCT1_H,
	output reg signed [ 7:0] A_REMT1_H,
	output reg signed [ 7:0] A_REMT2_H,
	output reg [ 7:0] A_STATUS,
	output reg [ 7:0] A_MFG_ID,
	output reg [ 7:0] A_DEV_ID,
			
		
	//--TEST -- 
   output reg       I2C_LO0P,	
	output reg [7:0] SLAVE_ADDR , 
   output reg [7:0] ST ,
   output reg [7:0] CNT,
	output reg [7:0] WCNT,
   output reg [7:0] W_WORD_DATA,
   output reg [7:0] W_POINTER_REG,
	
	output           W_WORD_END ,
   output reg       W_WORD_GO ,	
   output     [7:0] R_DATA,
	input            BUSY_GO_HI 

);


wire [7:0] user_ktach;
assign   user_ktach =  ((992 * KSCALE ) / (Set_Fan_Speed/60) ) - 1;

//---- output to MAX6650 KTACH ; 
wire      [ 7:0] KTACH;
assign  KTACH = Auto_Fan_Speed? auto_ktach :user_ktach ; 


//-----MAX Temperature ( FPGA, Board , Board2 ) to Auto fan --- 
reg signed[7:0] AutoFan_temp=40 ; 
always @ (posedge CLK_400K or negedge reset_n )
begin
	if (~reset_n)
		AutoFan_temp <= 40;
	else begin 
	        if ((FPGA_Temperature   >=Board_Temperature ) &&  (FPGA_Temperature   >= Board2_Temperature)) AutoFan_temp   <= FPGA_Temperature;
	   else if ((Board_Temperature  >=FPGA_Temperature  ) &&  (Board_Temperature  >= Board2_Temperature)) AutoFan_temp   <= Board_Temperature;
	   else if ((Board2_Temperature >=FPGA_Temperature  ) &&  (Board2_Temperature >= Board_Temperature )) AutoFan_temp   <= Board2_Temperature;
	   
	end  
end

//--------Auto FAN -----------------
wire invalid_temp ; 
wire [7:0]auto_ktach ;           
AutoFan AutoFan_inst(
	.clk         ( CLK_400K     ),
	.reset_n     ( reset_n      ),
	.temp_fpga   ( AutoFan_temp ),
	.fan_ktach   ( auto_ktach   ) ,
	.invalid_temp(invalid_temp  ) 
);
//----------------------------------------------------



/////

//---- output FAN speed
assign Fan_Speed   = 60 * TACH0  ;   //rpm  

//---- output FPGA temperature
assign FPGA_Temperature = A_REMT1_H ; 

//---- output BOARD temperature
assign  Board_Temperature = A_LOCT1_H ; 

//---- output BOARD2 temperature
assign  Board2_Temperature = A_REMT2_H ; 





//----400KHZ generater-----
wire CLK_400K;
CLOCKMEM CLOCKMEM_inst2(  .RESET_n(1), .CLK    (clk_50),.CLK_FREQ(125) ,.CK_1HZ (CLK_400K)) ;

//=======================================================
//  WIRE /REGISETER 
//=======================================================

//--I2C Main Controller--- 
reg  [31:0] DELY;

//-----I2C-BUS-I/O----
wire        SDAO;
wire        SCLO;
wire        W_WORD_SCL; 
wire        W_WORD_SDAO;  
wire        W_POINTER_SCL; 
wire        W_POINTER_END; 
reg         W_POINTER_GO;
wire        W_POINTER_SDAO; 
wire        R_SCL; 
wire        R_END; 
reg         R_GO; 
wire        R_SDAO;  

//=======================================================
//  Parameter  
//=======================================================
// I2C  W/R NUMBER 
parameter    WRITE_MAX      = 10; 
parameter    READ_MAX       = 10; 
    
//--- Temperature-Sensor IC (TMP442) Register -----    
parameter    SLAVE_ADDR_TA = 8'h98;
 
parameter    PA_CONF1      = 8'h09;    // Write configuration byte
parameter    PA_CONF2      = 8'h0a;    // Write configuration byte
parameter    PA_RATE       = 8'h0B;    // Write conversion rate byte
parameter    PA_MFG_ID     = 8'hFE;    //55h
parameter    PA_DEV_ID     = 8'hFF;    //42h
parameter    PA_LOCT1_H    = 8'h00;    //Read local temperature
parameter    PA_LOCT1_L    = 8'h10;    //Read local temperature
parameter    PA_REMT1_H    = 8'h01;    //Read remote temperature: returns latest temperature
parameter    PA_REMT1_L    = 8'h11;    //Read remote temperature: returns latest temperature
parameter    PA_REMT2_H    = 8'h02;    //Read remote temperature: returns latest temperature
parameter    PA_REMT2_L    = 8'h12;    //Read remote temperature: returns latest temperature
parameter    PA_STATUS     = 8'h08;    //Read status byte (flags, busy signal)
parameter    PA_SFRESET    = 8'hFC;    //oftware Reset(4

	 
//--- Fan IC (MAX6650) Register ----- 
//slave address   
parameter    SLAVE_ADDR_F   = 8'h90;

//registers address
parameter    P_SPEED        = 8'h00;
parameter    P_CONFIG       = 8'h02;
parameter    P_GPIO_DEF     = 8'h04;  
parameter    P_DAC          = 8'h06; 
parameter    P_ALARM_ENABLE = 8'h08;  
parameter    P_ALARM        = 8'h0a; 
parameter    P_TACH0        = 8'h0c;
parameter    P_TACH1        = 8'h0e;
parameter    P_COUNT        = 8'h16; 

//register value
parameter    CONFIG         = 8'h29;  // --FAN IC, to See Datasheet Page10, closed-loop operation, KSCALE = 2
parameter    GPIO_DEF       = 8'hf5;  // --FAN IC, To See Datasheet Page11, GPIO1 serves as a FULL ON input. GPIO0 serves as an ALERT output 
parameter    ALARM_ENABLE   = 8'h0f ; // --FAN IC ,to see Datasheet Page12, 
                                      // GPIO1 Alarm Enable, Tachometer Overflow Alarm Enable, Minimum Output Level Alarm Enabl, Maximum Output Level Alarm Enabl 
parameter    COUNT          = 8'h01;//0.5s count												 


//--TIME 
parameter    SEC=400_000;
parameter    SEC0d1=SEC/10;
parameter    SEC0d5=SEC/2;


//--- Fan SPEED KSCALE
parameter    KSCALE         = 2;
//------------------------------------
//=======================================================
//  Structural coding
//======================================================= 

assign TEMP_BUSY   = A_STATUS[7];  //A adc is making a conversion

//------
wire can_enable_alarm ; //<--- about 0.2s after reset
fan_timer timer_enable_alarm(  
.RESET_N   (reset_n),
.CLK       (CLK_400K) ,
.TIME_OUT  (can_enable_alarm)
);
																																		 
//--I2C Main Controller--- 
reg do_config ; //<--
always @(negedge reset_n or posedge CLK_400K )begin 
if (!reset_n  ) begin 
    ST <=0;
 	 W_POINTER_GO <=1;
    R_GO  <=1 ;		 
	 W_WORD_GO <=1;
	 WCNT <=0;  
	 CNT  <=0;
	 DELY <=0 ; 
    do_config   <=0;//<--
	 I2C_READY   <=0;
end 
else 
case (ST)
0: begin 
    ST     <=30; //---First ,  to do I2C write . 
	 W_POINTER_GO <=1;
    R_GO  <=1 ;		 
	 W_WORD_GO <=1;
	 WCNT <=0;  
	 CNT  <=0;
	 DELY <=0 ;   
    do_config   <=0;//<--
   end
//------------- READ -------	
1: begin 
    ST<=2; 
	end	
2: begin
        // FAN READ 
	          if ( CNT==0)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_F[7:0] ,P_ALARM };
		  else if ( CNT==1)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_F[7:0] ,P_TACH0 };
		  else if ( CNT==2)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_F[7:0] ,P_TACH1 };
		  else if ( CNT==3)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_F[7:0] ,P_DAC };
		  //TEMP READ    
		  else if ( CNT==4)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_TA[7:0] ,PA_MFG_ID };
		  else if ( CNT==5)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_TA[7:0] ,PA_DEV_ID  };
		  else if ( CNT==6)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_TA[7:0] ,PA_STATUS };		  
		  else if ( CNT==7)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_TA[7:0] ,PA_LOCT1_H };
		  else if ( CNT==8)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_TA[7:0] ,PA_REMT1_H};		                
		  else if ( CNT==9)      {SLAVE_ADDR[7:0] ,W_POINTER_REG}<= {SLAVE_ADDR_TA[7:0] ,PA_REMT2_H};	
		  		  
		  		  
		                
	if ( W_POINTER_END ) begin  
	   W_POINTER_GO  <=0; 
		ST<=3 ; 
		DELY<=0;  
	 end
	end                
	//------- Write Pointer
3: begin 
    DELY  <=DELY +1;
    if ( DELY ==2 ) begin 
      W_POINTER_GO  <=1;
      ST<=4 ; 
	 end
	end       
4: begin 
    if  ( W_POINTER_END ) ST<=5 ; 	
	end              
5: begin 
    ST<=6 ; 
	end 
	//------- Read DATA  		 
6: begin 
	 if ( R_END ) begin  
	  R_GO  <=0; 
	  ST<=7 ; 
	  DELY<=0; 
	 end
	end                
7: begin 
    DELY  <=DELY +1;
    if ( DELY ==2 ) begin 	 
      R_GO  <=1;
      ST<=8 ; 
	 end
	end       
8: begin 
     ST<=9 ; 
	end       
9: begin 
   if  ( R_END ) 
	 begin 		
	      //---FAN READ  
		        if ( CNT==0) 	ALARM<=R_DATA ; 
		   else if ( CNT==1) 	TACH0<=R_DATA ;
			else if ( CNT==2) 	TACH1<=R_DATA ;
		   else if ( CNT==3) 	DAC  <=R_DATA ;
	 	//-- TEMP READ 
		   else if ( CNT==4) 	A_MFG_ID <=R_DATA ; 
		   else if ( CNT==5) 	A_DEV_ID <=R_DATA ; 
		   else if ( CNT==6) 	A_STATUS <=R_DATA ; ///6
		   else if ( CNT==7) 	A_LOCT1_H<=R_DATA ; 
		   else if ( CNT==8)    A_REMT1_H<=R_DATA ; 
		   else if ( CNT==9)    A_REMT2_H<=R_DATA ; 
	      CNT<=CNT+1 ;
	      ST<=10 ; 	
	 end 
  end	
10: begin   
     if ( CNT == READ_MAX) 
	   begin
		 TEMP_VALID <= 1;	
	    CNT <= 2 ; 
		 ST  <= 11; 
		 I2C_READY   <=1;
		end
	  else if ( ( CNT==2) &&  (!do_config)) 	ST<=30; //write
	  else begin   
	        ST<=1;
			  if ( (CNT == 7) && TEMP_BUSY    ) CNT <= 6 ; // TMP441_A read check busy again
		end 	
		  DELY <=0;
	     W_POINTER_GO <=1;
        R_GO         <=1 ;		 
	     W_WORD_GO    <=1; 		    		 		  
	 end 
	 
11: begin 
	  DELY   <=DELY+1; 
     if (DELY == 20) begin  
	      ST         <= 29; 
			TEMP_VALID <= 0;
	  end 	 
 end	
//----  READ END ----

//----  WRITE----
29: begin 
     if (DELY < 10 ) DELY <=DELY+1; 
	  else  ST<=31; 
    end	
30: begin 
	  ST<=31; 
    end	
31: begin 
      //TEMP WRITE 
           if ( WCNT==0) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_TA ,PA_SFRESET, 8'hff} ;  end //RESET
      else if ( WCNT==1) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_TA ,PA_CONF1, 8'h00  } ;  end //onvert continuouslyeasurement range (–55°C to +127°C)
      else if ( WCNT==2) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_TA ,PA_CONF2, 8'h3c  } ;  end //1 = External channel 2 enabled//1 = External channel 1 enabled//1 = Local channel enabled// = Resistance correction enabled
      else if ( WCNT==3) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_TA ,PA_RATE , 8'h0b  } ;  end // 110:ONVERSIONS/SEC=4, 0.25 sec


      //FAN WRITE 
           if ( WCNT==4 ) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_F ,P_COUNT     ,  COUNT };  end
      else if ( WCNT==5 ) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_F ,P_CONFIG      ,8'h0a };  end
		else if ((WCNT==6 ) && ( ( TACH0>50) | can_enable_alarm)) begin  
		   do_config<=1; 
		   {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_F ,P_ALARM_ENABLE,ALARM_ENABLE}; 			
		end	
			//<--
      else if ( WCNT==7 ) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_F ,P_CONFIG      ,CONFIG };  end
      else if ( WCNT==8 ) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_F ,P_GPIO_DEF,    GPIO_DEF}; end		 						  		
	   else if ( WCNT==9 ) begin {SLAVE_ADDR ,W_POINTER_REG ,W_WORD_DATA} <= { SLAVE_ADDR_F ,P_SPEED       ,KTACH  };  end	
		       
	 if (  W_WORD_END ) begin  
	   W_WORD_GO  <=0; 
		ST   <=32 ;  
		DELY <=0;  
	 end
	end           
32: begin 
    DELY  <=DELY +1;
	   if (  DELY ==5 )  begin
        W_WORD_GO  <=1;
        ST<=33 ; 
	 end
	 
	end       
33: begin 
    ST<=34 ; 
	end       	
34: begin 
     if  ( W_WORD_END )  begin 	
			 WCNT<=WCNT+1 ;			 
			 ST   <=35 ; 
	  end
	end              
35: begin
    if (( WCNT ==7) && (!do_config) )begin //READ
	 	      ST    <= 1; 
				WCNT  <= 5;
				CNT   <= 0; 
	  end 
	 else  if ( WCNT != WRITE_MAX )  ST<=31 ; 	  
	 else  
		begin 
	         ST       <= 36; 
	 			WCNT     <= WRITE_MAX-1;  
				CNT      <= 0; 
				DELY     <= 0;
				I2C_LO0P <= 0;
	   end 
	 end 
36: begin
    I2C_LO0P <= 0 ; 
    if ( DELY ==SEC0d5   ) begin 
	    ST <=37; 
	 end 	
	 else DELY  <= DELY +1;
	 end 
37: begin 
		 ST <=1;
	 end  
endcase
end
//-----------------------------MAIN-ST END ------------------------------------------

//============inout  i2c  q15(a10) example ===============  
// wire const_zero_sig /* synthesis keep */;
// assign const_zero_sig = 1\'b0;
// assign TRI_PIN = enable? const_zero_sig : \'bz;
//========================================================
wire   const_zero_sig/* synthesis keep */ ; 
assign I2C_SDA        = (SDAO)?1'bz :1'b0;
assign I2C_SCL        = (SCLO)?1'bz :1'b0;;
assign SCLO           = W_POINTER_SCL  & R_SCL   & W_WORD_SCL;
assign SDAO           = W_POINTER_SDAO & R_SDAO  & W_WORD_SDAO;

//==== I2C WRITE WORD ===
I2C_WRITE_BYTE  wrd(
   .RESET_N      ( reset_n),
	.PT_CK        ( CLK_400K),
	.GO           ( W_WORD_GO),
	.POINTER      ( W_POINTER_REG),
   .WDATA8	     ( W_WORD_DATA),
	.SLAVE_ADDRESS( SLAVE_ADDR ),
	.SDAI         ( I2C_SDA),
	.SDAO         ( W_WORD_SDAO),
	.SCLO         ( W_WORD_SCL ),
	.END_OK       ( W_WORD_END)
);

//==== I2C WRITE POINTER ===
I2C_WRITE_POINTER  wpt(
   .RESET_N      (reset_n   ),
	.PT_CK        ( CLK_400K ),
	.GO           ( W_POINTER_GO ),
	.POINTER      ( W_POINTER_REG),
	.SLAVE_ADDRESS( SLAVE_ADDR ),
	.SDAI         ( I2C_SDA    ),
	.SDAO         ( W_POINTER_SDAO),
	.SCLO         ( W_POINTER_SCL ),
	.END_OK       ( W_POINTER_END )
);

//-----I2C TO READ---- 
I2C_READ_DATA rd( 
   .RESET_N      ( reset_n    ),
	.PT_CK        ( CLK_400K   ),
	.GO           ( R_GO       ),
	.SLAVE_ADDRESS( SLAVE_ADDR ),
 	.BYTE_NUM     ( 0          ) , // I2C read 8 bit data 
	.SDAI         ( I2C_SDA),
	.SDAO         ( R_SDAO ),
	.SCLO         ( R_SCL  ),
	.END_OK       ( R_END  ),
	.DATA         ( R_DATA )
);
	
endmodule
	
