module main (
  //input                clk,
  input  wire          pll_ref_clk,          //        pll_ref_clk.clk,                  PLL reference clock input
  input  wire          oct_rzqin,            //                oct.oct_rzqin,            Calibrated On-Chip Termination (OCT) RZQ input pin
  output wire [0:0]    mem_ck,               //                mem.mem_ck,               CK clock
  output wire [0:0]    mem_ck_n,             //                   .mem_ck_n,             CK clock (negative leg)
  output wire [16:0]   mem_a,                //                   .mem_a,                Address
  output wire [0:0]    mem_act_n,            //                   .mem_act_n,            Activation command
  output wire [1:0]    mem_ba,               //                   .mem_ba,               Bank address
  output wire [0:0]    mem_bg,               //                   .mem_bg,               Bank group
  output wire [0:0]    mem_cke,              //                   .mem_cke,              Clock enable
  output wire [0:0]    mem_cs_n,             //                   .mem_cs_n,             Chip select
  output wire [0:0]    mem_odt,              //                   .mem_odt,              On-die termination
  output wire [0:0]    mem_reset_n,          //                   .mem_reset_n,          Asynchronous reset
  output wire [0:0]    mem_par,              //                   .mem_par,              Command and address parity
  input  wire [0:0]    mem_alert_n,          //                   .mem_alert_n,          Alert flag
  inout  wire [1:0]    mem_dqs,              //                   .mem_dqs,              Data strobe
  inout  wire [1:0]    mem_dqs_n,            //                   .mem_dqs_n,            Data strobe (negative leg)
  inout  wire [15:0]   mem_dq,               //                   .mem_dq,               Read/write data
  inout  wire [1:0]    mem_dbi_n,            //                   .mem_dbi_n,            Acts as either the data bus inversion pin, or the data mask pin, depending on configuration.
  output wire          local_cal_success,    //             status.local_cal_success,    When high, indicates that PHY calibration was successful
  output wire          local_cal_fail     //                   .local_cal_fail,       When high, indicates that PHY calibration failed
  
  );

  // Wires and Internal Registers
  wire           calbus_clk;
  wire           calbus_read;
  wire           calbus_write;
  //logic [2:0]    source;
  wire  [127:0]  x;
  //reg   [7:0]    address=0;

  wire  [19:0]   calbus_address;
  wire  [31:0]   calbus_wdata, calbus_rdata;
  wire  [4095:0] calbus_param;

  wire  [31:0]   avm_address;
  wire  [31:0]   avm_burstcount;
  wire           avm_read;
  wire  [127:0]  avm_readdata;
  wire  [15:0]   avm_byteenable;
  wire           emif_usr_clk;
  wire           emif_usr_reset_n;
  wire           ready;
  wire           amm_read;
  wire           amm_readdatavalid_0;
  wire [127:0]   amm_readdata_0;
  wire           valid_wire;
  wire           done;  
  wire           axi_ready;
  


  emif u0 (
         .local_reset_req      (),      //   input,     width = 1,    local_reset_req.local_reset_req
         .local_reset_done     (),     //  output,     width = 1, local_reset_status.local_reset_done
         .pll_ref_clk          (pll_ref_clk),          //   input,     width = 1,        pll_ref_clk.clk
         .oct_rzqin            (oct_rzqin),            //   input,     width = 1,                oct.oct_rzqin
         .mem_ck               (mem_ck),               //  output,     width = 1,                mem.mem_ck
         .mem_ck_n             (mem_ck_n),             //  output,     width = 1,                   .mem_ck_n
         .mem_a                (mem_a),                //  output,    width = 17,                   .mem_a
         .mem_act_n            (mem_act_n),            //  output,     width = 1,                   .mem_act_n
         .mem_ba               (mem_ba),               //  output,     width = 2,                   .mem_ba
         .mem_bg               (mem_bg),               //  output,     width = 1,                   .mem_bg
         .mem_cke              (mem_cke),              //  output,     width = 1,                   .mem_cke
         .mem_cs_n             (mem_cs_n),             //  output,     width = 1,                   .mem_cs_n
         .mem_odt              (mem_odt),              //  output,     width = 1,                   .mem_odt
         .mem_reset_n          (mem_reset_n),          //  output,     width = 1,                   .mem_reset_n
         .mem_par              (mem_par),              //  output,     width = 1,                   .mem_par
         .mem_alert_n          (mem_alert_n),          //   input,     width = 1,                   .mem_alert_n
         .mem_dqs              (mem_dqs),              //   inout,     width = 2,                   .mem_dqs
         .mem_dqs_n            (mem_dqs_n),            //   inout,     width = 2,                   .mem_dqs_n
         .mem_dq               (mem_dq),               //   inout,    width = 16,                   .mem_dq
         .mem_dbi_n            (mem_dbi_n),            //   inout,     width = 2,                   .mem_dbi_n
         .local_cal_success    (local_cal_success),    //  output,     width = 1,             status.local_cal_success
         .local_cal_fail       (local_cal_fail),       //  output,     width = 1,                   .local_cal_fail
         .emif_usr_reset_n     (emif_usr_reset_n),     //  output,     width = 1,   emif_usr_reset_n.reset_n
         .emif_usr_clk         (emif_usr_clk),         //  output,     width = 1,       emif_usr_clk.clk
         .amm_ready_0          (ready),          //  output,     width = 1,         ctrl_amm_0.waitrequest_n
         .amm_read_0           (amm_read),           //   input,     width = 1,                   .read
         .amm_write_0          (avm_read),          //   input,     width = 1,                   .write
         .amm_address_0        (avm_address),        //   input,    width = 27,                   .address
         .amm_readdata_0       (amm_readdata_0),       //  output,   width = 128,                   .readdata
         .amm_writedata_0      (avm_readdata),      //   input,   width = 128,                   .writedata
         .amm_burstcount_0     (avm_burstcount),     //   input,     width = 7,                   .burstcount
         .amm_byteenable_0     (avm_byteenable),     //   input,    width = 16,                   .byteenable
         .amm_readdatavalid_0  (amm_readdatavalid_0),  //  output,     width = 1,                   .readdatavalid
         .calbus_read          (calbus_read),          //   input,     width = 1,        emif_calbus.calbus_read
         .calbus_write         (calbus_write),         //   input,     width = 1,                   .calbus_write
         .calbus_address       (calbus_address),       //   input,    width = 20,                   .calbus_address
         .calbus_wdata         (calbus_wdata),         //   input,    width = 32,                   .calbus_wdata
         .calbus_rdata         (calbus_rdata),         //  output,    width = 32,                   .calbus_rdata
         .calbus_seq_param_tbl (calbus_param), //  output,  width = 4096,                   .calbus_seq_param_tbl
         .calbus_clk           (calbus_clk)            //   input,     width = 1,    emif_calbus_clk.clk
       );


  emif_cal u1 (
             .calbus_read_0          (calbus_read),          //  output,     width = 1,   emif_calbus_0.calbus_read
             .calbus_write_0         (calbus_write),         //  output,     width = 1,                .calbus_write
             .calbus_address_0       (calbus_address),       //  output,    width = 20,                .calbus_address
             .calbus_wdata_0         (calbus_wdata),         //  output,    width = 32,                .calbus_wdata
             .calbus_rdata_0         (calbus_rdata),         //   input,    width = 32,                .calbus_rdata
             .calbus_seq_param_tbl_0 (calbus_param), //   input,  width = 4096,                .calbus_seq_param_tbl
             .calbus_clk             (calbus_clk)              //  output,     width = 1, emif_calbus_clk.clk
           );


  avalon_host dut (
                .clk(emif_usr_clk),
                .rst_n(emif_usr_reset_n),
                .reset_release(done),
                .s_axi_data(x),
                .s_axi_valid(valid_wire),
                .s_axi_last(),
                .s_axi_ready(ready),
                .avm_address(avm_address),
                .avm_burstcount(avm_burstcount),
                .avm_write(avm_read),
                .avm_writedata(avm_readdata),
                .avm_byteenable(avm_byteenable),
                .avm_read_0(amm_read),
                .avm_readdata_0(amm_readdata_0),
                .avm_readdatavalid_0(amm_readdatavalid_0),
                .ready_out(axi_ready)                
              );

  // vio vio (
  //       .source(source),     //    sources.source
  //       .source_clk(emif_usr_clk)  // source_clk.clk
  //     );
  // // rom rom (
  // //       .q(x),       //       q.dataout
  // //       .address(address), // address.address
  // //       .clock(emif_usr_clk)    //   clock.clk
  // //     );
  counter counter (
        .clk(emif_usr_clk),
        .areset(emif_usr_reset_n),
        .ready_in(axi_ready),
        .valid(valid_wire),
        .count(x)
      );
  res res (
        .ninit_done(done)  // ninit_done.reset
      );

endmodule
