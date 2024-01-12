module MEDIAN #(parameter WIDTH = 8)
               (input [WIDTH-1:0] DI,
                input DSI, nRST, CLK,
                output [WIDTH-1:0] DO,
                output logic DSO);
    logic BYP;
    logic [3:0] counter, state;  
    localparam state0 = 4'd0, state1 = 4'd1, state2 = 4'd2, state3 = 4'd3,
    state4 = 4'd4, state5 = 4'd5, state6 = 4'd6;

    MED #(.WIDTH(WIDTH))
    myMED(.DI(DI), .DSI(DSI), .CLK(CLK), .BYP(BYP), .DO(DO));

    always_ff @(posedge CLK)
      if(!nRST)
        state   <= 0;
      else
      begin
        if(state == state0) begin
          if(DSI) state <=  state1;
        end
        else if(state == state1) begin
          if(!DSI) state <=  state2;
        end
        else if(state == state6 && counter == 4'd4) begin
          state <= (DSI) ? state1 : state0;
        end
        else if(counter == 4'd8) begin
          state <= state + 1;
        end
      end

    always_ff @(posedge CLK)
      if(!nRST)
        counter <= 0;
      else
      begin
        if(state == state0 || state == state1)
          counter <= 0;
        else if(counter == 4'd8)
          counter <= 0;
        else
          counter <= counter + 1;
      end

    always_comb
    begin
        DSO = (state == state6 && counter == 4'd4);
        BYP = (state == state5 && counter > 4'd4)
           || (state == state4 && counter > 4'd5)
           || (state == state3 && counter > 4'd6)
           || (state == state2 && counter > 4'd7)
           || DSI;
    end
endmodule
