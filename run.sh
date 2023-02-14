nasm -felf64  main.asm -o main.o
gcc -no-pie main.o -lX11
./a.out
