%include "io.inc"

%include    '/home/chus/Arqui1/PruebasSasm/functions.asm'

SECTION .data
entrada_a_leer db '/home/chus/Arqui1/DefensaProgra1/polka_eco.txt', 0h    ; Archivo de entrada a leer
archivo_salida db '/home/chus/Arqui1/DefensaProgra1/polka_noeco.txt', 0h       ; Archivo de salida para cargar los datos finales
salto_linea    db 0ah                                                          ; Salta lineas
k              dw 2205                                                         ;Se pasa de flotante a binario
alfa           dw 153                                                          ;Se pasa alfa de flotante a binario
uno_menosAlfa  dw 102                                                          ;Se pasa de flotante a binario
uno_entreUno_menosAlfa dw 640                                                  ;Se pasa de flotante a binario



SECTION .bss
decriptor_entrada:  RESB  4     ;Se guardan 4 bytes para l decriptor de entrada
decriptor_salida:   RESB  4     ;Se guardan 4 bytes para 1 decriptor de entrada
puntero_lectura:    RESD  1     ;Se guardan 4 bytes para el puntero de lectura. 32 bits

valor_numero:       RESB  16    ;Se guarda el valor del numero. Guarda lo que lee el archivo
valor_a_escribir:   RESB  16    ;Se dice cual valor se va a escribir en la salida

contador_bits:      RESB  1     ;Se va a guadar el numero 16 para usarlo en contador y offset en ASCII_To_Bits
guardar_numeros:    RESB  4     ;Se guardan 16 bits para guardar los numeros

x_actual:           RESB  2     ;Para guardar el resultado de ASCII_To_Num
y_actual:           RESB  2     ;Para guardar el resultado de la reverberacion

operandoA:          RESD  1     ;22 Bits para el operando A
operandoB:          RESD  1     ;22 Bits para el operando B

op_neg:             RESB  1     ;Una flag para saber si el resultado de la operacion debe ser negativo

m1:                 RESD  1     ;Guarda la primera multiplicacion de medium
m2:                 RESD  1     ;Guarda la segunda multiplicacion de medium

high:               RESD  1     ;Se reservan 16 bits para el resultado high de la multiplicacion
medium:             RESD  1     ;Se reservan 32 bits para el resultado de medium de la multiplicacion
low:                RESD  1     ;Se reservan 16 bits para el resultado de low de la multiplicacion

multi1:             RESD  1     ;Se guarda la primera parte de la suma del algoritmo

resultado_multiplicacion: RESD 1;16 Bits para el resultado final de la multiplicacion

buffer:             RESW  2205  ;Se reserva la memoria para el buffer
contador_buffer:    RESW  1     ;Se reserva la memoria para el contador del buffer
buffer_respaldo:    RESW  2205  ;Se usa para siempre tener respaldada del inicio del buffer
contador_k:         RESB  1     ;Es el contador para saber cada cuanto reiniciar el buffer

mulf1:              RESD  1     ;Se reserva memoria para la primera parte de la formula final
mulf2:              RESD  1     ;Se guarda memoria para la segunda parte de la formula final
mulf3:              RESD  1     ;Se guarda memoria para la tercera parte de la formula final

section .text
global CMAIN
CMAIN:    mov ebp, esp; for correct debugging


;Inicializacion de variables

    mov word[puntero_lectura], 0 ;Se inicializa el lugar de lectura del puntero (inicio)
    mov byte[contador_bits], 16  ;Se inicializa el valor del contador de bits para ASCII_To_Bits
    mov     byte[op_neg], 0         ;Se inicializa la flag del signo del resultado
    mov     word[contador_buffer], 0;Se inicializa el contador del buffer
    call    Abrir_archivo        ;Se llama a la funcion
    call    Crear_archivo        ;Se llama a la funcion
    call    Main_loop            ;Se llama a la funcion
    
    

    
        
            
;Bloque principal
Main_loop:
      call    Leer_archivo         ;Se llama a la funcion
      call    ASCII_To_Num         ;Se llama a la conversion
;Esto va en reverberacion
      call    Reverberacion
;*************************************************************************************************************************
      call    Num_To_ASCII         ;Se llama la funcion
      call    Escritura_archivo    ;Se llama a la funcion
      jmp     Main_loop            ;Se mantiene el ciclo




;Loop que pasa de ASCII a numero con el fin de poder obtener los datos correctos de la lista
;PASOS

;Se lee el valor
;Se le resta el ASCII para obtener el valor real
;Se le realiza un shift a la posicion real del numero (donde va en bits. Primero a la pos 16, segundo 15 etc)
;Lo suma al registro donde se este guardando el numero completo
;Shift logico
ASCII_To_Num:
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov     eax, 0              ;Se limpia el valor de eax
    mov     ebx, 0              ;Se limpia el valor de ecx
    mov     edx, 0             
    mov     eax, 0              ;Se carga la posicion de memoria de x_actual a eax
    
    call ASCII_To_Num_Aux       ;Se llama la funcion auxiliar que realiza el ciclo
    
    mov  word[x_actual], ax     ;Se guarda el numero final en la posicion temporal x_actual
    
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    ret
    
    
    
ASCII_To_Num_Aux:
    mov edx, 0                  ;Se limpia edx
    mov ecx, valor_numero       ;Se carga el archivo ya leido en el registro ecx. Posicion de memoria
    add ecx, ebx                ;Se incrementa el puntero para decirle donde debe leer
    mov dl, byte[ecx]           ;Se carga el valor de la posicion de memoria actual a bl
    mov cl, 15                  ;Contador para manejar lo shifts
    sub dl,  48                 ;Se le resta 48 en ASCII para sacar el verdadero valor del binario (0 o 1)
    sub ecx, ebx                ;Se maneja el contador de shifts al restarse en ecx
    shl edx, cl                 ;Se shiftea el puntero para colocar el numero donde corresponde
    inc ecx                     ;Se aumenta ecx en 1 para el subs de edx
    add eax, edx                ;Se guarda el valor en la lista donde corresponde
    inc ebx                     ;Se va a la siguiente posicion de memoria de valor_numero
    cmp ebx, 15                 ;Se hace el comper a ver si se termia el loop
    jz salir_ciclo              ;Se sale del ciclo
    jmp ASCII_To_Num_Aux        ;Se sigue el ciclo
    



;Para el valor de X_actual a ASCII para escribirlo en el nuevo documento
;Agarrar el numero, hacerle division entre dos y al resultado sumarle 48, luego guardarlo en el y_actual
Num_To_ASCII:
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov     eax, 0              ;Se limpia el valor de eax
    mov     ebx, 16            ;Se limpia el valor de ecx
    mov     edx, 0             
    mov     eax, 0              ;Se carga la posicion de memoria de x_actual a eax
    mov     eax, [y_actual]     ;Se mueve la  de memoria ecx
    
    call Num_To_ASCII_aux       ;Se llama la funcion auxiliar que realiza el ciclo
    
    
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    ret



Num_To_ASCII_aux:
    sub     ebx, 1              ;Se resta el contador de lectura y el contador para terminar el ciclo
    mov     edx, 0              ;Se limpia edx
    mov     ecx, valor_a_escribir;Se mueve el lugar en donde va a escribir
    add     ecx, ebx            ;Se incrementa el puntero para decirle donde debe escribir 
     
    push    ebx 
    mov     ebx, 0              ;Se limpia ebx
    mov     edx, 0              ;Se limpia edx para la division
    mov     ebx, 2              ;Se mueve el divisor a eax
    
    
    div     ebx                 ;Se hace la division ebx/eax
    pop     ebx                 ;Se restaura ebx
    
    add     edx, 48             ;Se le suma 48 al residuo, asi se obtiene 49 = 1 o 48 = 0 
    mov     byte[ecx],dl        ;Se guarda el valor en la posicion de memoria donde se va a escribir
    
    
    cmp     ebx, 0              ;Se revisa si ya termino de leer el valor
    jz      salir_ciclo         ;Se retorna al loop principal
    jmp     Num_To_ASCII_aux    ;Se sigue el ciclo
    
    
;Funcion que realiza la multiplicacion. Pasos:
;No se pueden hacer multiplicaciones a numeros que tengan complemento a dos
;Se tiene que manejar multiplicacion con numeros negativos, positivos, de todo con todo. Saber como queda el signo.
;Se tiene que separar en l y h, ya que son 16 bits 8 y 8. Se meten en un registor y l llama los primeros 8 y h los segundos 8
;Se quitan los complementos, se realiza la operacion, se tiene que ver si se debe cambiar de signo al resultado final (mult * -1)
;El resultado es el resultado de la multiplicacion
Multiplicacion:

;Parte principal de la funcion
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov    edx,0                ;Se le hace push al registro
    mov    ecx,0                ;Se le hace push al registro
    mov    ebx,0                ;Se le hace push al registro
    mov    eax,0                ;Se le hace push al registro
 
;Primera parte del algoritmo, revision del bit mas significativo y si se le debe quitar el complemento 2 o no      
    mov    eax, [operandoA]      ;Se carga el valor del y_actual que se va a multiplicar con punto fijo
    mov    ecx, eax             ;Respaldo el valor de y_actual para despues de haberlo destruido
    mov    ebx, 16
    call   Revisar_msb          ;Se revisa si se le tiene que quitar el complemento 2 al numero o se puede seguir normal
    mov    dword[operandoA], ecx;Se retorna el, ya sea con complemento 2 o sin el, dependiendo del caso
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    
    mov    eax, [operandoB]     ;Se carga el valor del y_actual que se va a multiplicar con punto fijo
    mov    ecx, eax             ;Respaldo el valor de y_actual para despues de haberlo destruido
    mov    ebx, 16
    call   Revisar_msb          ;Se revisa si se le tiene que quitar el complemento 2 al numero o se puede seguir normal
    mov    dword[operandoB], ecx;Se retorna el, ya sea con complemento 2 o sin el, dependiendo del caso
    
    
    
;***********************************************************************************************

;Segunda parte del algoritmo, realiza la multiplicacion y el algoritmo de puntos flotantes.
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov    edx,0                ;Se le hace push al registro
    mov    ecx,0                ;Se le hace push al registro
    mov    ebx,0                ;Se le hace push al registro
    mov    eax,0                ;Se le hace push al registro
    
    mov    edx, [operandoA]     ;Se prepara el operandoA a multiplicar. En este caso dh = a y dl = b
    mov    ecx, [operandoB]     ;Se prepara el operandoB a multiplicar. En este caso ch = c y cl = d
    
    call   Manejar_multi        ;Se realiza el algoritmo de multiplicacion
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    
;Tercera parte del algoritmos, se verifica si se le debe cambiar el signo final al resultado
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov    edx,0                ;Se le hace push al registro
    mov    ecx,0                ;Se le hace push al registro
    mov    ebx,0                ;Se le hace push al registro
    mov    eax,0                ;Se le hace push al registro
    
    mov    cl, byte[op_neg]     ;Se carga el flag a cl
    mov    eax, [resultado_multiplicacion];
    call   Revisar_signo        ;Se revisa si se le debe cambiar el signo al resultado final
    mov    dword[resultado_multiplicacion], eax; Se restaura con el valor final, ya sea si se fue a comp2 o no
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    
    push   ecx                  ;Se guarda el valor del registro
    mov    ecx, 0               ;Se limpia el registro
    mov    byte[op_neg], 0      ;Se reinicia el contador con el registro limpio
    pop    ecx                  ;Se saca ecx del stack
    ret
;*******************************************************************************************************
    
    
    
    
    
    
    
 Manejar_multi:
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  bl, dh                 ;Se mueven 8 bits a bl, los cuales representan A en el algoritmo
    mov  eax, 0                 ;Se limpia ecx
    mov  al, ch                 ;Se mueven 8 bits al ah, los cuales representan a C en el algoritmo
    push edx                    ;Para guardar el edx
    mul  ebx                    ;Se realiza la multiplicacion de eax y ebx, pero con solo ah y bh
    pop  edx                    ;Se recupera edx
    mov  dword[high], eax         ;Se guarda el high de la multiplicacion
    
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  bl, dl                 ;Se mueven 8 bits a bl, los cuales representan a B en el algoritmo
    mov  eax, 0                 ;Se limpia ecx
    mov  al, cl                 ;Se mueven 8 bits al al, los cuales representan a D en el algoritmo
    push edx                    ;Para guardar el edx
    mul  ebx                    ;Se realiza la multiplicacion de eax y ebx, pero con solo ah y bh
    pop  edx                    ;Se recupera edx
    mov  dword[low], eax          ;Se guarda el resultado de low
    
    mov  ebx, 0                 ;Se limpia ebx
    mov  bl, dh                 ;Se mueven 8 bits a bl, los cuales representan A en el algoritmo
    mov  eax, 0                 ;Se limpia ecx
    mov  al, cl                 ;Se mueven 8 bits al al, los cuales representan a D en el algoritmo
    push edx                    ;Para guardar el edx
    mul  ebx                    ;Se realiza la multiplicacion de eax y ebx
    pop  edx                    ;Se recupera edx
    mov  dword[m1], eax           ;Se guarda el resultado de m1, la primera parte de medium
    
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  bl, dl                 ;Se mueven 8 bits a bl, los cuales representan a B en el algoritmo
    mov  eax, 0                 ;Se limpia ecx
    mov  al, ch                 ;Se mueven 8 bits al ah, los cuales representan a C en el algoritmo
    push edx                    ;Para guardar el edx
    mul  ebx                    ;Se realiza la multiplicacion de eax y ebx.
    pop  edx                    ;Se recupera edx
    mov  dword[m2], eax           ;Se guarda el resultado de m2, la primera parte de medium
    
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  eax, 0                 ;Se limpia ecx
    mov  bx, [m1]               ;Se mueve la primera parte de medium a bx
    mov  ax, [m2]               ;Se mueve la segunda parte de medium a ax 
    add  ebx, eax               ;Se suma y se obtiene medium completo
    mov  dword[medium], ebx       ;Se guarda el medium completo en la variable
    
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  ecx, 0                 ;Se limpia el registro ebx
    mov  ebx, [high]            ;Se guarda el valor de high en ebx
    mov  cl,  8                 ;Se guarda 8 en cl para hacer el shift posteriormente
    shl  ebx, cl                ;Se realiza el shift correspondiente al algoritmo
    mov  dword[high], ebx         ;Se guarda el valor de high ahora con shift
    
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  ecx, 0                 ;Se kimpia el registro ecx
    mov  ebx, [low]             ;Se guarda el valor de low en ebx
    mov  cl,  8                 ;Se guarda 8 en cl para hacer el shift posteriormente
    shr  ebx, cl                ;Se guarda realiza el shift correspondiente al algoritmo
    mov  dword[low], ebx          ;Se guarda el valor de high ahora con shift 
    
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  ecx, 0                 ;Se limpia el registro ecx
    mov  ebx, [low]             ;Se guarda el valor de low en ebx
    mov  ecx, [high]            ;Se guarda el valor de high en ecx
    add  ebx, ecx               ;Se suman low y high
    mov  dword[multi1], ebx       ;Se guarda el resultado de high y low
    mov  ebx, 0                 ;Se limpia el registro ebx
    mov  ecx, 0                 ;Se kimpia el registro ecx
    mov  ebx, [medium]          ;Se carga el resultado de medium en ebx
    mov  ecx, [multi1]          ;Se carga lo que habia dado high+low
    add  ebx, ecx               ;Se suma (high+low) + medium
    mov  dword[resultado_multiplicacion], ebx; Se guarda el resultado final de la multiplicacion en su variable
    ret
    
    

    
    
    
    
    

Revisar_msb:
    sub     ebx, 1              ;Se resta el contador de lectura y el contador para terminar el ciclo
    mov     edx, 0              ;Se limpia edx
    push    ebx                 ;Se guarda ebx en el stack
    mov     ebx, 0              ;Se limpia ebx
    mov     edx, 0              ;Se limpia edx para la division
    mov     ebx, 2              ;Se mueve el divisor a eax
    
    div     ebx                 ;Se hace la division ebx/eax
    pop     ebx                 ;Se saca ebx del stack para recuperar el contador
    cmp     ebx, 1              ;Se revisa si ya se llego al bit 16
    jz      Comparar_msb        ;Se va a analizar si el bit 16 es 1
    jmp     Revisar_msb         ;Se sigue el ciclo hasta llegar al bit 16

Comparar_msb:
    cmp     eax,1
    jz      Quitar_complemento2 ;Se detecto un numero de complemento 2, por lo tando se debe ir a quitar dicho estado
    ret                         ;El numero analizado no tiene complemento 2, se vuelve a la funcion principal       
    
    
;Le quita el complemento a los operandos    
Quitar_complemento2:
    XOR    ecx, 0xffff          ;Se hace un XOR de FFFF hexa = 1111 1111 1111 1111 binario
    add    ecx, 1               ;Se le suma 1 para terminar el complemento 2
    push   ecx                  ;Se pushea ecx
    mov    ecx, 0               ;Se limpia ecx
    mov    ecx, [op_neg]        ;Se carga la flag a ecx
    xor    ecx, 1               ;Se le hace xor a ecx con 1 para alterar su valor
    mov    byte[op_neg], cl     ;Se actualiza el valor de la flag
    pop    ecx                  ;Se restaura ecx
    ret                         ;Vuelve a la call de la llamada inicial
    
Revisar_signo:   
    cmp   ecx, 1                ;Se revisa la flag de signo a ver si se debe cambiar el signo al resultado final
    jz    Quita_complemento2F   ;Se va a cambiar el resultado
    ret                         ;No se tuvo que aplicar el cambio
    
    
    
    
Quita_complemento2F:
    XOR    eax, 0xffff          ;Se hace un XOR de FFFF hexa = 1111 1111 1111 1111 binario
    add    eax, 1               ;Se le suma 1 para terminar el complemento 2
    ret
    


;Se recorre con el puntero los primeros 4410 bytes (2205 words)
;Se le hace lo que se le tenga que hacer al valor para luego actualizarlo en la posicion de donde se saco
;Se sigue hasta llegar a k
;Al llegar al 4410 se reinicia el puntero a 0
;Se repite el ciclo hasta el final de la lista
Buffer:
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov     edx,0               ;Se le hace push al registro
    mov     ecx,0               ;Se le hace push al registro
    mov     ebx,0               ;Se le hace push al registro
    mov     eax,0               ;Se le hace push al registro
    
    mov     cx, word[contador_buffer];Se carga el contador que me dice por donde va guardando el buffer
    mov     eax, buffer           ;Se carga la etiqueta buffer
    add     eax, ecx              ;Se le dice a donde se va a guardar dentro del buffer
    mov     bx, word[x_actual]    ;Se guarda y actual en la posicion del buffer correspondiente
    mov     word[eax], bx         ;Se guarda bx en la direccion de la lista n, ya que eax tiene la direccion
    add     ecx, 2                ;Se le suma 2 al contador de posiciones en el buffer
    mov     word[contador_buffer], cx;Se actualiza el contador
    
    
    cmp     ecx, 4410             ;Se compara si ya se debe reiniciar la posicion del buffer
    jz      Buffer_reset          ;Se va a reiniciar el buffer
    
    pop     eax                  ;Se le hace pop al registro
    pop     ebx                  ;Se le hace pop al registro
    pop     ecx                  ;Se le hace pop al registro
    pop     edx                  ;Se le hace pop al registro
    
    ret                           ;Se retorna    
    

Buffer_reset:
    mov     ecx, 0              ;Se mueve el 0 a ecx
    mov     word[contador_buffer], cx;Se reinicia el contador
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    ret

    
;PARA ESTE ARCHIVO ESTA FUNCION SE ENCARGA DE *QUITAR* LA REVERBERACION
Reverberacion:
;Primera parte de la multiplicacion para x_actual
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov     edx,0               ;Se limpia el registro
    mov     ecx,0               ;Se limpia el registro
    mov     ebx,0               ;Se limpia el registro
    mov     eax,0               ;Se limpia el registro

    
    mov     ax, word[x_actual]     ;Se carga el primer operando en eax
    mov     bx, word[uno_entreUno_menosAlfa]  ;Se carga el segundo operando a ebx, la direccion de memoria de la variable
    
    mov     dword[operandoA], eax ;Se cargan los valoresn para la multiplicacion
    mov     dword[operandoB], ebx ;Se cargan los valores para la multiplicacion
    
    mov     edx,0               ;Se limpia el registro
    mov     ecx,0               ;Se limpia el registro
    mov     ebx,0               ;Se limpia el registro
    mov     eax,0               ;Se limpia el registro
    
    call    Multiplicacion      ;Se llama al algoritmo de multiplicacion
    mov     ecx, dword[resultado_multiplicacion] ;Se carga lo que sea que diera la multiplicacion a ecx
    mov     dword[mulf1], ecx   ;1/(1-a)*x(n) es este resultado
;*************************************************************************************************************
;Parte 2 de la multiplicacion
    
    mov     edx,0               ;Se limpia el registro
    mov     ecx,0               ;Se limpia el registro
    mov     ebx,0               ;Se limpia el registro
    mov     eax,0               ;Se limpia el registro

    
    mov     cx, word[contador_buffer];Se carga el contador que me dice por donde va guardando el buffer
    mov     eax, buffer           ;Se carga la etiqueta buffer
    add     eax, ecx              ;Se le dice a donde se va a guardar dentro del buffe   
    mov     bx, word[alfa]  ;Se carga el segundo operando a ebx, la direccion de memoria de la variable
    
    mov     ecx, 0
    mov     cx, word[eax] ;Se cargan los valoresn para la multiplicacion
    mov     dword[operandoA], ecx
    mov     dword[operandoB], ebx ;Se cargan los valores para la multiplicacion
    
    mov     edx,0               ;Se limpia el registro
    mov     ecx,0               ;Se limpia el registro
    mov     ebx,0               ;Se limpia el registro
    mov     eax,0               ;Se limpia el registro
    
    call    Multiplicacion
    
    mov     ecx, dword[resultado_multiplicacion] ;Se carga lo que sea que diera la multiplicacion a ecx
    mov     dword[mulf2], ecx   ;a*x(n-k) es este resultado
    
;*******************************************************************************************************************8
;Tercera parte de la multiplicacion para X_actual
   mov     edx,0               ;Se limpia el registro
   mov     ecx,0               ;Se limpia el registro
   mov     ebx,0               ;Se limpia el registro
   mov     eax,0               ;Se limpia el registro
   
   mov     eax, dword[mulf2]     ;Se carga el primer operando en eax
   mov     bx, word[uno_entreUno_menosAlfa]  ;Se carga el segundo operando a ebx, la direccion de memoria de la variable
    
   mov     dword[operandoA], eax ;Se cargan los valoresn para la multiplicacion
   mov     dword[operandoB], ebx ;Se cargan los valores para la multiplicacion
   
   mov     edx,0               ;Se limpia el registro
   mov     ecx,0               ;Se limpia el registro
   mov     ebx,0               ;Se limpia el registro
   mov     eax,0               ;Se limpia el registro

   call    Multiplicacion
   
   mov     ecx, dword[resultado_multiplicacion] ;Se carga lo que sea que diera la multiplicacion a ecx
   mov     dword[mulf3], ecx   ;a*x(n-k) es este resultado

    mov    eax, 0
    mov    edx, dword[mulf1]       ;Se carga mulf1
    mov    eax, dword[mulf3]       ;Se carga mulf2
    call   Quita_complemento2F ;Se pone en negativo a mulf3
    
    add    edx, eax           ;Se resta edx con ebx, los cuales son mulf1 mulf3
    mov    word[y_actual], dx ;Se guarda la salida
    call   Buffer             ;Se llama al buffer
    
    pop     eax                  ;Se le hace pop al registro
    pop     ebx                  ;Se le hace pop al registro
    pop     ecx                  ;Se le hace pop al registro
    pop     edx                  ;Se le hace pop al registro
    
    
    ret
    
    
    
    
    
    
    
   
    



                        
        
    
;Se abre un archivo(entrada)
Abrir_archivo:
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro                              
    push    eax                 ;Se le hace push al registro
    
    mov     ecx, 0              ; Permiso para leer
    mov     ebx, entrada_a_leer ; Se abre el archivo para leer
    mov     eax, 5              ; Me devuelve el decriptor para la entrada.Ejecuta la op 5 (open file)
    int     80h                 ; llamada al kernel
    mov     [decriptor_entrada], eax ;Se guarda el decriptor de entrada 
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    ret                         ;Se vuelve al call
 
;Se crea un archivo(salida)
Crear_archivo:
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    mov     ecx, 0777o          ;Permiso de leer, escribir y ejecutar. Sale un decriptor
                                ;el decriptor sabe cual es el que sabe a que archivo voy a tocar
    mov     ebx, archivo_salida       
    mov     eax, 8              ;Haga system_create al archivo. Crea decriptor
    int     80h                 ;Llamada al kernel
    mov     [decriptor_salida], eax ;Se mueve el decriptor a la variable
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    ret                         ;Se vuelve al call

   


;Funcion para leer(entrada)
;EL bit 17 es \n, los primeros 16 son los que me interesan
Leer_archivo:
    
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov     edx,0               ;Se limpia el registro
    mov     ecx,0               ;Se limpia el registro
    mov     ebx,0               ;Se limpia el registro
    mov     eax,0               ;Se limpia el registro
    
    
    
;Bloque de codigo de puntero(mueve el puntero el archivo, tanto lectura como escritura)
    mov     edx, 0              ; Le dice donde se ubica el puntero en el archivo al comenzar la lectura
    mov     ecx, dword[puntero_lectura] ; Se mueve el offset del puntero a ecx
    mov     ebx, [decriptor_entrada]; Se mueve lo que tiene el decriptor_entrada a ebx
    mov     eax, 19             ; invoque el kernel el 19
    int     80h                 ; Se llama el kernel
    
    
    mov     edx, 16             ; Cantidad de bytes a leer (debido a que lo guarde en binario)
    mov     ecx, valor_numero   ; Aqui se guarda lo que se lea en esta funcion
    mov     ebx, [decriptor_entrada] ;Se guarda lo que esta en la memoria del decriptor en ebx
    mov     eax, 3              ; Invoca el sistema read
    int     80h                 ; call the kernel
    
    mov     edx, dword[puntero_lectura];Se le asigna a edx el valor de puntero_lectura(0 inicialmente)
    add     edx, 17             ;Se le suma 17 al puntero, con el fin de ir recorriedo solo los bits deseados
    mov     dword[puntero_lectura],edx;Se actualiza el valor del puntero
    
    cmp     eax, 0
    jz      terminar
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    ret


 
;Se escribe en el archivo(salida)
Escritura_archivo:
;Este bloque escribe el dato
    push    edx                 ;Se le hace push al registro
    push    ecx                 ;Se le hace push al registro
    push    ebx                 ;Se le hace push al registro
    push    eax                 ;Se le hace push al registro
    
    mov     edx, 16             ; Voy a escribir la salida en binarios
    mov     ecx, valor_a_escribir;Le dice el valor que va a escribir en salida. La direccion
    mov     ebx, [decriptor_salida]; Se le dice en donde va a escribir gracias al descriptor
    mov     eax, 4              ; Sys_write
    int     80h    

;Este bloque hace la separacion de los datos \n
    mov     edx, 1             ; Voy a escribir la salida en binarios
    mov     ecx, salto_linea   ;Le dice el valor que va a saltar a la otra salida. La direccion
    mov     ebx, [decriptor_salida]; Se le dice en donde va a escribir gracias al descriptor
    mov     eax, 4              ;Sys_write
    int     80h 
    
    pop     eax                 ;Se le hace pop al registro
    pop     ebx                 ;Se le hace pop al registro
    pop     ecx                 ;Se le hace pop al registro
    pop     edx                 ;Se le hace pop al registro
    ret        
salir_ciclo:
    ret
terminar: 
    call    quit                ; call our quit function