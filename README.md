# FDOS - FASM Disk Operating System
FDOS is a real mode DOS-like operating system written in x86 assembly.

# About
FDOS is a learning project to learn more about filesystems, operating systems and x86 assembly. The code is available under the LGPL license.

# TODO
See [TODO.md](TODO.md)

# Modifying the code
If you are only modifying the kernel running `make kernel` should be enough. Then you will need to copy the kernel into the .img file. That can be done by mounting it and replacing the already existing file. Running `make full` will recompile both bootloader and the kernel, and recreate the .img file. **Note:** it will **not** copy to kernel into the .img file.

# Writing programs for FDOS
This is unfortunately impossible for now, but I am working on adding functionality for loading files from the kernel. It will allow the user to create new programs and simply copy them into the .img file. Running them will be as simple as just typing the program's name in the shell.
