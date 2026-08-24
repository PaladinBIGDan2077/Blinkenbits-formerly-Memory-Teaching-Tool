## Members
Daniel J. Lomis, Computer Engineering: Chip-Scale Integration (May 2026)
dlomis1999@vt.edu

## Mentor
Professor Jason S. Thweatt

## Current Status
IN PROGRESS

## Project Overview

This project will demonstrate to the end-user how memory is used to store and read data within a computer, how changing BITs will have an effect on the output of a visualized character. while the unit itself will not be using a centralized processing unit instead the heart of the binary to ask you decoding will be controlled by a character generator ROM made by Fairchild semiconductor. The particular part is a 3257ADC from the late 1970s. The use of vintage components in this particular build helps to take away the layers of abstraction that computers now represent in modern day technology. By simplifying the underlying hardware that has the result of making the overall explanation of its functionality simpler. All plans were originally meant to include a set of early 1980s SRAM moudules. The need to switch to multiple education boards for the final product, made it clear that additional memory was needed as well as a more ample and stable supply of it.

## Educational Value Added

It provides insight to how character generator ROMs work, which were quite common in the days of early home computing. This will lead to a further understanding of ASCII based decoding. Storage of certain bits will allow the character rom to display individual characters on an LED Matrix, which will allow the viewer to write a message on screen letter by letter. A Binary Counter will be used to scroll through memory addresses, and a buffer will be used to display the current data to write to memory, as well as entry of a specific memory address.

## Tasks

Remaining tasks
 • research and implementation of a proper display method for the 8 x 8 matrix
 • research in limitation of the chosen memory modules
 • research and implementation of a binary input method for the memory
 • optional: an implementation to set and reset the memory counter to change specific memory areas that aren't linearly accessed

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
