set repo_dir   [file dirname [file normalize [info script]]]
set report_dir [file join $repo_dir build reports]
file mkdir $report_dir

source [file join $repo_dir create_project_here.tcl]

launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "Synthesis did not complete"
}

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
open_run impl_1

report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_utilization -file [file join $report_dir utilization.rpt]

puts "Bitstream flow finished. Review build/reports/timing_summary.rpt before programming the board."
