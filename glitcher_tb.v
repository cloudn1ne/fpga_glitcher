`timescale 10ns / 1ns

module glitcher_test;

  parameter PLL_CLK_DELAY = 1;  // 100 MHz
  parameter MAIN_CLK_DELAY = PLL_CLK_DELAY*6;  // 16 MHz
  parameter TARGET_CLK_DELAY = PLL_CLK_DELAY*15; // 33 MHz

  parameter COUNT = 32'h10;
  parameter DURATION = 32'h7;
  
  initial begin
    $dumpfile("glitcher.vcd");
    $dumpvars(0, clk);
    $dumpvars(0, clk_pll);
    $dumpvars(0, target_clk_in);
    $dumpvars(0, target_powerdip_out);
    $dumpvars(0, resetn);
    $dumpvars(0, target_trigger_in);
    $dumpvars(0, glitch_status);
    $dumpvars(0, glitch_dbg1);    
    $dumpvars(0, glitch_dbg2);
    // $dumpvars(0, glitch_delay_dv);    
  end
    
  reg resetn = 1;
  reg clk = 0;
  reg clk_pll = 0;
  reg target_clk_in = 0;
  reg target_trigger_in = 0;

  reg [7:0] glitch_ctrl = 8'h0;
  reg glitch_ctrl_dv = 0;    
  reg [31:0] glitch_delay = 32'h0;
  reg glitch_delay_dv = 0;    
  reg [31:0] glitch_duration = 32'h0;
  reg glitch_duration_dv = 0;    
  wire [31:0] glitch_status;
  wire glitch_dbg1,glitch_dbg2;
  

  initial begin
     # MAIN_CLK_DELAY resetn = 1;
     # MAIN_CLK_DELAY resetn = 0;  // reset
     # MAIN_CLK_DELAY resetn = 1;     

     // ########### PULSE #1 ##############

     // set glitch count
     # (MAIN_CLK_DELAY*2) glitch_delay = 32'h10;
     # (MAIN_CLK_DELAY*2) glitch_delay_dv = 1;
     # (MAIN_CLK_DELAY*2) glitch_delay_dv = 0;
     
     // set glitch duration
     # (MAIN_CLK_DELAY*2) glitch_duration = 32'h7;
     # (MAIN_CLK_DELAY*2) glitch_duration_dv = 1;
     # (MAIN_CLK_DELAY*2) glitch_duration_dv = 0;

     // setup (arm) glitcher          
     # (MAIN_CLK_DELAY*2) glitch_ctrl = 8'b0000_0001;
     # (MAIN_CLK_DELAY*2) glitch_ctrl_dv = 1;
     # (MAIN_CLK_DELAY*2) glitch_ctrl_dv = 0;

     # (MAIN_CLK_DELAY*5) /* zZZzZZz */

     // POS TRIGGER   
     # (MAIN_CLK_DELAY*2) target_trigger_in = 0;
     # (MAIN_CLK_DELAY*2) target_trigger_in = 1;
     # (MAIN_CLK_DELAY*2) target_trigger_in = 0;

     // ########### PULSE #2 ##############

     # (MAIN_CLK_DELAY*8) /* zZZzZZz */

    // set glitch count
     # (MAIN_CLK_DELAY*2) glitch_delay = 32'h10;
     # (MAIN_CLK_DELAY*2) glitch_delay_dv = 1;
     # (MAIN_CLK_DELAY*2) glitch_delay_dv = 0;
     
     // set glitch duration
     # (MAIN_CLK_DELAY*2) glitch_duration = 32'h7;
     # (MAIN_CLK_DELAY*2) glitch_duration_dv = 1;
     # (MAIN_CLK_DELAY*2) glitch_duration_dv = 0;

     // setup (arm) glitcher          
     # (MAIN_CLK_DELAY*2) glitch_ctrl = 8'b0000_0001;
     # (MAIN_CLK_DELAY*2) glitch_ctrl_dv = 1;
     # (MAIN_CLK_DELAY*2) glitch_ctrl_dv = 0;

     // POS TRIGGER   
     # (MAIN_CLK_DELAY*2) target_trigger_in = 0;
     # (MAIN_CLK_DELAY*2) target_trigger_in = 1;
     # (MAIN_CLK_DELAY*2) target_trigger_in = 0;  

     // delay until stop of sim     
     # (MAIN_CLK_DELAY*100) $stop;
  end


  /* Make a regular pulsing clock. */

  // Clock Generators:
  always #(MAIN_CLK_DELAY)   clk = !clk;
  always #(TARGET_CLK_DELAY) target_clk_in = !target_clk_in;
  always #(PLL_CLK_DELAY)    clk_pll = !clk_pll;

  glitcher glt1 (
		.i_Rst_L 		  (resetn),    		// SOC Reset
		.i_Clk     		(clk),      		// SOC Clock
		.i_PLL_Clk		(clk_pll),			// PLL'ed clock (FAST)
		.i_target_Clk	(target_clk_in),	// Target clock signal

		.i_target_trigger_in 	(target_trigger_in),
		.o_target_powerdip_out 	(target_powerdip_out),
	
  	.i_glitch_ctrl_DV	  	(glitch_ctrl_dv),
		.i_glitch_ctrl			  (glitch_ctrl),
    .o_glitch_status_DV	  (glitch_status_DV),
	  .o_glitch_status			(glitch_status),
		.i_glitch_delay_DV		(glitch_delay_dv),
		.i_glitch_delay			  (glitch_delay),
		.i_glitch_duration_DV	(glitch_duration_dv),
		.i_glitch_duration		(glitch_duration),
    .o_glitch_debug1      (glitch_dbg1),
    .o_glitch_debug2      (glitch_dbg2)
	);
  
  //initial
    // $monitor("At time %t, value = %h (%0d)", $time, spi_clk, spi_miso);
endmodule // test
