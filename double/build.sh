echo "Compiling assembly file..."
nasm -f elf musicmixer.asm
echo "Generating C object..."
gcc -c mp3Interface.c
echo "Linking binary file..."
gcc -g -o musicmixer musicmixer.o mp3Interface.o -lsndfile
rm musicmixer.o mp3Interface.o
echo "Done."

