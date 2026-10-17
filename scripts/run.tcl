
#run.tcl compiles and runs the traffic FSM testbench at several clock frequencies
# then prints a pass/fail summary
# to run - from traffic-fsm folder
# vsim -c -do scripts/run.tcl

#sets a number of frequencies to test
set freqs {1 2 5 10}

# deletes the old library to ensure a fresh compile is used
if {[file exists work]} { vdel -lib work -all}
vlib work
vlog rtl/traffic_fsm.v tb/tb_traffic_fsm.v

# runs the tb once per frequency and records result
set failures 0
foreach f $freqs {
    vsim -voptargs=+acc -onfinish stop -GCLOCK_FREQ=$f work.tb_traffic_fsm
    run -all

    # reads the testbenches error counter from the sim
    set errs [examine -radix decimal /tb_traffic_fsm/errors]
    if {$errs == 0} {
        echo "CLOCK_FREQ=$f : Pass"
    } else {
        echo "CLOCK_FREQ=$f : Fail ($errs errors)"
        incr failures
    }
    quit -sim
    }

#summary of the tests
echo "Regression complete: [llength $freqs] runs, $failures failed"
quit -f