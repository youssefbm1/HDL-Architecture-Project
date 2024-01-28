module vga #(
    parameter HDISP = 800,
    parameter VDISP = 480
) (
    input pixel_clk,  
    input pixel_rst,  
    video_if.master video_ifm 
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
    if (BLANK_aux) begin
      video_ifm.RGB <= ((pixelCpt - (HW - HDISP)) % 16) && ((lineCpt - (VW - VDISP)) % 16) ? 24'h000000 : 24'hFFFFFF;
    end
  end

  assign video_ifm.CLK = pixel_clk;
  assign pixelCpt_aux = pixelCpt == HW - 1;
  assign BLANK_aux = ((pixelCpt >= (HW - HDISP)) && (lineCpt >= (VW - VDISP)));
endmodule