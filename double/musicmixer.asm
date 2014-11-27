; musicmixer.asm
; 
; Para compilar se puede ejecutar el script "build.sh", de igual manera
; se puede hacer manualmente con los comandos:
;
;   $ nasm -f elf musicmixer.asm
;   $ gcc -c includes.c
;   $ gcc -g -o musicmixer musicmixer.o includes.o -lsndfile
;   $ rm musicmixer.o includes.o
;
; Uso: ./musicmixer <nombreentrada1.mp3> <nombreentrada2.mp3> <nombresalida.mp3>

extern initializeLibrary
extern loadSong
extern setFormat
extern readBufferFromSong1
extern readBufferFromSong2
extern getSong1Item
extern getSong2Item
extern saveInBuffer
extern writeResults
extern convertSongToWav
extern convertSongToMp3
extern closeFiles
extern printf

section .data
  sys_exit:               equ 1
  sys_write:              equ 4
  stdout:                 equ 1
  
  ;Definir mensaje para cantidad de parámetros inválidos
  ;el 10 al final es el fin de línea
  WRONG_PARAMS:           db  "USAGE: musicmixer <song1.mp3> <song2.mp3> <output.mp3>", 10
  
  ;Definir la longitud del mensaje
  WRONG_PARAMS_LENGTH:    equ $-WRONG_PARAMS
  
  ;Definir mensajes de error al abrir archivos.
  UNABLE_TO_OPEN:         db  "Error: could not open all the files.", 10 
  UNABLE_TO_OPEN_LENGTH:  equ $-UNABLE_TO_OPEN
  
  ;Definir nombres de las canciones a trabajar
  SONG_1_NAME:            db  "input1.wav", 0
  SONG_2_NAME:            db  "input2.wav", 0
  SONG_OUT_NAME:          db  "outputsong.wav", 0
  
  ;Definir la constante para fin de línea
  ENDL:                   db  0xa
  
  ;Definir el tamaño del buffer
  BUFFER_LENGTH:          equ 4096
  
  ;Definir factor de multiplicación para la fórmula
  MULT_FACTOR:            dq  0.5
  
  ;Formato para impresión de mensaje de terminación
  END_MESSAGE_FORMAT:     db  10, 10, "Songs mixed successfully, output song generated in %s", 10

section .bss
  song1Name               resb  4
  song2Name               resb  4
  songOutName             resb  4
  songOriginalOutput      resb  4
  
  ; Reservar variables para los flags de la lectura de buffer
  itemsReadSong1          resb  4
  itemsReadSong2          resb  4
  
  ; Reservar punteros para los buffers de las canciones
  bufferSong1             resb  4
  bufferSong2             resb  4
  inItem                  resq  1
  outItem                 resq  1

section .text
  global main
  global echol
  global strlen

;==============================================================================
; Punto de entrada del programa (main)
main:
  ; El segundo elemento en el stack es argc (número de argumentos de consola)
  mov ecx, [esp + 4]

  ; Comparamos argc con 4
  cmp ecx, 4
  
  ; Si no es 4, se muestra error de parámetros
  jne wrongParams

  je storeNames

;==============================================================================
wrongParams:
  ; Se le dice al sistema que se quiere escribir
  mov eax, sys_write
  ; Por salida estándar
  mov ebx, stdout
  ; Se envía el mensaje por ecx
  mov ecx, WRONG_PARAMS
  ; Cantidad de bytes a imprimir
  mov edx, WRONG_PARAMS_LENGTH
  int 80h
  jmp exit

;==============================================================================
; Almacena los argumentos recibidos por consola en las variables song1Name,
; song2Name y songOutName
storeNames:
  ;Apuntador al inicio de los argumentos
  mov ebp, [esp + 8]
  
  ;    PILA
  ;  _________
  ; | argv[3] |+12 -> Parámetro de salida
  ; | argv[2] |+08 -> Segundo nombre de entrada
  ; | argv[1] |+04 -> Primer nombre de entrada
  ; |   ebp   |+00

  ;Obtener y almacenar el primer nombre de entrada
  mov ecx, [ebp + 4]
  mov [song1Name], ecx
 
  ;Se almacena para indicar a la función que se desea abrir
  ;el archivo número 1, se convierte a .wav y se obtiene el nuevo nombre
  push 1 
  push dword[song1Name]
  call convertSongToWav
  pop ecx
  mov dword[song1Name], SONG_1_NAME
  push dword[song1Name]
  call loadSong
  pop ecx
  pop ecx
  ;En caso de que no se haya podido abrir el archivo, se imprime
  ;un mensaje de error 
  cmp eax, 0
  jne unableToOpen
  
  ;Obtener y almacenar segundo nombre de entrada
  mov ecx, [ebp + 8]
  mov [song2Name], ecx
  
  ;Se almacena para indicar a la función que se desea abrir
  ;el archivo número 2, se convierte a .wav y se obtiene el nuevo nombre
  push 2
  push dword[song2Name]
  call convertSongToWav
  pop ecx
  mov dword[song2Name], SONG_2_NAME
  push dword[song2Name]
  call loadSong
  pop ecx
  pop ecx
  ;En caso de que no se haya podido abrir el archivo, se imprime
  ;un mensaje de error 
  cmp eax, 0
  jne unableToOpen
  
  ; Obtener y almacenar nombre de salida
  mov ecx, [ebp + 12]
  mov [songOriginalOutput], ecx
  mov dword[songOutName], SONG_OUT_NAME
  
  ;Se almacena para indicar a la función que se desea abrir
  ;el archivo número 3 (de salida)
  push 3
  push dword[songOutName]
  call loadSong
  pop ecx
  pop ecx
  
  ;En caso de que no se haya podido abrir el archivo, se imprime
  ;un mensaje de error 
  cmp eax, 0
  jne unableToOpen
  
  ;Establecer el formato de lectura para los buffers de audio
  call setFormat
  
  ;Procesar los audios en el buffer
  jmp readBuffers

;==============================================================================
; Función para imprimir un mensaje de error cuando no ha sido posible
; abrir alguno de los archivos de entrada.
unableToOpen:
; Se le dice al sistema que se quiere escribir
  mov eax, sys_write
  ; Por salida estándar
  mov ebx, stdout
  ; Se envía el mensaje por ecx
  mov ecx, UNABLE_TO_OPEN
  ; Cantidad de bytes a imprimir
  mov edx, UNABLE_TO_OPEN_LENGTH
  int 80h
  jmp exit

;==============================================================================
; Función para leer los buffers de las canciones y sumar los valores
readBuffers:
  ;Llamar la función para leer buffer de la canción 1 y almacenar
  ;los items leidos por la biblioteca
  call readBufferFromSong1
  mov dword[itemsReadSong1], eax
  
  ;Llamar la función para leer buffer de la canción 2 y almacenar
  ;los items leidos por la biblioteca
  call readBufferFromSong2
  mov dword[itemsReadSong2], eax
  
  ;Se hace un or lógico entre los dos valores para ver si hay almenos
  ;una canción que lea
  or eax, dword[itemsReadSong1]
  
  ;Si no hay ningún elemento que leyó almenos un Byte entonces terminamos
  cmp eax, 0
  je mixDone

  ;Preparamos el contador ecx para iterar en los buffers leídos
  mov ecx, BUFFER_LENGTH
  
loopGetDoublesBuffers:
  mov ebx, BUFFER_LENGTH
  sub ebx, ecx
  push ebx
  ;Obtener los valores de la canción en la posición actual (quedan en la pila)
  call getSong1Item
  call getSong2Item
  pop eax
  ;Sumar los valores
  fadd
  ;Cargar el multiplicador (0,5)
  fld qword[MULT_FACTOR]
  fmul
  ;Guardar el valor final en outItem
  fstp qword[outItem]
  push dword[outItem + 4]
  push dword[outItem]
  push ebx
  ;Guardar el pedazo de buffer en el buffer de salida
  call saveInBuffer
  pop eax
  pop eax 
  pop eax
  dec ebx
  ;Iterar hasta acabar con todo el buffer
  loop loopGetDoublesBuffers
  
  mov dword[itemsReadSong1], BUFFER_LENGTH
  push dword[itemsReadSong1]
  
  ;Escribir los resultados en el archivo de salida
  call writeResults
  pop ebx
  jmp readBuffers

;==============================================================================
; Terminar de procesar los audios, cerrar los archivos de entrada y salida
; y terminar el programa.
mixDone:
  push dword[songOriginalOutput]
  call convertSongToMp3
  push END_MESSAGE_FORMAT
  call printf
  pop ecx
  pop ecx
  call closeFiles
  jmp exit
  
;==============================================================================
; Salir del programa.
exit:
    mov eax, sys_exit
    xor ebx, ebx
    int 80h

