
`timescale 1ns/ 1ns
module top();
  semaphore sem; 
        
  initial begin 
    fork begin 
      sem = new (1);
      sem.get(1);
      #45ns;
      sem.put(2);
    end 
      wait10();
    join
  end

   task wait10;
    integer i=0;
    begin 
      for(i=0 ; i <10; i+=1 ) begin
	fork begin

	begin
        #10ns;
	end

	begin
       /* if(sem.try_get(1)) begin
        $display("\n i=%d  time inside if  = %0t \n ",i, $time);
        end
        $display(" time = %0t  ",$time); 
    	 */
#45  $display("@%0t: Error: timeout", $time); end 
	end
join_any
end
end
  endtask;

endmodule;

  
