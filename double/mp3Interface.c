#include <sndfile.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define	BUFFER_LEN 4096

SNDFILE *inputSong1, *inputSong2, *outputSong;
SF_INFO sfInfo;

double buffer1[BUFFER_LEN], buffer2[BUFFER_LEN];

int buffersWrote = 0;

void
initializeLibrary() {
  memset (&sfInfo, 0, sizeof (sfInfo));
}

int
loadSong(char *songName, int songID) {
  switch (songID) {
    case 1:
      if (!(inputSong1 = sf_open(songName, SFM_READ, &sfInfo))) {	
        return 1;
	    }
	    //Revisar el formato del archivo 1
      if (!sf_format_check(&sfInfo)) {
        sf_close(inputSong1);
        return 1;
      }
      break;
    case 2:
      if (!(inputSong2 = sf_open(songName, SFM_READ, &sfInfo))) {	
        return 2;
	    }
	    //Revisar el formato del archivo 1
      if (!sf_format_check(&sfInfo)) {
        sf_close(inputSong2);
        return 2;
      }
      break;
    case 3:
      if (!(outputSong = sf_open(songName, SFM_WRITE, &sfInfo))) {	
        return 3;
	    }
	    //Revisar el formato del archivo 3
      if (!sf_format_check(&sfInfo)) {
        sf_close(outputSong);
        return 3;
      }
      break; 
  }
  return 0;
}

void
setFormat() {
  sfInfo.format = SF_FORMAT_WAV | SF_FORMAT_DOUBLE;
}

int
readBufferFromSong1() {
  int a = sf_read_double(inputSong1, buffer1, BUFFER_LEN);
  return a;
}

int
readBufferFromSong2() {
  int a = sf_read_double(inputSong2, buffer2, BUFFER_LEN);
  return a;
}

double
getSong1Item(int index) {
  return buffer1[index];
}

double
getSong2Item(int index) {
  return buffer2[index];
}

void
saveInBuffer(int index, double value) {
  buffer1[index] = value;
}

void
writeResults(int readCount) {
  printf("\r%d buffers wrote in output song", buffersWrote++);
  sf_write_double(outputSong, buffer1, readCount);
}

void
convertSongToWav(char *songName, int songNumber) {
  system("touch input1.wav input2.wav");
  system("rm input1.wav input2.wav");
  char *first = "ffmpeg -i ";
  char *second;
  if (songNumber == 1) second = " input1.wav";
  else second = " input2.wav";
  char *command = malloc(strlen(first) + strlen(songName) + strlen(second) + 1);
  strcpy(command, first);
  strcat(command, songName);
  strcat(command, second);
  system(command);
}

void
convertSongToMp3(char *songName) {
  printf("Me llega para convertir %s\n", songName);
  char *first = "touch ";
  char *comm = malloc(strlen(first) + strlen(songName) + 1);
  strcpy(comm, first);
  strcat(comm, songName);
  system(comm);
  first = "rm ";
  comm = malloc(strlen(first) + strlen(songName) + 1);
  strcpy(comm, first);
  strcat(comm, songName);
  system(comm);
  first = "ffmpeg -i outputsong.wav ";
  comm = malloc(strlen(first) + strlen(songName) + 1);
  strcpy(comm, first);
  strcat(comm, songName);
  system(comm);
  system("rm outputsong.wav");
}

void
closeFiles() {
  system("touch input1.wav input2.wav");
  system("rm input1.wav input2.wav");
  sf_close(inputSong1);
	sf_close(inputSong2);
	sf_close(outputSong);
}

