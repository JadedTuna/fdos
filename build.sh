#!/bin/sh
#=============================================================================#
#                                  FDOS                                       #
#                         Written by Victor Kindhart                          #
#                    FDOS - build.sh - Used to build FDOS                     #
#=============================================================================#

set -e
# Make sure it exists
mkdir -p obj
# Assemble bootloader
fasm bootloader.asm obj/bootloader.obj
# Assemble kernel
fasm kernel.asm obj/kernel.obj

# And now create bootable media
cat obj/bootloader.obj obj/kernel.obj > fdos.img