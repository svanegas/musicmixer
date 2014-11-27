; musicmixer.asm
; 
; Para compilar se puede ejecutar el script "build.sh", de igual manera
; se puede hacer manualmente con los comandos:
;
;   $ nasm -f elf musicmixer.asm
;   $ gcc -c mp3Interface.c
;   $ gcc -g -o musicmixer musicmixer.o mp3Interface.o -lsndfile
;   $ rm musicmixer.o mp3Interface.o
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

;==============================================================================
; Inicia sección de definición de constantes
section .data
  sys_exit:               equ 1
  sys_write:              equ 4
  stdout:                 equ 1
  
  ;Definir mensaje para cantidad de parámetros inválidos
  ;el 10 al final es el fin de línea
  WRONG_PARAMS:           db  "USAGE: musicmixer <song1.mp3> <song2.mp3> <output.mp3>", 10
  
  ;Definir la longitud del mensaje
  ; $-WRONG_PARAMS indica el tamaño en Bytes del mensaje WRONG_PARAMS
  WRONG_PARAMS_LENGTH:    equ $-WRONG_PARAMS
  
  ;Definir mensajes de error al abrir archivos.
  UNABLE_TO_OPEN:         db "Error: could not open all the files.", 10
  UNABLE_TO_OPEN_LENGTH:  equ $-UNABLE_TO_OPEN
  
  ;Definir nombres de las canciones a trabajar
  SONG_1_NAME:            db  "input1.wav", 0
  SONG_2_NAME:            db  "input2.wav", 0
  SONG_OUT_NAME:          db  "outputsong.wav", 0
  
  ;Definir el tamaño del buffer
  BUFFER_LENGTH:          equ 4096
  
  ;Definir factor de multiplicación para la fórmula
  MULT_FACTOR:            dq  0.5
  
  ;Formato para impresión de mensaje de terminación
  END_MESSAGE_FORMAT:     db  10, 10, "Songs mixed successfully, output song generated in %s", 10

;==============================================================================
; Inicia sección de variables
section .bss
  song1Name               resb  4
  song2Name               resb  4
  songOutName             resb  4
  songOriginalOutput      resb  4

  ; Estas variables indican el número de ítems leídos de la canción que se
  ; encuentran actualmente en el buffer.
  itemsReadSong1          resb  4
  itemsReadSong2          resb  4
  
  ; Variables para almacenar el valor de cada uno de los ítems del buffer.
  outItem1                resb  4
  outItem2                resb  4
  index                   resb  4

;==============================================================================
; Se define la función de entrada del programa
section .text
  global main

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
  ;  ____________ ebp
  ; |   argv[3]  |+12 -> Parámetro de salida
  ; |   argv[2]  |+08 -> Segundo nombre de entrada
  ; |   argv[1]  |+04 -> Primer nombre de entrada
  ; | ebp|arg[0] |+00

  ;Obtener y almacenar el primer nombre de entrada
  mov ecx, [ebp + 4]
  mov [song1Name], ecx
 
  ;Se almacena para indicar a la función que se desea abrir
  ;el archivo número 1
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
  ;un mensaje de error, la función loadSong nos retorna un código, si ese código
  ;es 0 significa que sí se pudo abrir el archivo.
  cmp eax, 0
  jne unableToOpen
  
  ;Obtener y almacenar segundo nombre de entrada
  mov ecx, [ebp + 8]
  mov [song2Name], ecx
  
  ;Se almacena para indicar a la función que se desea abrir
  ;el archivo número 2
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
  
  ;Si no hay ningún elemento que leyó al menos un Byte entonces terminamos
  cmp eax, 0
  je mixDone
  
  ;Preparamos el contador index para leer los buffer
  mov dword[index], BUFFER_LENGTH
  dec dword[index]
  
loopGetIntBuffers:
  ;Cuando el index sea -1 es porque ya terminamos
  cmp dword[index], 0
  jl endLoopBuffer
  ;Obtener los valores de la canción en la posición actual
  push dword[index]
  call getSong1Item
  
  ; Acá empieza el uso de los registros MMX.
  ; Movemos al inicio del registro mm1 el contenido de eax
  movd mm1, eax
  call getSong2Item
  movd mm2, eax
  pop ecx
  
  ; Muevo todos los bits de mm1 32 veces a la izquierda
  psllw mm1, 32
  ; Muevo todos los bits de mm2 32 veces a la izquierda
  psllw mm2, 32
  
  dec dword[index]
  push dword[index]
  call getSong1Item
  movd mm1, eax
  call getSong2Item
  movd mm2, eax
  pop ecx
  
  ;Sumar los valores en paralelo, el resultado queda en mm1,
  ;donde los primeros 32 bits son la suma de los primeros 32 bits de mm1 y mm2
  ;y los segundos 32 bits corresponden a la suma de los segundos 32 bits
  ;de ambos registros.
  paddq mm1, mm2
  
  ;Muevo a eax los primeros 32 bits del resultado
  movd eax, mm1
  ;Guardo la suma de los primeros ítems en outItem1
  mov dword[outItem1], eax
  ;Se mueve el contenido de los segundos 32 bits del registro mm1 hacia
  ;los primeros 32 bits (shift a la derecha)
  psrlw mm1, 32
  ;Muevo el resultado de la segunda parte de la suma a eax 
  movd eax, mm1
  ;Guardo la suma de los primeros ítems en outItem2
  mov dword[outItem2], eax
  
  ;Esta instrucción debe ser ejecutada después de utilizar
  ;instrucciones de mmx, con el fin de reestablecer los registros
  emms
  
  ;Se carga el resultado 1 a la pila de flotantes.
  fild dword[outItem1]
  ;Cargar el multiplicador (0,5)
  fld qword[MULT_FACTOR]
  fmul
  ;Guardar el valor final en outItem1
  fistp dword[outItem1]
  
  ;Se carga el resultado 2 a la pila de flotantes.
  fild dword[outItem2]
  ;Cargar el multiplicador (0,5)
  fld qword[MULT_FACTOR]
  fmul
  ;Guardar el valor final en outItem2
  fistp dword[outItem2]
  
  ;Se debe incrementar el index para almacenar el resultado en la posición
  ;correcta, esto se debe a que se tomaron dos índices para ejecutar las
  ;instrucciones MMX.
  inc dword[index]
  push dword[outItem1]
  push dword[index]
  ;Guardar el pedazo de buffer en el buffer de salida
  call saveInBuffer
  pop ecx
  pop ecx
  
  ;Decremento el índice para almacenar el resultado de los segundos ítems.
  dec dword[index]
  push dword[outItem2]
  push dword[index]
  ;Guardar el pedazo de buffer en el buffer de salida
  call saveInBuffer
  pop ecx
  pop ecx
  
  ;Decremento el índice para iterar nuevamente
  dec dword[index]
  ;Iterar hasta acabar con todo el buffer
  jmp loopGetIntBuffers

endLoopBuffer:
  mov dword[itemsReadSong1], BUFFER_LENGTH
  push dword[itemsReadSong1]
  call writeResults
  pop ebx
  jmp readBuffers

;==============================================================================
; Terminar de procesar los audios, cerrar los archivos de entrada y salida
; y terminar el programa.
mixDone:
  push dword[songOriginalOutput]
  call convertSongToMp3
  call closeFiles
  push END_MESSAGE_FORMAT
  call printf
  pop ecx
  pop ecx
  jmp exit

;==============================================================================
; Salir del programa
exit:
    mov eax, sys_exit
    xor ebx, ebx
    int 80h

