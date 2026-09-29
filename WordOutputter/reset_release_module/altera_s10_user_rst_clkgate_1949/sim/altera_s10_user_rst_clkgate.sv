// (C) 2001-2026 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ns / 1 ns
module altera_s10_user_rst_clkgate (
	output logic ninit_done
);

	localparam USER_RESET_DELAY = 0;
	
	initial begin
		#0 ninit_done = 1;
		#1 ninit_done = 0;
	end
					
	
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "YZ38Y1+HPopSA1TlC3H91qmXZEQu+ydYw0xxwe6vzV6Zb6QrYO9D75OSqICi5+S47PQvfuRbSKG1hWOj/ZLI1YYotjeI7qaMj39CfeJyXZp0MXuw/A1U0JwhWVHTIQCrbtcgL76bTTBRXtVxiD2wwEN0VrVtRGeLCkhMvvLrC1Gssuu18sRRyohgYV9nE9CiqBQaqMzSNyLvbCrcUR0aLW/Ol73OI5rotU8CzPZ2iMPZ5X2SbMx7/RJSxX2CgrMp2olpzlTjDzTvh7bUVSXTyrl0lvbW6rMvUsHRrLklsr+FtFAy5UmSYaH16D1eS+UlwlR6mMT/pMPWuC5d+QLuZgMgyUz2nHpkwGe+70DJYAjDm6djTUb7RUSn9iq1Sf2JFcQTT+kUVxOBRjrmB3x3p/kyOTTQ190ol6YsYNZ81kI874brFT5PHonWLZ5KKW6jHjQLlbmNj5ulrLJV0PxU8mHascPuuIUEfHLgGVyL7wVYr2x5piQztpPpmKsbiGcKdPrupHjF/STkhE2uiF2K+DYbMsMbimt1FDYnikhiHNt5s/tcg6i/XuoclECKGuAv1tV7Xg1SnHIBSxq6ASJ6ZIUoKRdfIHQv1xpX4TzBLT7HVUDCvKgAMIkkTeRpoqsrciFb8jAPp9FqfrpapuH9WGbpGk102HXosHB7TGv5Eif0XMqfXZ8e6s8Nh0KW6kA1k6Xw+hUOZ0gAFa+yhTkIgUL0VOvfp1A30AbmJXMxwzVAzXJHBBRGpkkcDgjm8DlfF75mM/EYAYb20X/LtzGDcijLHq8XKcPdytxPFfDmv9X5gVNk7nDCjO+SUBFbipQWluOz7UptlgfVL2U9HDgm3/dBYN7t+1ejPWWB9W1JrXdaCpNNiSxIAJZ6lUPt8o/f/MQwpp+p1IotYyKvahc4eUem3jOvU05PyjgZ4vcZiRjJ5WIPB4OsCbgRc54StFGhvu4BfCvQOzs2nLzPJRbtV8mtHj3Nk3xDcmBkj6KJ0UzsjD8TUOHN6i99oPCzRSwn"
`endif