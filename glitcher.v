///////////////////////////////////////////////////////////////////////////////
// Description: Glitcher Peripherial
// (c) Georg Swoboda 2021
///////////////////////////////////////////////////////////////////////////////

module glitcher
  (
    // Control/Data Signals,
    input            i_Rst_L,       // FPGA Reset
    input            i_Clk,         // FPGA Clock
    input            i_PLL_Clk,     // PLL'ed FPGA Clocked (fast)
    input            i_target_Clk,  // DUT clock (which is counted)

    input            i_target_trigger_in,    // start the counter
    output reg       o_target_powerdip_out,   // output trigger signal when counter is reached

    input            i_glitch_ctrl_DV,    
    input  [7:0]     i_glitch_ctrl,    // control register

    input             o_glitch_status_DV,    
    output reg [31:0] o_glitch_status,  // status register    

    input            i_glitch_delay_DV,    
    input  [31:0]    i_glitch_delay,   // the counter value (target_clk_in) since reset released when we trigger the glitch
    input            i_glitch_duration_DV,
    input  [31:0]    i_glitch_duration, // the duration of the glitch in (clk_ppl) 
    output           o_glitch_debug1,
    output           o_glitch_debug2
   );


  assign o_glitch_debug1 = w_start_counter; 
  assign o_glitch_debug2 = w_pulse_fired_rise;

  assign w_start_counter = w_PLL_glitch_ctrl_arm & ( (r_glitch_ctrl_pos_trigger & w_PLL_target_trigger_in_rise) | (!r_glitch_ctrl_pos_trigger & w_PLL_target_trigger_in_fall)); /* start counter on falling or raising edge of trigger if its armed */
  
  wire debug;
  wire w_pulse_fired;  
  wire w_start_counter;

  reg [31:0] glitch_status;
  reg [31:0] glitch_delay;
  reg [31:0] glitch_duration;  
  reg [31:0] r_PLL_delay;
  reg [31:0] r_PLL_duration;
  reg r_PLL_glitch_ctrl_arm;
  reg r_glitch_ctrl_arm;    
  reg r_glitch_ctrl_pos_trigger;  
  reg r_PLL_run_delay;
  reg r_PLL_run_duration;
  reg r_PLL_pulse_fired;

    
  /* i_target_trigger_in sampled in i_PLL_Clk domain */
  reg [2:0] TRIG;  always @(posedge i_PLL_Clk) TRIG <= {TRIG[1:0], i_target_trigger_in}; 
  wire w_PLL_target_trigger_in_rise = (TRIG[2:1]==2'b01);   
  wire w_PLL_target_trigger_in_fall = (TRIG[2:1]==2'b10);  
  
     
  /* pulse from pulse fired signal */
  reg [2:0] PULSEFIRED;  always @(posedge i_Clk) PULSEFIRED <= {PULSEFIRED[1:0], w_pulse_fired}; 
  wire w_pulse_fired_rise = (PULSEFIRED[2:1]==2'b01);   

 /*
 ** Cross Domain Signals
 */

  Signal_CrossDomain X_pulse_fired (
    .clkA           (i_PLL_Clk),   // we actually don't need clkA in that example, but it is here for completeness as we'll need it in further examples
    .SignalIn_clkA  (r_PLL_pulse_fired),
    .clkB           (i_Clk),
    .SignalOut_clkB (w_pulse_fired)  
	);

  Signal_CrossDomain X_arm (
    .clkA           (i_Clk),   // we actually don't need clkA in that example, but it is here for completeness as we'll need it in further examples
    .SignalIn_clkA  (r_glitch_ctrl_arm),
    .clkB           (i_PLL_Clk),
    .SignalOut_clkB (w_PLL_glitch_ctrl_arm)  
	);

/*
** COUNT and DURATION (i_PLL_Clk Domain)
*/
always @(posedge i_PLL_Clk)
begin         
  if (!i_Rst_L)
    begin
      r_PLL_delay <=0;
      r_PLL_duration <=0;      
      r_PLL_pulse_fired <= 0;    
      r_PLL_run_delay <= 0;
      r_PLL_run_duration <= 0;
      o_target_powerdip_out <= 0;
    end
  else
    begin
      if (w_start_counter)
        begin
          r_PLL_run_delay <= 1;                    
          r_PLL_pulse_fired <=0;
        end
      else
        begin

          if (r_PLL_run_delay)   // increase counter (delay)
            begin
              r_PLL_delay <= r_PLL_delay+1;     
            end
          
          if (r_PLL_run_duration) // increase duration counter
            begin
              r_PLL_duration <= r_PLL_duration+1;     
            end

          if (r_PLL_run_delay && (r_PLL_delay == glitch_delay)) // end of counter reached
            begin     
              r_PLL_run_delay <= 0;              
              r_PLL_run_duration <= 1;     
              o_target_powerdip_out <= 1;  
              r_PLL_delay <=0;
            end      

          if (r_PLL_run_duration && (r_PLL_duration == glitch_duration)) // end of duration reached
            begin
              r_PLL_run_duration <= 0;           
              o_target_powerdip_out <= 0;
              r_PLL_pulse_fired <=1;
              r_PLL_duration <=0;
            end
        end
    end
end

/*
** Register Handling (i_Clk Domain)
*/
always @(posedge i_Clk or negedge i_Rst_L)
begin
  if (!i_Rst_L)
    begin                 
      glitch_duration <= 0;
      glitch_delay <= 0;
      r_glitch_ctrl_arm <= 0;
      r_glitch_ctrl_pos_trigger <= 0;        
    end
  else
    begin      
      if (w_pulse_fired_rise)         // reset r_glitch_ctrl_arm
          r_glitch_ctrl_arm <= 0;

      if (i_glitch_ctrl_DV)
        begin        
          r_glitch_ctrl_arm <= i_glitch_ctrl[0];        
          r_glitch_ctrl_pos_trigger <= i_glitch_ctrl[1];               
        end 
      if (i_glitch_delay_DV)
        begin
            glitch_delay <= i_glitch_delay;       
        end 
      if (i_glitch_duration_DV)
        begin
          glitch_duration <= i_glitch_duration;                
        end 
      if (o_glitch_status_DV)
        begin 
          o_glitch_status[0] <= r_glitch_ctrl_arm;
          o_glitch_status[1] <= r_glitch_ctrl_pos_trigger;
          o_glitch_status[7] <= w_pulse_fired;
        end
    end   
    
end

endmodule // glitcher
