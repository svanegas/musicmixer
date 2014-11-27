#include <sndfile.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define	BUFFER_LEN 4096

SNDFILE *inputSong1, *inputSong2, *outputSong;
SF_INFO sfInfo;

int buffer1[BUFFER_LEN], buffer2[BUFFER_LEN];

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
        return 1; //Error abriendo canción 1
	    }
	    //Revisar el formato del archivo 1
      if (!sf_format_check(&sfInfo)) {
        sf_close(inputSong1);
        return 1; //Error de formato de canción
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
  return 0; //Éxito al abrir el archivo
}

void
setFormat() {
  //Indicarle a la biblioteca que se va a trabajar con archivos WAV y que se
  //quieren los items del buffer en enteros de 32 bits.
  sfInfo.format = SF_FORMAT_WAV | SF_FORMAT_PCM_32;
}

int
readBufferFromSong1() {
  return sf_read_int(inputSong1, buffer1, BUFFER_LEN);
}

int
readBufferFromSong2() {
  return sf_read_int(inputSong2, buffer2, BUFFER_LEN);
}

int
getSong1Item(int index) {
  return index >= 0 ? buffer1[index] : 0;
}

int
getSong2Item(int index) {
  return index >= 0 ? buffer2[index] : 0;
}

void
saveInBuffer(int index, int value) {
  if (index < 0) return;
  buffer1[index] = value;
}

void
writeResults(int readCount) {
  printf("Buffers wrote in output song: %d\r", buffersWrote++);
  sf_write_int(outputSong, buffer1, readCount);
}

void
convertSongToWav(char *songName, int songNumber) {
  system("touch input1.wav input2.wav");
  system("rm input1.wav input2.wav");
  char *first = "ffmpeg -i ";
  char *second;
  if (songNumber == 1) second = " input1.wav";
  else second = " input2.wav";
  // +1 es por el caracter terminador.
  char *command = malloc(strlen(first) + strlen(songName) + strlen(second) + 1);
  strcpy(command, first);     //command = ffmpeg -i
  strcat(command, songName);  //command = ffmpeg -i songName.mp3
  strcat(command, second);    //command = ffmpeg -i songName.mp3 input2.wav
  system(command);            //Ejecuto el comando
}

void
convertSongToMp3(char *songName) {
  puts(""); //Se imprimie una línea vacía para que no se sobreescriba el número
            //de buffers copiados en la canción de salida.
  char *first = "touch ";
  char *comm = malloc(strlen(first) + strlen(songName) + 1);
  strcpy(comm, first);    //comm = touch
  strcat(comm, songName); //comm = touch songName.mp3
  system(comm);           //Ejecuto el comando
  first = "rm ";
  comm = malloc(strlen(first) + strlen(songName) + 1);
  strcpy(comm, first);    //comm = rm
  strcat(comm, songName); //comm = rm songName.mp3
  system(comm);           //Ejecuto el comando
  first = "ffmpeg -i outputsong.wav ";
  comm = malloc(strlen(first) + strlen(songName) + 1);
  strcpy(comm, first);    //comm = ffmpeg -i outputsong.wav
  strcat(comm, songName); //comm = ffmpeg -i outputsong.wav songName.mp3
  system(comm);           //Ejecuto el comando
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
