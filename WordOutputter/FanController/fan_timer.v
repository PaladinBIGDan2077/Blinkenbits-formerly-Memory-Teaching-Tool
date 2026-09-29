module fan_timer ( 
input RESET_N,
input CLK     , // 400KHz
output reg TIME_OUT=0
);

reg [31:0] DELAY =0;  // 20 bit is enough
always @( negedge RESET_N or posedge  CLK ) 
if (!RESET_N) begin 
    TIME_OUT <=0;
	 DELAY    <=0; 
end
else begin 
         //if (DELAY < 400000/5) DELAY<=DELAY+1;  ///400KHz, about 0.2 second
			if (DELAY < 400000/2) DELAY<=DELAY+1;  ///400KHz, about 0.5 second
	  else 
	   begin 
		 TIME_OUT  <= 1; 
		 DELAY     <= DELAY; 
		end  //delay0.2s
end 
endmodule 


