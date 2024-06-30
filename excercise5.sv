class Excercise1;
rand bit [7:0] data;
rand bit [3:0] address;
  constraint address_length{address>=3;
			address <=4;}
endclass

class Excercise2 extends Excercise1;
rand bit [7:0] data;
rand bit [3:0] address;
  static int ten_c =0;
  static int eighten_c =0;
  static int ten2_c =0;
  constraint data_length{data == 5;}
  constraint address_length{
    address dist{
      4'd0 :=10,
      [4'd1:4'd14]  :=80,
      4'd15 :=10
    };
  }
  function void post_randomize();
              if(p.address== 4'd0)
      		 begin
               ten_c ++;
        	 end
          else if(p.address>= 4'd1||p.address<= 4'd14)
      		 begin
               eighten_c ++;
        	 end
          else if(p.address== 4'd15)
      		 begin
               ten2_c ++;
        	 end
  endfunction
endclass


module top;
initial begin
   int err_c =0;

	Excercise2 p = new();
	p.randomize();
  	
    $display("p.address = %0d , p.data= %0d ", p.address, p.data);
  	for( int i = 0 ; i<100 ; i++) begin
    	if(!p.randomize())
      		 begin
               err_c ++;
        	 end
        else begin

    $display("p.address = %0d , p.data= %0d ", p.address, p.data);
          
        end
    
  	end
  if(err_c>0)
      		 begin
               $display("error count =%0d ",err_c);
        	 end
        else begin
          $display("everything is OK  ");
        end
 
  final begin
    $display("count at address 0 = %0d" , p.ten_c);
    
    $display("count at address 1-14 = %0d" , p.eighten_c);
    
    $display("count at address 15 = %0d" , p.ten2_c);
  end
endmodule
  