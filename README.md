# mini-NPU

This repository explores hardware acceleration through the RTL design of a neural processing unit (NPU). The core implements INT8 multiply-accumulate operations using a systolic-array-based architecture for efficient matrix computation.

## Motivation

---

## Architecture Overview

---

## Design Challenges

---

## Formal Verification (SVA)

---

## Timing Analysis (Sky130 Post-Synth)

---

## Repository Structure

```
/0-rtl/    - pure Verilog implementation of the matrix-multiply engine
/1-sim/    - testbenches for different workloads 
/2-formal/ - SystemVerilog assertions + SymbiYosys scripts 
/3-sta/    - static timing analysis with yosys/opensta/tcl scripts
/4-images/ - visual illustrations to better explain certain concepts
```

---

## Build & Simulate

### Compile

### Run

---

Thanks for stopping by!
