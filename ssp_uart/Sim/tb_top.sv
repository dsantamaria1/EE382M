
/**
 * @brief Testbench Top
 * This is module is the top level testbench for the ssp_uart DUT.
 *
 * This top level module instantiates the top of the HDL  (hdl_top),
 *
 * It runs the This top level module instantiates the DUT (ssp_uart),
 *
 */

`timescale 1 ns / 1 ns

module tb_top ();

  logic clk = 0;
  logic rst = 1;
  logic [2:0] ssp_ra = 0;
  logic ssp_wnr = 0;
  logic [11:0] ssp_di = 12'h0;
  logic [11:0] ssp_do = 12'h0;
  logic ssp_eoc = 0;
  logic ssp_ssel = 0;

  hdl_top     hdl_top_i();

  config_item   c1; 
  virtual ssp_uart_if      ssp_uart_vif ;

 /**
   * @brief initialize the ssp_uart interface
   *
   * @param none
   * @return void
   */


  function void initialize_ssp_uart_if();
       hdl_top_i.get_interface(ssp_uart_vif);
  endfunction


 /**
   * @brief drives the transaction on the hardware
   *
   * @param config_item seq - the item to be driven
   * @return void
   */


  task drive_transaction(config_item  item); 
  //task drive_transaction(logic [2:0] reg_addr, logic [11:0] data, logic WE, logic eoc, logic ssel); 
  
    ssp_uart_vif.SSP_WnR_sig 	= item.get_SSP_WnR();
    ssp_uart_vif.SSP_DI_sig 	= item.get_SSP_DI();
    ssp_uart_vif.SSP_RA_sig 	= item.get_SSP_RA();
    ssp_uart_vif.SSP_SSEL_sig 	= item.get_SSP_SSEL();
    ssp_uart_vif.SSP_EOC_sig 	= item.get_SSP_EOC();

  endtask


  // TB Top Process
  //connected clk to DUT
  always begin
    #10 clk = ~clk;
    ssp_uart_vif.Clk_sig = clk;
    ssp_uart_vif.SSP_SCK_sig = clk;
  end

  initial begin
    $timeformat(-9, 0, " ns", 5); // show time in ns
    initialize_ssp_uart_if();
    #0; //initialize reset to 1 at beginning of simulation
    ssp_uart_vif.Rst_sig = rst;
    #50;
    
    // bring SSP_UART out of reset
    rst = 0;
    ssp_uart_vif.Rst_sig = rst;

    ssp_ra = 'h0;
    ssp_di = 'hDED;
    ssp_wnr = 1'b1;
    ssp_eoc = 1'b1;
    ssp_ssel = 1'b1;
    //drive_transaction(ssp_ra, ssp_di, ssp_wnr, ssp_eoc, ssp_ssel);
    
    // Create a new config_item object and assign to variable c1
    c1 = new(ssp_uart_vif);
    // Set addr to 0 (UCR) and data to 12'hDED for c1
    c1.set_SSP_RA(ssp_ra);
    c1.set_SSP_DI(ssp_di);
    c1.set_SSP_WnR(ssp_wnr);
    c1.set_SSP_SSEL(ssp_ssel);
    c1.set_SSP_EOC(ssp_eoc);

    // Call method print for c1
    c1.print();
    // Call task drive_transaction with config_item c1 as argument
    drive_transaction(c1);
    
    // read data back and compare (need to wait for 2 negedges for register to latch value);
    @(negedge ssp_uart_vif.Clk_sig);
    @(negedge ssp_uart_vif.Clk_sig);
    
    ssp_do = c1.get_SSP_DO();
    if(ssp_do !== ssp_di) begin // using != instead of !== results in true
	$display("ERROR @ time %0t: Data read from UCR is incorrect. Expected = %0h, Actual = %0h", $time, ssp_di, ssp_do);
    end
    else begin
	$display("SUCCESS!: Data read from UCR was correct. Expected = %0h, Actual = %0h", ssp_di, ssp_do);
    end
    #100; 
     
    #100; 

    $finish();

  end

    // Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end

endmodule : tb_top
