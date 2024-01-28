`timescale 1ns/1ps

`default_nettype none

module tb_Top;

// Entrées sorties extérieures
bit   FPGA_CLK1_50;
logic [1:0]	KEY;
wire  [7:0]	LED;
logic [3:0]	SW;

// Interface vers le support matériel
hws_if      hws_ifm();

///////////////////////////////
//  Code élèves
//////////////////////////////

  always #10ns FPGA_CLK1_50 = ~FPGA_CLK1_50;

  `define SIMULATION

  initial begin
    KEY[0] = 1;
    #128ns KEY[0] = 0;
    #128ns KEY[0] = 1;
    #5ms $stop();
  end

  
  video_if video_if0 ();
  Top #(
      .HDISP(160),
      .VDISP(90)
  ) myTop (
      .FPGA_CLK1_50(FPGA_CLK1_50),
      .KEY(KEY),
      .LED(LED),
      .SW(SW),
      .hws_ifm(hws_ifm),
      .video_ifm(video_if0)
  );

  screen #(.mode(13),.X(160),.Y(90)) screen0 (.video_ifs(video_if0));

endmodule
