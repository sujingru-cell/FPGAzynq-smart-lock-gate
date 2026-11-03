# AA18 is not on a dedicated clock route on this board.
# This exception is enabled for implementation only by create_project_here.tcl.
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]
