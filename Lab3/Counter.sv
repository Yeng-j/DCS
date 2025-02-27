module Counter(

    clk,
    rst_n,
    clk2

);

    input clk,rst_n;
    output logic clk2;

    logic [1:0]count;


    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            count<=0;
        else if(count==3)
            count<=0;
        else
            count<=count+1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk2<=1'b0;
        end 
        else if (count<2) begin
            clk2<=1;
        end
        else begin
            clk2<=0;
        end
    end

endmodule