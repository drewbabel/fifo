// Sync FIFO harness
module tt_sync_fifo (
    input  logic clk,
    input  logic rst_n,
    input  logic si,
    output logic so
);
  localparam int NIN = 10;
  localparam int NOUT = 10;

  logic [NIN-1:0] in_r;
  logic [NOUT-1:0] out_w, out_r;

  always_ff @(posedge clk) in_r <= {in_r[NIN-2:0], si};

  sync_fifo dut (
      .clk    (clk),
      .rst_n  (rst_n),
      .wr_en  (in_r[0]),
      .rd_en  (in_r[1]),
      .wr_data(in_r[9:2]),
      .rd_data(out_w[7:0]),
      .full   (out_w[8]),
      .empty  (out_w[9])
  );

  always_ff @(posedge clk) out_r <= out_w;
  always_ff @(posedge clk) so <= ^out_r;
endmodule
