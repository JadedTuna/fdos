#=============================================================================#
#                                  FDOS                                       #
#                         Written by Victor Kindhart                          #
#                 FDOS - Makefile - used for building the OS                  #
#=============================================================================#

OBJDIR=obj
SRCDIR=src
FLOPPY=fdos
FLOPPYMNT=fdos

help:
	@echo -e "Available commands:"
	@echo -e "\tfloppy - create .img file"
	@echo -e "\tbootloader - compile bootloader and create .img file"
	@echo -e "\tkernel - compile the kernel"
	@echo -e "\tinstall-kernel - install the kernel."
	@echo -e "\tfull - compile both bootloader and kernel"
	@echo -e "\tqemu - run qemu"
	@echo -e "\tclean - clean up"
	@echo -e "\thelp - print this help message"

objdir:
	mkdir -p obj

floppy: objdir
	dd bs=512 count=2880 if=/dev/zero of=$(FLOPPY).img

bootloader: floppy
	fasm $(SRCDIR)/bootloader/bootloader.asm $(OBJDIR)/bootloader.o
	dd conv=notrunc if=$(OBJDIR)/bootloader.o of=$(FLOPPY).img

kernel: $(FLOPPY).img
	fasm $(SRCDIR)/kernel/kernel.asm $(OBJDIR)/kernel.sys

full: bootloader kernel

install-kernel:
	mkdir -p $(FLOPPYMNT)
	mount $(FLOPPY).img
	cp $(OBJDIR)/kernel.sys $(FLOPPYMNT)/KERNEL.SYS
	umount $(FLOPPY).img

qemu:
	qemu-system-i386 -fda $(FLOPPY).img

clean: objdir
	rm -f $(OBJDIR)/*
	rm -f $(FLOPPY).img