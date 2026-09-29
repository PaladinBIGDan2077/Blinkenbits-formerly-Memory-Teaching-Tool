module AutoFan(
	input				clk,
	input 			         reset_n,
	input		signed [7:0]	temp_fpga,
	output	[7:0]	         fan_ktach,
	input                   invalid_temp
);

assign fan_ktach = auto_ktach;

//ktach = ((992 * kscale ) / RPS ) - 1
//ktach = ((992 * kscale ) / (RPM/60) ) - 1
//ktach = ((992 * 4 ) / (RPM/60) ) - 1
parameter max_Speed =6000;// richard 6600;//5300 ; 
parameter min_Speed =3500 ; 

parameter offset =(max_Speed-min_Speed)/7 ;//5300 ~2000
parameter Speed1 =min_Speed+offset*7;
parameter Speed2 =min_Speed+offset*6;
parameter Speed3 =min_Speed+offset*5;
parameter Speed4 =min_Speed+offset*4;
parameter Speed5 =min_Speed+offset*3;
parameter Speed6 =min_Speed+offset*2;
parameter Speed7 =min_Speed+offset*1;
parameter Speed8 =min_Speed+offset*0;
parameter max_temp =70 ; 
parameter min_temp =40 ;
parameter Toffset  = (max_temp-min_temp)/6 ; //60~40 
parameter scale    =2 ;

`define TEMP_LEVEL_1 min_temp+Toffset*6 
`define TEMP_LEVEL_2 min_temp+Toffset*5 
`define TEMP_LEVEL_3 min_temp+Toffset*4 
`define TEMP_LEVEL_4 min_temp+Toffset*3 
`define TEMP_LEVEL_5 min_temp+Toffset*2 
`define TEMP_LEVEL_6 min_temp+Toffset*1 
`define TEMP_LEVEL_7 min_temp+Toffset*0


`define FAN_SPEED_1 ((992 * scale ) / (Speed1/60) ) - 1
`define FAN_SPEED_2 ((992 * scale ) / (Speed2/60) ) - 1
`define FAN_SPEED_3 ((992 * scale ) / (Speed3/60) ) - 1
`define FAN_SPEED_4 ((992 * scale ) / (Speed4/60) ) - 1
`define FAN_SPEED_5 ((992 * scale ) / (Speed5/60) ) - 1
`define FAN_SPEED_6 ((992 * scale ) / (Speed6/60) ) - 1
`define FAN_SPEED_7 ((992 * scale ) / (Speed7/60) ) - 1
`define FAN_SPEED_8 ((992 * scale ) / (Speed8/60) ) - 1


//-----------------
reg [7:0] temp_pre;

always@(posedge clk or negedge reset_n )
begin
	if (~reset_n)
		temp_pre <= 0;
	else
		temp_pre <= temp_fpga ;
end

//-----------------
reg TEMP_UP_FLAG;
always@(posedge clk or negedge reset_n )
begin
	if (~reset_n)
		TEMP_UP_FLAG <= 1'b1;
	else if (TEMP_UP_FLAG)
	begin
		if (temp_fpga < (temp_pre+1))
			TEMP_UP_FLAG <= 1'b0;
	end
	else
	begin
		if (temp_fpga > (temp_pre+1))
			TEMP_UP_FLAG <= 1'b1;
	end
end

//-----------------
reg [7:0] auto_ktach;
always@(posedge clk or negedge reset_n)
begin
	if (~reset_n)
		auto_ktach <= `FAN_SPEED_4;
	else if ( invalid_temp ) auto_ktach <= `FAN_SPEED_1;
	else if (TEMP_UP_FLAG)
	begin
     if (temp_fpga  >  `TEMP_LEVEL_1 ) 
			auto_ktach <= `FAN_SPEED_1;
     else if (temp_fpga  >  `TEMP_LEVEL_2 ) 
			auto_ktach <= `FAN_SPEED_2;
     else if (temp_fpga  >  `TEMP_LEVEL_3 ) 
			auto_ktach <= `FAN_SPEED_3;
     else if (temp_fpga  >  `TEMP_LEVEL_4 ) 
			auto_ktach <= `FAN_SPEED_4;
     else if (temp_fpga  >  `TEMP_LEVEL_5 ) 
			auto_ktach <= `FAN_SPEED_5;
     else if (temp_fpga  >  `TEMP_LEVEL_6 ) 
			auto_ktach <= `FAN_SPEED_6;
     else if (temp_fpga  >  `TEMP_LEVEL_7 ) 
			auto_ktach <= `FAN_SPEED_7;
     else
			auto_ktach <= `FAN_SPEED_8;
	end
	else
	begin
     if (temp_fpga  <  `TEMP_LEVEL_7 ) 
			auto_ktach <= `FAN_SPEED_8;
     else if (temp_fpga  <  `TEMP_LEVEL_6 ) 
			auto_ktach <= `FAN_SPEED_7;
     else if (temp_fpga  <  `TEMP_LEVEL_5 ) 
			auto_ktach <= `FAN_SPEED_6;
     else if (temp_fpga  <  `TEMP_LEVEL_4 ) 
			auto_ktach <= `FAN_SPEED_5;
     else if (temp_fpga  <  `TEMP_LEVEL_3 ) 
			auto_ktach <= `FAN_SPEED_4;
     else if (temp_fpga  <  `TEMP_LEVEL_2 ) 
			auto_ktach <= `FAN_SPEED_3;
     else if (temp_fpga  <  `TEMP_LEVEL_1 ) 
			auto_ktach <= `FAN_SPEED_2;
	  else
			auto_ktach <= `FAN_SPEED_1;
	
	end
	
end





endmodule

