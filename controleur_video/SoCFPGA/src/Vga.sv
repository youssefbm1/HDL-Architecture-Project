module vga #(
    parameter HDISP = 800,
    parameter VDISP = 480
) (
    input pixel_clk,  
    input pixel_rst,  
    video_if.master video_ifm,
    wshb_if.master wshb_ifm
);

  // Time Parameters 
  localparam HFP = 40;  
  localparam HPULSE = 48;  
  localparam VFP = 13;  
  localparam VPULSE = 3;  
  localparam VBP = 29;
  localparam HBP = 40;  

  localparam HW = HDISP + HFP + HPULSE + HBP;
  localparam VW = VDISP + VFP + VPULSE + VBP;

  logic BLANK_aux, pixelCpt_aux;

  logic [$clog2(HW) - 1:0] pixelCpt;
  logic [$clog2(VW) - 1:0] lineCpt;

  always_ff @(posedge pixel_clk) begin
    if (pixel_rst || pixelCpt_aux) begin
      pixelCpt <= 0;
    end else begin
      pixelCpt <= pixelCpt + 1;
    end
  end

  always_ff @(posedge pixel_clk) begin
    if (pixel_rst || lineCpt == VW) begin
      lineCpt <= 0;
    end else begin
      lineCpt <= lineCpt + pixelCpt_aux;
    end
  end

  always_ff @(posedge pixel_clk) begin
    video_ifm.HS <= !(pixelCpt >= HFP && pixelCpt < HFP + HPULSE);
    video_ifm.VS <= !(lineCpt >= VFP && lineCpt < VFP + VPULSE);
    video_ifm.BLANK <= BLANK_aux;
  end

  assign video_ifm.CLK = pixel_clk;
  assign pixelCpt_aux = pixelCpt == HW - 1;
  assign BLANK_aux = ((pixelCpt >= (HW - HDISP)) && (lineCpt >= (VW - VDISP)));

  assign wshb_ifm.dat_ms = 32'hBABECAFE;  
  assign wshb_ifm.cyc = 1'b1;  
  assign wshb_ifm.sel = 4'b1111;  
  assign wshb_ifm.we = 1'b0;  
  assign wshb_ifm.cti = '0;  
  assign wshb_ifm.bte = '0; 

  logic read, rempty, write, wfull, walmost_full, fifoFull;
  logic [31:0] rdata, wdata;

  async_fifo #(
      .DATA_WIDTH(32),
      .DEPTH_WIDTH($clog2(256)),
      .ALMOST_FULL_THRESHOLD(255)
  ) myFIFO (
      .rst(wshb_ifm.rst),
      .rclk(pixel_clk),
      .read(read),
      .rdata(rdata),
      .rempty(rempty),
      .wclk(wshb_ifm.clk),
      .wdata(wdata),
      .write(write),
      .wfull(wfull),
      .walmost_full(walmost_full)
  );
  assign write = wshb_ifm.ack;
  assign wdata = wshb_ifm.dat_sm;

  always_ff @(posedge wshb_ifm.clk) begin
    if (wshb_ifm.rst) begin
      wshb_ifm.adr <= 0;
    end else if (wshb_ifm.ack) begin
      if (wshb_ifm.adr == 4 * (VDISP * HDISP - 1)) begin
        wshb_ifm.adr <= 0;
      end else begin
        wshb_ifm.adr <= wshb_ifm.adr + 4;
      end
    end
  end
  assign wshb_ifm.stb = !wfull; 

  always_ff @(posedge pixel_clk) begin
    if (pixel_rst) begin
      fifoFull <= 0;
    end else begin
      read <= (video_ifm.BLANK && !rempty && fifoFull);
      if (wfull && !(video_ifm.VS && video_ifm.HS)) begin
        fifoFull <= 1;
      end else begin
        fifoFull <= fifoFull;
      end
      if (BLANK_aux) begin
        video_ifm.RGB <= rdata[23:0];
      end
    end
  end
endmodule