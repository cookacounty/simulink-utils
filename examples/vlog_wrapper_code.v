// An example file of a multiplier

`define MULT_SIZE 10


module multiplier(

   input [`MULT_SIZE:1] a;
   input [`MULT_SIZE:1] b;
   output reg [20:1] out;
)

always @(*) begin
   out = a*b;
end

endmodule
