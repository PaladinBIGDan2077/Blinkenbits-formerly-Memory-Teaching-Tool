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
 - Develop a PCB Footprint and Symbol for the 8x8 Matrix in KiCad
 - Determine the best circuit to implement the clock generation for the vertical and horizontal line drawing (must be two separate circuits), maybe PLL-based for Vertical generation or both maybe 555-based for the Horizontal generation (needs to be adjustable to center the letter)
 - Determine the best way to change colors either using relays or solid state circuits (it may need to involve 7 separate 3-direction analog multiplexers per column)

   
## Design Decisions

 - the board will be placed on a single PCB smaller than a sheet of standard letter paper
 - the device will be using a 16 VDC power supply going into the power connector on the board. The type of power supply and whether it will be USB-C based has yet to be determined.
 - the 3257ADC is the heart of the display readout
 - A combination of decade counters, inverters, Bipolar-Junction Transistors, 3-t0-8 decoders will be used to control the display output
 - Power Supply will likely be shielded or encased to avoid potential burns from the Voltage Regulators (potentially using the cage itself as a heatsink?)
   
## Design Misc

# 8-Bit D-type Flip Flop Demo Board
 - Developed a preliminary demo PCB (using an octal D-type Flip Flop chip) to aide in improving circuit development knowledge, and ensure a sucessful and functional build
 - Learned important methods to clock circuit design practices
   
## Steps for Documenting Your Design Process

Additions completed as I go, every 8 weeks a new presentation will be uploaded demonstrating progress on the project overall (mainly for the AMP Lab team)

## BOM + Component Cost

VINTAGE Fairchild 3257ADC Character Generator ROM - $16.37
8X8 LED MATRIX - $10.86
OnSemi (Motorola) 4 x 1024 Bit SRAM Memory, two in parallel making 1K of memory - $7.99 (per chip)
Various 74-series logic chips, more will be added as design decisions are finalized - $9.99 (per chip)
PCB Generation: Prototype (8-Bit D-Type Flip Flop Display Board, practice) - $11.15
PCB Generation: Visual-portion Prototype - $9.99
PCB Generation: Final Product

## Timeline

<!-- Your Text Here. You may work with your mentor on this later when they are assigned -->

## Useful Links

 - https://en.wikipedia.org/wiki/ASCII
 - https://en.wikipedia.org/wiki/7400-series_integrated_circuits
 - https://en.wikipedia.org/wiki/Character_generator
 - https://en.wikipedia.org/wiki/Transistor

## Log

<!-- Your Text Here. You may work with your mentor on this later when they are assigned -->
