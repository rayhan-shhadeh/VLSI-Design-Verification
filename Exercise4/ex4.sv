
interface arb_if (input bit clk); logic [3:0] grant, request;
bit rst;
modport TEST (output request, rst,
	input grant, clk);
modport DUT (input request, rst, clk,
	output grant);
modport MONITOR (input request, grant, rst, clk);
endinterface

/*
module arb_with_port (
output logic [3:0] grant, 
input logic [3:0] request,
input bit rst, clk);
always @(posedge clk or posedge rst) begin
if (rst)
grant <= 2'b00;
else if (request[0])
grant <= 2'b00;
else if (request [1])
grant <= 2'b01;
else if (request [2])
grant <= 2'b10;
else if (request [3])
grant <= 2'b11;
else
grant <= 0;
end
endmodule
*/

module arb_with_ifc (arb_if arbif);
always @(posedge arbif.clk or posedge arbif.rst)
begin
if (arbif.rst)
arbif.grant <= '0;
else if (arbif.request[0])
arbif.grant <= 2'b00;
else if (arbif.request [1])
arbif.grant <= 2'b01;
else if (arbif.request [2])
arbif.grant <= 2'b10;
else if (arbif.request [3])
arbif.grant <= 2'b11;
else
arbif.grant <= '0;
end
endmodule 

module test_with_ifc (arb_if arbif); 
initial begin
@(posedge arbif.clk);
arbif.request <= 2'b01;
$display ("@%0t: Drove req=01", $time); 
repeat (2) @(posedge arbif.clk);
if (arbif.grant != 2'b01)
$display("@%0t: value: grant = %0b", $time,arbif.grant);
$display("@%0t: Error: grant != 2'b01", $time);
$finish;
end
endmodule

module monitor (arb_if.MONITOR arbif);
always @(posedge arbif.request[0]) begin
$display ("@%0t: request[0] asserted", $time); 
@(posedge arbif.grant[0]);
$display("@%0t: grant[0] asserted", $time);
end

always @(posedge arbif.request[1]) begin
 $display("@%0t: request[1] asserted", $time);
 @(posedge arbif.grant[1]);
$display("@%0t: grant[1] asserted", $time);
end

always @(posedge arbif.request[2]) begin
 $display("@%0t: request[2] asserted", $time);
 @(posedge arbif.grant[2]);
$display("@%0t: grant[2] asserted", $time);
end

always @(posedge arbif.request[3]) begin
 $display("@%0t: request[3] asserted", $time);
 @(posedge arbif.grant[3]);
$display("@%0t: grant[3] asserted", $time);
end
endmodule


module top;
bit clk;
always #50 clk = ~clk;
arb_if arbif(clk);
arb_with_ifc a1 (arbif.DUT);
test_with_ifc t1(arbif.TEST);
monitor(arbif.MONITOR);
endmodule : top