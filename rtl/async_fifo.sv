module async_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16,
    localparam int AW = $clog2(DEPTH)
) (
    // Write
    input  logic             wr_clk,
    input  logic             wr_rst_n,
    input  logic             wr_en,
    input  logic [WIDTH-1:0] wr_data,
    output logic             full,

    // Read
    input  logic             rd_clk,
    input  logic             rd_rst_n,
    input  logic             rd_en,
    output logic [WIDTH-1:0] rd_data,
    output logic             empty
);

  logic [  AW:0] wr_gray;
  logic [  AW:0] rd_gray;
  logic [  AW:0] wr_gray_sync;
  logic [  AW:0] rd_gray_sync;
  logic [AW-1:0] wr_addr;
  logic [AW-1:0] rd_addr;

  // Synchronizer for write pointer to read clock domain
  synchronizer #(
      .WIDTH(AW + 1)
  ) u_rd_gray_sync (
      .clk(wr_clk),
      .d  (rd_gray),
      .q  (rd_gray_sync)
  );

  // Synchronizer for read pointer to write clock domain
  synchronizer #(
      .WIDTH(AW + 1)
  ) u_wr_gray_sync (
      .clk(rd_clk),
      .d  (wr_gray),
      .q  (wr_gray_sync)
  );

  // Write pointer and full flag
  wptr_full #(
      .DEPTH(DEPTH)
  ) u_wptr_full (
      .wr_clk(wr_clk),
      .wr_rst_n(wr_rst_n),
      .wr_en(wr_en),
      .rd_gray_sync(rd_gray_sync),
      .full(full),
      .wr_addr(wr_addr),
      .wr_gray(wr_gray)
  );

  // Read pointer and empty flag
  rptr_empty #(
      .DEPTH(DEPTH)
  ) u_rptr_empty (
      .rd_clk(rd_clk),
      .rd_rst_n(rd_rst_n),
      .rd_en(rd_en),
      .wr_gray_sync(wr_gray_sync),
      .empty(empty),
      .rd_addr(rd_addr),
      .rd_gray(rd_gray)
  );

  // FIFO memory
  fifomem #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) u_fifomem (
      .wr_clk(wr_clk),
      .wr_en(wr_en),
      .full(full),
      .wr_addr(wr_addr),
      .wr_data(wr_data),
      .rd_clk(rd_clk),
      .rd_en(rd_en),
      .empty(empty),
      .rd_addr(rd_addr),
      .rd_data(rd_data)
  );

endmodule
