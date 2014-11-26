The project was mainly developed using the libsndfile library by Erik de Castro Lopo (https://github.com/erikd).
With this C library we read and write files containing sampled audio data.
The project is composed by two files: a C file from which the library functions are invoked and an Assembly file which is used to call the methods developed in C.
The core logic, consisting in mixing two mp3 audio files and writing the result in a new one, was implemented in Assembly language. MMX instructions were used to reduce the processing time, because they allow to execute multiple additions at the same time.
Due to the fact the library wasn't compatible with MP3 audio files, the program converts the input files to WAV format using ffmpeg library at the beginning and it does the inverse process at the end of the execution.

Libraries setup
--------------------
In order to manipulate the audio files, libraries installations are needed.

To install the ffmpeg library, follow these steps:
1) Download the library package from 'https://www.ffmpeg.org/download.html'
2) Extract the files in the desired directory
3) In a terminal, open the directory just extracted
4) Run the following commands:
  $ ./configure
  $ make
  $ sudo make install

To install the libsndfile library, follow these steps:
1) In a terminal, run the following commands to make sure you have installed some GNU and other Free and Open Source Software tools that are required to build the library:
  $ apt-get install autoconf
  $ apt-get install autogen
  $ apt-get install automake
  $ apt-get install libtool
  $ apt-get install pkgconfig
  $ apt-get install python
2) Download the library package at 'http://www.mega-nerd.com/libsndfile/#Download'
3) Extract the files in the desired directory
4) Open the directory just extracted and run the following commands:
  $ ./autogen.sh
  $ ./configure --enable-gcc-werror
  $ make
  $ sudo make check

Once you have ran all the commands you're ready to use the library functionalities.
  
Usage
----------
Open either 'double' or 'mmx' directory to build and run the application.
Inside of any of these folders you will find three files: 'build.sh', 'mp3Interface.c' and 'musicmixer.asm'.
You should run the 'build.sh' script which will compile and link the other two files:

  $ ./build.sh
  
After running the script you will be able to see an executable file called 'musicmixer'. To run the MusicMixer application use the following command:

  $ ./musicmixer <inputFileName1.mp3> <inputFileName2.mp3> <outputFileName.mp3>
  
In this project you will find a folder that contains some sample tracks, example:
  
  $ ./musicmixer ../sample_tracks/lamn_instrumental.mp3 ../sample_tracks/lamn_vocal.mp3 output_lamn.mp3
  
The command above will take both 'lamn_instrumental.mp3' and 'lamn_vocal.mp3' songs, mix them and write the resulting audio in 'output_lamn.mp3'

