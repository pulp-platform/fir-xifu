# Finite Impulse Response CORE-V eXtended InterFace (CV-XIF) Functional Unit
This repository contains a simple Finite Impulse Response (FIR) filter XIF Functional Unit (XIFU) designed in particular as a teaching aid.
Lecturers can split out part of the repository or remove material to prepare guided exercises and lab lectures to learn:
 - about the design of tightly-coupled coprocessors
 - about instruction set architecture (ISA) extensions
 - about the XIF interface and the CV32E40X processor from OpenHW Group

## FIR XIFU structure
The FIR XIFU IP is fully described in SystemVerilog in the `rtl` folder. Each module is contained in a file with its own name, moreover there is a `fir_xifu_package` SV package containing constants data structure definitions.
The overall hierarchy of the FIR XIFU looks like this:

```
fir_xifu_top          # top-level of the IP
 |-> fir_xifu_ctrl    # main controller, including a simple scoreboard for instructions offloaded to the interface
 |-> fir_xifu_regfile # a private register file of parametric size
 |-> fir_xifu_id      # instruction decode stage
 |-> fir_xifu_ex      # instruction execute stage
 |-> fir_xifu_wb      # instruction write-back stage
```

The FIR XIFU provides essentially dot-products and right-shift operations on a private register file, not colliding with the architectural one of the core.
The IP follows the CV-XIF specifications and should be compatible with several cores following it; however, it has only been tested coupled with CV32E40X.

### Dependencies
The dependencies are managed via Bender (https://github.com/pulp-platform/bender).
