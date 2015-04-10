#/**************************************************/
#/* Compile Script for Synopsys                    */
#/*                                                */
#/* dc_shell-t -f compile_dc.tcl                   */
#/*                                                */
#/* OSU FreePDK 45nm                               */
#/**************************************************/

#/* All verilog files, separated by spaces         */
set my_verilog_files [list arbiterPN.v demux1to2.v demux1to5.v demuxWrapper1to2.v demuxWrapper1to5.v global.v highestBit.v mux2to1.v mux5to1.v muxWrapper2to1.v muxWrapper5to1.v outSelTrans.v permutationNetwork.v permuterBlock.v routeComp.v topBLESS.v Xbar5Ports.v xbarCtrl.v topMultiNoC.v secondHighestBit.v lastBit.v computePPV.v portAllocParallel.v firstbit.v highestBit5.v highestBit6.v ejector.v ejectKillNInject.v]

#/* Top-level Module                               */
#set my_toplevel demux1to6
set my_toplevel topBLESS
#set my_toplevel portAllocParallel 
#set my_toplevel xbar6Ports 
#set my_toplevel  portAllocWrapper

#/* The name of the clock pin. If no clock-pin     */
#/* exists, pick anything                          */
set my_clock_pin clk

#/* Target frequency in MHz for optimization       */
set my_clk_freq_MHz 500

set my_period 1.03

#/* Delay of input signals (Clock-to-Q, Package etc.)  */
set my_input_delay_ns [expr $my_period*0.1]

#/* Reserved time for output signals (Holdtime etc.)   */
set my_output_delay_ns [expr $my_period*0.1]


#/**************************************************/
#/* No modifications needed below                  */
#/**************************************************/
set OSU_FREEPDK [format "%s%s"  [getenv "PDK_DIR"] "/osu_soc/lib/files"]
set search_path [concat  $search_path $OSU_FREEPDK]
#set alib_library_analysis_path $OSU_FREEPDK

set link_library [set target_library [concat  [list gscl45nm.db] [list dw_foundation.sldb]]]
set target_library "gscl45nm.db"
define_design_lib WORK -path /tmp/xxx1698/WORK
set verilogout_show_unconnected_pins "true"
set_ultra_optimization true
set_ultra_optimization -force

analyze -f verilog $my_verilog_files

elaborate $my_toplevel

current_design $my_toplevel

link
uniquify

#set my_period [expr 1000 / $my_clk_freq_MHz]

set find_clock [ find port [list $my_clock_pin] ]
if {  $find_clock != [list] } {
   set clk_name $my_clock_pin
   create_clock -period $my_period $clk_name
} else {
   set clk_name vclk
   create_clock -period $my_period -name $clk_name
}

set_driving_cell  -lib_cell INVX1  [all_inputs]
set_input_delay $my_input_delay_ns -clock $clk_name [remove_from_collection [all_inputs] $my_clock_pin]
set_output_delay $my_output_delay_ns -clock $clk_name [all_outputs]

compile -ungroup_all -map_effort medium

compile -incremental_mapping -map_effort medium

check_design
report_constraint -all_violators

set filename [format "%s%s"  $my_toplevel ".vh"]
write -f verilog -output /tmp/xxx1698/$filename

set filename [format "%s%s"  $my_toplevel ".sdc"]
write_sdc /tmp/xxx1698/$filename

set filename [format "%s%s"  $my_toplevel ".db"]
write -f db -hier -output /tmp/xxx1698/$filename -xg_force_db

redirect timing.rep { report_timing }
redirect cell.rep { report_cell }
redirect power.rep { report_power }

quit

