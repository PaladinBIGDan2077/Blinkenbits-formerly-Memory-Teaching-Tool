## Project Name
WIP Title: BlinkenBits
Internal Codename: Memory Teaching Tool

## Members
Daniel J. Lomis, Computer Engineering: Chip-Scale Integration (May 2027)
dlomis1999@vt.edu

## Mentor
Professor Jason S. Thweatt

## Current Status
IN PROGRESS

## Project Overview

This project will demonstrate to the end-user how memory is used to store and read data within a computer, how changing BITs will have an effect on the output of a visualized character. While the unit itself will not be using a centralized processing unit to control the screen, instead an ASCII table will be given to insert the desired letter into each memory address, those bits will then be decoded by a character generator ROM made by Fairchild Semiconductor. The particular part is a 3257ADC from the late 1970s. The use of vintage components in this particular build helps to take away the layers of abstraction that computers now typically use in modern day technology. By simplifying the underlying hardware, this has the result of making the overall explanation of its functionality simpler. All plans were originally meant to include a set of early 1980s SRAM modules and to only develop one board; however, the scope and end goal of this project has grown to the creation of about 20 boards necesitating the switch to a more reliable supply of MM2114 SRAM Units. 

## Educational Value Added

It provides insight to how a character generator ROMs works, which were quite common in the days of early home computing. This type of technology was used in primitive computer video cards, consoles, glass teletype systems, and signage. This will lead to a further understanding of ASCII based decoding. Storage of certain bits will allow the character rom to display individual characters on an LED Matrix, which will allow the viewer to write a message on screen letter by letter. A Binary Counter will be used to scroll through memory addresses, and a buffer will be used to display the current data to write to memory, as well as entry of a specific memory address. This will be given as a either a hexadecimal readout and binary readout of the bus as well. Octal might be implemented depending on time. Since the CG ROM only needs six bits to cover the original 64 ASCII characters installed on it, the two remaining bits might be used to control the color being displayed (00 - Red, 01 - Green, 10 - Blue, 11 - Blank). The end goal is to potentially showcase 20 of these boards to a class of students (like middle-school, elementary-school) and try to recruit students into the field of Computer Engineering/Science. 

## Tasks

# Completed Tasks
 - Functional and Reliable Implementation of the 8x8 LED Matrix
 - Sourcing the proper driving logic to handle the display generation
 - Selection of appropriate memory DIPs for the project
 - Drafted initial design of character input, insert/read, using D-type Flip Flops, SR Latch, Asynchronus Clear Binary Counter with Preset-able Option and Bus Trancievers.
 - Finalized testing platform for circuit testing and implementation development
 - Testing of SR Latch as a potential input method for data (allowing the use of momentary switches)

# Remaining tasks
 - Preliminary physical development of the data portion of the data input circuit
 - Implement Memory Testing using SystemVerilog to check the operation of the MM2114
 - Develop a physical PCB prototype of the 8x8 Matrix portion of the circuit (as current implementation has a tendency to fail due to the literal rats nest of jumpers and wires being used. This will improve testing accuracy when moving on to the data input side)
 - Develop a PCB Footprint and Symbol for the 8x8 Matrix

   
## Design Decisions

 • the board will be placed on a single PCB smaller than a sheet of standard letter paper
 • the device will be using a 16 VDC power supply going into the power connector on the board. The type of power supply and whether it will be USB-C based has yet to be determined.
 • 
## Design Misc

<!-- Your Text Here. You may work with your mentor on this later when they are assigned -->

## Steps for Documenting Your Design Process

<!-- Your Text Here. You may work with your mentor on this later when they are assigned -->

## BOM + Component Cost

VINTAGE Fairchild 3257ADC Character Generator ROM - $16.37
8X8 LED MATRIX - $10.86
VINTAGE AMD AM9101BPC SRAM Modules 256 x 4 BITS, (two used in series, two in parallel, to increase to 512 X 8 BITS) 512K RAM - $23.97


## Timeline

<!-- Your Text Here. You may work with your mentor on this later when they are assigned -->

## Useful Links

<!-- Your Text Here. You may work with your mentor on this later when they are assigned -->

## Log

<!-- Your Text Here. You may work with your mentor on this later when they are assigned -->
