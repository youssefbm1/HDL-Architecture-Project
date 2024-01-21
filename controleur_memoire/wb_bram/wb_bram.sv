//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------
//
// Le paramètre mem_adr_width doit permettre de déterminer le nombre 
// de mots de la mémoire : (2048 pour mem_adr_width=11)

module wb_bram #(
    parameter mem_adr_width = 11
) (
    // Interface Wishbone
    wshb_if.slave wb_s
);

  // Déclaration des signaux logiques
  logic ack_write, ack_read, ack_read_assync, adress_counter = 0;
  logic [7:0][mem_adr_width-1:0] memory[0:(1<<mem_adr_width)-1];
  wire [mem_adr_width-1:0] address_input;

  assign address_input = wb_s.adr[mem_adr_width+1:2] + adress_counter;

  // Initialisation des signaux d'erreur et de rety
  assign wb_s.err = 0;
  assign wb_s.rty = 0;

  // Gestion du signal ACK pour l'écriture
  assign ack_write = wb_s.we & wb_s.stb;

  // Gestion du signal ACK pour la lecture
  assign ack_read_assync = !wb_s.we & wb_s.stb;
  assign wb_s.ack = ack_write | ack_read;

  // Bloc always_ff pour la synchronisation des signaux
always_ff @(posedge wb_s.clk) begin
    // Logique de réinitialisation
    if (wb_s.rst || ack_read_assync) begin
        ack_read <= !wb_s.rst;
    end

    // Logique de lecture
    if (ack_read_assync) begin
        // Cycle de bus classique
        if (!(wb_s.cti[2] || wb_s.cti[1])) begin // cti = '000'
          adress_counter <= 0;
          ack_read <= !ack_read;
        end
      else if (wb_s.cti[1]) begin 
        adress_counter <= 1;
      end else begin 
        adress_counter <= 0;
      end
      wb_s.dat_sm <= memory[address_input];
    end

    // Logique d'écriture
    if (ack_write) begin
      for (int i = 0; i < 4; i++) begin
        if (wb_s.sel[i]) begin
          memory[address_input][i] <= wb_s.dat_ms[(8*i+7)-:8];
        end
      end
    end
  end

endmodule
