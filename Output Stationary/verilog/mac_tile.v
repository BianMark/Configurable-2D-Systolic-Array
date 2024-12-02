// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, WeightOrOutput, OS_out, IFIFO_loop, OS_out_valid);

parameter bw = 4;
parameter psum_bw = 16;
parameter acc_kij = 9;


input  [bw-1:0] in_w;
input  [1:0] inst_w;//[1]:execute,[0]kernel loading
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;
input  WeightOrOutput;


output [1:0] inst_e;
output [bw-1:0] out_e;
output [psum_bw-1:0] out_s;
output IFIFO_loop; // high if psum finish 9 times accumulation, IFIFO need to loop the weight
output [psum_bw-1:0] OS_out; // psum value to be read out to ofifo in Output Stationary mode

wire [psum_bw-1:0] mac_out;
reg [bw-1:0] b_q; // buffer for west to east
reg [bw-1:0] a_q; // buffer for north to south
reg [psum_bw-1:0] c_q;
reg [1:0] inst_q; // buffer for west to east instruction
reg load_ready_q; // only active after reset, once receive new weight from west, become 0

reg [3:0] acc_counter;  // counter for accumulation in Output Stationary, when it reaches 9, it will be reset to 0
reg IFIFO_loop_q;
reg [psum_bw-1:0] OS_tile0; //store the psum of tile0
reg [psum_bw-1:0] OS_tile1; //store the psum of tile1
reg [3:0] tile0_ic_counter;
reg [3:0] tile1_ic_counter;
reg choose_tile;
reg tile0_out_valid;  // High if tile0 finished 8 input channels accumulation
reg tile1_out_valid;  // High if tile1 finished 8 input channels accumulation
wire OS_out_valid = tile0_out_valid | tile1_out_valid;

assign out_s = WeightOrOutput ? b_q : mac_out;
assign out_e = a_q;
assign inst_e = inst_q;
assign IFIFO_loop = IFIFO_loop_q;
assign OS_out = (tile0_out_valid * OS_tile0) + (tile1_out_valid * OS_tile1);


always @(posedge clk) begin

 if (reset) begin
    inst_q[1:0] <= 2'b00;
    load_ready_q <= 1;
    a_q <= 0;
    b_q <= 0;
    c_q <= 0;
    acc_counter <= 0;
    choose_tile <= 0;
    tile0_ic_counter <= 0;
    tile1_ic_counter <= 0;
    tile0_out_valid <= 0;
    tile1_out_valid <= 0;
 end


 case(WeightOrOutput)
 0: // Weight Stationary
 begin
    inst_q[1] <= inst_w[1];
    c_q <= in_n;
    if (inst_w[1:0] != 2'b00) begin
      a_q <= in_w;
    end
    if (inst_w[0] && load_ready_q) begin
      b_q <= in_w;
      load_ready_q <= 0;
    end
    if (!load_ready_q) begin
      inst_q[0] <= inst_w[0];
    end
  end

  1:  // Output Stationary
  begin
    inst_q[1] <= inst_w[1];
    if (inst_w[1]) begin
      b_q <= in_n;  // pass the weight from north to south
      a_q <= in_w;  // pass the activation from west to east

      if (acc_counter != acc_kij) begin  // execution stage
        acc_counter <= acc_counter + 1; // increment the accumulation counter
        IFIFO_loop_q <= 0; // disable the output
        c_q <= mac_out;
        if (tile0_ic_counter == 8) begin
          tile0_out_valid <= 1;
        end
        else if (tile1_ic_counter == 8) begin
          tile1_out_valid <= 1;
        end
        else begin
          tile0_out_valid <= 0;
          tile1_out_valid <= 0;
        end
      end

      if (acc_counter == acc_kij) begin // 9 times accumulation finished
      acc_counter <= 0;
      IFIFO_loop_q <= 1; // enable the output
      choose_tile <= ~choose_tile; // switch the reg to store different tile's psum
      case(choose_tile)
        0: begin
          tile0_ic_counter <= tile0_ic_counter + 1;
          OS_tile0 <= mac_out > 0 ? mac_out : 0; // ReLU
          c_q <= OS_tile1;  // current choose_time is 0, so next execution will use the psum of tile1 to accumulate different input channels
        end
        1: begin
          tile1_ic_counter <= tile1_ic_counter + 1;
          OS_tile1 <= mac_out > 0 ? mac_out : 0; // ReLU
          c_q <= OS_tile0;
        end
      endcase
      end
    end
  end
 endcase
end

// always @ (negedge clk) begin
//   if (WeightOrOutput && (acc_counter == acc_kij)) begin // 9 times accumulation finished
//     acc_counter <= 0;
//     IFIFO_loop_q <= 1; // enable the output
//     choose_tile <= ~choose_tile; // switch the reg to store different tile's psum
//     case(choose_tile)
//       0: begin
//         tile0_ic_counter <= tile0_ic_counter + 1;
//         OS_tile0 <= mac_out;
//         c_q <= OS_tile1;  // current choose_time is 0, so next execution will use the psum of tile1 to accumulate different input channels
//       end
//       1: begin
//         tile1_ic_counter <= tile1_ic_counter + 1;
//         OS_tile1 <= mac_out;
//         c_q <= OS_tile0;
//       end
//     endcase
//   end
// end

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q),  // activation
    .b(b_q),  // weight
    .c(c_q),  // psum
    .out(mac_out) // act*weight + psum
    );


endmodule
