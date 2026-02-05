# ==============================================================================
# Makefile for AXI4-Lite LED/SEG/IRQ UVM Testbench
# ==============================================================================

# Simulator Selection (VCS, QUESTA, XCELIUM)
SIM ?= VCS

# Directories
RTL_DIR = ./rtl
TB_DIR = .
SIM_DIR = ./sim

# RTL Files
RTL_FILES = $(RTL_DIR)/axi_ledseg_irq.sv

# Testbench Files
TB_FILES = $(TB_DIR)/axi_if.sv \
           $(TB_DIR)/tb_pkg.sv \
           $(TB_DIR)/tb_top.sv

# UVM Home (adjust based on your installation)
UVM_HOME ?= $(VCS_HOME)/etc/uvm-1.2

# Common Options
UVM_VERBOSITY ?= UVM_MEDIUM
TEST ?= regression_test
SEED ?= $(shell date +%s)

#------------------------------------------------------------------------------
# VCS Options
#------------------------------------------------------------------------------
VCS = vcs
VCS_OPTS = -sverilog \
           -timescale=1ns/1ps \
           -full64 \
           -debug_access+all \
           -kdb \
           -lca \
           -ntb_opts uvm-1.2 \
           +vcs+lic+wait \
           -l compile.log

VCS_RUN_OPTS = +UVM_TESTNAME=$(TEST) \
               +UVM_VERBOSITY=$(UVM_VERBOSITY) \
               -l sim_$(TEST).log \
               +ntb_random_seed=$(SEED)

#------------------------------------------------------------------------------
# Questa Options
#------------------------------------------------------------------------------
QUESTA = vlog
QUESTA_OPTS = -sv \
              -timescale 1ns/1ps \
              +acc \
              -L $(QUESTA_UVM_HOME) \
              -l compile.log

QUESTA_SIM = vsim
QUESTA_RUN_OPTS = -c \
                  -do "run -all; quit" \
                  +UVM_TESTNAME=$(TEST) \
                  +UVM_VERBOSITY=$(UVM_VERBOSITY) \
                  -l sim_$(TEST).log \
                  -sv_seed $(SEED)

#------------------------------------------------------------------------------
# Xcelium Options
#------------------------------------------------------------------------------
XCELIUM = xrun
XCELIUM_OPTS = -sv \
               -timescale 1ns/1ps \
               -access +rwc \
               -uvm \
               -uvmhome $(XCELIUM_UVM_HOME) \
               -l compile.log

XCELIUM_RUN_OPTS = +UVM_TESTNAME=$(TEST) \
                   +UVM_VERBOSITY=$(UVM_VERBOSITY) \
                   -l sim_$(TEST).log \
                   -svseed $(SEED)

#------------------------------------------------------------------------------
# Targets
#------------------------------------------------------------------------------

.PHONY: all clean compile sim run_reset run_basic run_irq run_stress run_regression help

all: compile

help:
	@echo "=============================================="
	@echo "  AXI4-Lite UVM Testbench - Makefile Help"
	@echo "=============================================="
	@echo ""
	@echo "Usage: make <target> [options]"
	@echo ""
	@echo "Targets:"
	@echo "  compile         - Compile testbench"
	@echo "  sim             - Compile and run test"
	@echo "  run_reset       - Run reset test"
	@echo "  run_basic       - Run basic read/write test"
	@echo "  run_wstrb       - Run WSTRB test"
	@echo "  run_irq         - Run IRQ test"
	@echo "  run_concurrent  - Run concurrent test"
	@echo "  run_stress      - Run stress test"
	@echo "  run_regression  - Run full regression"
	@echo "  clean           - Clean simulation files"
	@echo "  help            - Show this help"
	@echo ""
	@echo "Options:"
	@echo "  SIM=<VCS|QUESTA|XCELIUM>  - Select simulator (default: VCS)"
	@echo "  TEST=<test_name>          - Specify test (default: regression_test)"
	@echo "  SEED=<value>              - Random seed (default: timestamp)"
	@echo "  UVM_VERBOSITY=<level>     - UVM verbosity level (default: UVM_MEDIUM)"
	@echo ""
	@echo "Examples:"
	@echo "  make compile"
	@echo "  make sim TEST=reset_test"
	@echo "  make run_regression SEED=12345"
	@echo "  make sim SIM=QUESTA TEST=irq_test"
	@echo ""

#------------------------------------------------------------------------------
# Compilation Targets
#------------------------------------------------------------------------------

compile: compile_$(SIM)

compile_VCS:
	@echo "=========================================="
	@echo "  Compiling with VCS..."
	@echo "=========================================="
	mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && $(VCS) $(VCS_OPTS) $(RTL_FILES) $(TB_FILES)
	@echo "Compilation complete!"

compile_QUESTA:
	@echo "=========================================="
	@echo "  Compiling with Questa..."
	@echo "=========================================="
	mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && $(QUESTA) $(QUESTA_OPTS) $(RTL_FILES) $(TB_FILES)
	@echo "Compilation complete!"

compile_XCELIUM:
	@echo "=========================================="
	@echo "  Compiling with Xcelium..."
	@echo "=========================================="
	mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && $(XCELIUM) $(XCELIUM_OPTS) -compile $(RTL_FILES) $(TB_FILES)
	@echo "Compilation complete!"

#------------------------------------------------------------------------------
# Simulation Targets
#------------------------------------------------------------------------------

sim: sim_$(SIM)

sim_VCS: compile_VCS
	@echo "=========================================="
	@echo "  Running test: $(TEST)"
	@echo "  Seed: $(SEED)"
	@echo "=========================================="
	cd $(SIM_DIR) && ./simv $(VCS_RUN_OPTS)
	@echo "Simulation complete! Check sim_$(TEST).log"

sim_QUESTA: compile_QUESTA
	@echo "=========================================="
	@echo "  Running test: $(TEST)"
	@echo "  Seed: $(SEED)"
	@echo "=========================================="
	cd $(SIM_DIR) && $(QUESTA_SIM) $(QUESTA_RUN_OPTS) work.tb_top
	@echo "Simulation complete! Check sim_$(TEST).log"

sim_XCELIUM: compile_XCELIUM
	@echo "=========================================="
	@echo "  Running test: $(TEST)"
	@echo "  Seed: $(SEED)"
	@echo "=========================================="
	cd $(SIM_DIR) && $(XCELIUM) $(XCELIUM_OPTS) $(XCELIUM_RUN_OPTS) -R
	@echo "Simulation complete! Check sim_$(TEST).log"

#------------------------------------------------------------------------------
# Individual Test Targets
#------------------------------------------------------------------------------

run_reset:
	$(MAKE) sim TEST=reset_test

run_basic:
	$(MAKE) sim TEST=basic_write_test

run_wstrb:
	$(MAKE) sim TEST=wstrb_test

run_irq:
	$(MAKE) sim TEST=irq_test

run_concurrent:
	$(MAKE) sim TEST=concurrent_test

run_stress:
	$(MAKE) sim TEST=stress_test

run_regression:
	$(MAKE) sim TEST=regression_test

#------------------------------------------------------------------------------
# Coverage Targets
#------------------------------------------------------------------------------

cov: cov_$(SIM)

cov_VCS:
	@echo "Generating coverage report..."
	cd $(SIM_DIR) && urg -dir simv.vdb -report $(SIM_DIR)/coverage
	@echo "Coverage report generated in $(SIM_DIR)/coverage"

cov_QUESTA:
	@echo "Generating coverage report..."
	cd $(SIM_DIR) && vcover report -html $(SIM_DIR)/coverage
	@echo "Coverage report generated in $(SIM_DIR)/coverage"

#------------------------------------------------------------------------------
# Utility Targets
#------------------------------------------------------------------------------

clean:
	@echo "Cleaning simulation files..."
	rm -rf $(SIM_DIR)
	rm -rf simv* csrc* *.log *.vcd *.vpd DVE* ucli.key
	rm -rf work transcript vsim.wlf modelsim.ini
	rm -rf xcelium.d INCA_libs *.shm *.diag
	@echo "Clean complete!"

.PHONY: compile_VCS compile_QUESTA compile_XCELIUM
.PHONY: sim_VCS sim_QUESTA sim_XCELIUM
.PHONY: cov_VCS cov_QUESTA
