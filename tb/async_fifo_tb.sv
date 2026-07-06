module async_fifo_tb ();

  int checks = 0;
  int errors = 0;

  localparam int Width = 8;
  localparam int Depth = 16;

  localparam int WrClkPeriod = 10;
  localparam int RdClkPeriod = 14;

  logic wr_clk = 1'b0;
  logic wr_rst_n = 1'b1;
  logic wr_en = 1'b0;
  logic [Width-1:0] wr_data;
  logic full;

  logic rd_clk = 1'b0;
  logic rd_rst_n = 1'b1;
  logic rd_en = 1'b0;
  logic [Width-1:0] rd_data;
  logic empty;

  logic [Width-1:0] byte_q[$];
  logic exp_full;
  logic exp_empty;
  int iterations;

  always #(WrClkPeriod / 2) wr_clk = ~wr_clk;
  always #(RdClkPeriod / 2) rd_clk = ~rd_clk;

  async_fifo #(
      .WIDTH(Width),
      .DEPTH(Depth)
  ) u_async_fifo (
      .wr_clk(wr_clk),
      .wr_rst_n(wr_rst_n),
      .wr_en(wr_en),
      .wr_data(wr_data),
      .full(full),

      .rd_clk(rd_clk),
      .rd_rst_n(rd_rst_n),
      .rd_en(rd_en),
      .rd_data(rd_data),
      .empty(empty)
  );

  task automatic wr_reset();
    wr_rst_n = 1'b0;
    repeat (2) @(posedge wr_clk);
    wr_rst_n = 1'b1;
  endtask  //automatic

  task automatic rd_reset();
    rd_rst_n = 1'b0;
    repeat (2) @(posedge rd_clk);
    rd_rst_n = 1'b1;
  endtask  //automatic

  task automatic do_verdict();
    int check_cnt;
    wait (wr_clk && rd_clk);
    check_cnt = iterations / 4;
    if (errors == 0 && checks >= check_cnt) begin
      $display("PASSED: %0d checks, %0d errors", checks, errors);
    end else begin
      $display("FAILED: %0d checks, %0d errors (need >=%0d checks)", checks, errors, check_cnt);
    end
    $finish;
  endtask  //automatic

  task automatic do_reset();
    fork
      wr_reset();
      rd_reset();
    join
  endtask  //automatic

  task automatic write_data(input logic [Width-1:0] data);
    @(posedge wr_clk);
    if (!full) begin
      #1 wr_en = 1'b1;
      wr_data = data;
      byte_q.push_back(data);
      @(posedge wr_clk);
      #1 wr_en = 1'b0;
    end
  endtask  //automatic

  task automatic read_data();
    logic [Width-1:0] got;
    logic [Width-1:0] exp;

    @(posedge rd_clk);
    if (!empty) begin
      #1 rd_en = 1'b1;
      @(posedge rd_clk);
      #1 got = rd_data;
      exp = byte_q.pop_front();
      #1 rd_en = 1'b0;

      checks++;
      if (got !== exp) begin
        errors++;
        $error("t=%0t data mismatch: got=%b exp=%b", $time, got, exp);
      end
    end
  endtask  //automatic

  task automatic stall_read(input int stall_percent);
    if ($urandom_range(0, 100) > stall_percent) begin
      read_data();
    end
  endtask  //automatic

  initial begin
    $dumpfile("async_fifo_tb.vcd");
    $dumpvars(0, async_fifo_tb);
    do_reset();

    iterations = 50000;

    fork
      begin
        repeat (iterations) write_data((Width)'($urandom));
      end
      begin
        repeat (iterations) stall_read(25);
      end
    join

    do_verdict();
  end

  // Watchdog
  initial begin
    #200_000_000 $fatal(1, "TIMEOUT: sim exceeded max time");
  end

endmodule
