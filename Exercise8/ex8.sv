
module reg_ctrl
# (
parameter ADDR_WIDTH= 8,
parameter DATA_WIDTH=16,
parameter DEPTH=256,


parameter RESET_VAL= 16'h1234
)
  (input clk,
input rstn,
input [ADDR_WIDTH-1:0] addr,
input sel,
input wr,
   input [DATA_WIDTH-1:0] wdata,


  output reg [DATA_WIDTH-1:0] rdata,
output reg ready);
// Some memory element to store data for each addr 
  reg [DATA_WIDTH-1:0] ctrl [DEPTH];
reg ready_dly;
wire ready_pe;
// If reset is asserted, clear the memory element
// Else store data to addr for valid writes
// For reads, provide read data back
always@ (posedge clk) begin
if (!rstn) begin
for (int i = 0; i < DEPTH; i += 1) begin 
  ctrl[i] <= RESET_VAL;
end
end else begin
if (sel & ready & wr) begin
ctrl [addr] <= wdata;
end
if (sel & ready & !wr) begin
rdata <= ctrl [addr];
end else begin
rdata <= 0;
end
end
end
  
  
always@ (posedge clk) begin 
  if (!rstn) begin
ready <= 1; 
  end else begin
if (sel & ready_pe) begin
ready <= 1;
end
    if (sel & ready & !wr) begin
ready <= 0;
end
end
end
// Drive internal signal accordingly 
  always @ (posedge clk) begin
if (!rstn) 
  ready_dly <= 1; 
    else ready_dly <= ready;
end
assign ready_pe =~ready & ready_dly;
  endmodule


class reg_item;
rand bit [7:0] addr;
rand bit [15:0] wdata;
bit [15:0] rdata;
rand bit wr;
function void print(string tag="");
$display ("T=%0t [%s] addr=0x%0h wr=%0d wdata=0x%0h rdata=0x%0h",
$time, tag, addr, wr, wdata, rdata);
endfunction
endclass

//driver
class driver;
virtual reg_if vif;
event drv_done;
mailbox drv_mbx;
task run();
$display ("T=%0t [Driver] starting ...", $time);
@ (posedge vif.clk);
forever begin
reg_item item;
$display ("T=%0t [Driver] waiting for item ...", $time);
drv_mbx.get(item);
item.print("Driver");
vif.sel <= 1; vif.addr <= item.addr; vif.wr <= item.wr; vif.wdata <= item.wdata;
@ (posedge vif.clk);
while (!vif.ready) begin
$display ("T=%0t [Driver] wait until ready is high", $time);
@(posedge vif.clk);
end
vif.sel <= 0;
->drv_done;
end
endtask
endclass

// integer 10

class TestRegistry;
    static int NoOfTransactions = 10;
	static function int getvalue();
		return NoOfTransactions;
	endfunction
endclass

// gen class
class generator;
    mailbox drv_mbx;
	TestRegistry testr0 = new;
    task run();
        reg_item item;
        $display("T=%0t [Generator] Starting stimulus with %0d transactions ...", $time, testr0.getvalue() );
        for (int i = 0; i < testr0.getvalue() ; i++) begin
            item = new;
            item.randomize() with { addr == 8'haa; wr == 1; };
            drv_mbx.put(item);
        end
    endtask
endclass



//monitor
class monitor;
virtual reg_if vif;
mailbox scb_mbx;
task run();
$display ("T=%0t [Monitor] starting ...", $time);
forever begin
@ (posedge vif.clk);
if (vif.sel) begin
reg_item item = new;
item.addr = vif.addr; item.wr = vif.wr; item.wdata = vif.wdata;
if (!vif.wr) begin
@(posedge vif.clk);
item.rdata = vif.rdata;
end
item.print("Monitor");
scb_mbx.put(item);
end
end
endtask
endclass

class scoreboard;
mailbox scb_mbx;
reg_item refq[256];
task run();
forever begin
reg_item item;
scb_mbx.get(item);
item.print("Scoreboard");
if (item.wr) begin
// if (refq[item.addr] == null)
// refq[item.addr] = new;
refq[item.addr] = item;
$display ("T=%0t [Scoreboard] Store addr=0x%0h wr=0x%0h data=0x%0h",
$time, item.addr, item.wr, item.wdata);
end
if (!item.wr) begin
if (refq[item.addr] == null)
if (item.rdata != 'h1234)
$display ("T=%0t [Scoreboard] ERROR! First time read, addr=0x%0h exp=1234 act=0x%0h", $time, item.addr, item.rdata);
else
$display ("T=%0t [Scoreboard] PASS! First time read, addr=0x%0h exp=1234 act=0x%0h", $time, item.addr, item.rdata);
else
if (item.rdata != refq[item.addr].wdata)
$display ("T=%0t [Scoreboard] ERROR! addr=0x%0h exp=0x%0h act=0x%0h", $time, item.addr, refq[item.addr].wdata, item.rdata);
else
$display ("T=%0t [Scoreboard] PASS! addr=0x%0h exp=0x%0h act=0x%0h", $time, item.addr, refq[item.addr].wdata, item.rdata);
end
end
endtask
endclass

class env;
driver d0; // Driver to design
monitor m0; // Monitor from design
generator gen0; //
scoreboard s0; // Scoreboard connected to monitor
mailbox scb_mbx; // Top level mailbox for SCB <-> MON
virtual reg_if vif; // Virtual interface handle
// Instantiate all testbench components
function new();
d0 = new;
m0 = new;
s0 = new;
gen0=new;
scb_mbx = new();
endfunction
  virtual task run();
d0.vif = vif;
m0.vif = vif;
m0.scb_mbx = scb_mbx;
s0.scb_mbx = scb_mbx;
gen0.drv_mbx=scb_mbx;
fork
s0.run();
d0.run();
m0.run();
gen0.run();
join_any
endtask
endclass

class test;
    env e0;
    mailbox drv_mbx;

    function new();
        drv_mbx = new();
        e0 = new();
    endfunction

    virtual task run();
        e0.d0.drv_mbx = drv_mbx;
        fork
            e0.run();
        join_none
    endtask
endclass


interface reg_if (input bit clk);
logic rstn;
logic [7:0] addr;
logic [15:0] wdata;
logic [15:0] rdata;
logic wr;
logic sel;
logic ready;
endinterface

module tb;
    reg clk;
    always #10 clk = ~clk;
    reg_if _if (clk);
    reg_ctrl u0 ( .clk (clk),
                  .addr (_if.addr),
                  .rstn(_if.rstn),
                  .sel (_if.sel),
                  .wr  (_if.wr),
                  .wdata (_if.wdata),
                  .rdata (_if.rdata),
                  .ready (_if.ready));

    initial begin
        test t0;
        clk <= 0;
        _if.rstn <= 0;
        _if.sel <= 0;
        #20 _if.rstn <= 1;
        t0 = new;
        t0.e0.vif = _if;
        t0.run();
        #200 $finish;
    end

    initial begin
        $dumpvars;
        $dumpfile("dump.vcd");
    end
endmodule
