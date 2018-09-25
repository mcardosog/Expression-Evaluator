; multi-segment executable file template.

data segment
    ; add your data here!  
    
    
    pkey db "     ***FIN***$" 
    saludo db "     -= EVALUADOR 1.0 =-$" 
    
    ;ERRORES  
    error1 db "ERROR: NOMBRE DE VARIABLE O FUNCION INCORRECTO$" 
    error2 db "ERROR: ENTRADA INCORRECTA$"
    error3 db "ERROR: ESPACIO INSUFICIENTE$"
    error4 db "ERROR: VARIABLE O FUNCION EXISTENTE$"
    error5 db "ERROR: NOMBRE DE VARIABLE O ENTRADA INCORRECTA$"
    error6 db "ERROR: EXPRESION MAL BALANCEADA$"
    error7 db "ERROR: NO SE PUDO EVALUAR LA EXPRESION CORRECTAMENTE$"
    error8 db "ERROR: VALOR NUMERICO MAXIMO EXCEDIDO$" 
    error9 db "ERROR: OPERACION INVALIDA$" 
    error10 db "ERROR: DIVISION POR CERO$"
    error11 db "ERROR: VARIABLE O FUNCION NO DECLARADA$"
    error12 db "ERROR: DECLARACION INCORRECTA$"
    error13 db "ERROR: RAIZ COMPLEJA NO IMPLEMENTADA$"
    error14 db "ERROR: LOS DATOS DE LA SUMATORIA SON INCORRECTOS$"
    error15 db "ERROR: OPERACION SOLO DEFINIDA PARA NUMEROS POSITIVOS$" 
    
    
    imprime db 6 dup(?),'$' 
    t_unset db "unset$"        
    t_print db "print$"         
    t_list db "list$"
    
    
    calculo dw ?
    almacen db 512 dup(?)    
    read db 255,255 dup(?)                        
    nombreVar db 255 dup(?)
    
    OPERACION dw 512 dup(?);ARRAY QUE SE LE PASA AL SY
    MEMORIA dw 512 dup(?)  ;MEMORIA GENERAL DEL EVALUADOR. FORMATO = [#LengthNombre,"Nombre"+'=',#Valor]
    IDX_MEM dw 0           ;INDICE DE LA MEMORIA    
    
    COLA_SY dw 512 dup(0) ;COLA DEL SHUTING YARD
    IDX_COLA dw 0         ;INDICE DE LA COLA
    PILA_SY dw 512 dup(0) ;PILA DEL SHUTING YARD
    IDX_PILA dw 0         ;INDICE DE LA COLA DEL SHUTING YARD    
    PILA_NPI dw 512 dup(0);PILA PARA HACER LA EVALUACION (NOTACION POLACA INVERSA)
    
    
    PRIORIDAD db 0,0,1,1,1,-1,-1,2,4,4,4,3,2,0,0,4,4,5
    OPERADORES db "+-*/%()^",170,210,"><:|&!~@"
    
    
    
    
    
    
;     COSAS DEL EMU
;/////////////////////////// 
ends                      ;/
                          ;/
stack segment             ;/
    dw   128  dup(0)      ;/
ends                      ;/
                          ;/
code segment              ;/
start:                    ;/
; set segment registers:  ;/
    mov ax, data          ;/
    mov ds, ax            ;/
    mov es, ax            ;/
                          ;/
    ; add your code here  ;/
;/////////////////////////// 


    
    ;**** PRINCIPAL **** 
    
    mov dx, offset saludo
    mov ah,9
    int 21h  
    ;call CAMBIO_LINEA  

    
LEER: 
     call CAMBIO_LINEA
     mov ah,2
     mov dl, '>'
     int 21h 
     mov dl, ' '
     int 21h
     
     mov dx, offset read
     mov ah,0ah 
     int 21h
        
     call COMENTARIOS
     call ARITMETICAS_AVANZADAS
                    
     cmp read[1],0
     je FIN_PRINC  
     
     call INDENTIFICA_OP        
     ;PROBANDO ASIGNACION ----ok sin el ShutY 
     ;call ASIGNACION
     
     jmp LEER
     
FIN_PRINC: 
     call CAMBIO_LINEA
     call CAMBIO_LINEA       
    
    ;**** /PRINCIPAL ****
    
                    
                    
;                   COSAS DEL EMU
;////////////////////////////////////////////////    
    lea dx, pkey                               ;/
    mov ah, 9                                  ;/
    int 21h        ; output string at ds:dx    ;/
                                               ;/
    ; wait for any key....                     ;/
    mov ah, 1                                  ;/
    int 21h                                    ;/
                                               ;/
    mov ax, 4c00h ; exit to operating system.  ;/
    int 21h                                    ;/
ends                                           ;/
;////////////////////////////////////////////////
                                           
  

;-------------------------------------------
;         ___ ____ ____  ___   ____  ___    |
;  |\  /| |     |  |   | |  \  |   | |      |
;  | \/ | |__   |  |   | |   | |   | |__    |
;  |    | |     |  |   | |   | |   |    |   |
;  |    | |__   |  |___| |__/  |___| ___|   |
;-------------------------------------------
      
      
;        DESCRIPCION                                           
;////////////////////////////////                                           
;                               /
;e_MET = error del METODO       /              
;f_MET = fin del METODO         /                  
;c_MET = ciclo del METODO       /             
;a_MET = aux del METODO         /  
;i_MET = inicio del METODO      /
;                               / 
;////////////////////////////////
                                      
                                              
;   **** ASIGNACION ****                      
;Agrega una variable, a MEMORIA

ASIGNACION proc

mov si,2

i_ASIG:          
    cmp read[si],32 ;ES ESPACIO
    je a2_ASIG  
    
    cmp read[si],95 ;ES _
    je a0_ASIG 
    
    mov bh,0
    mov bl,read[si]
    push bx
    
    call ES_LETRA_MAY  ;A-Z
    cmp al,1
    je a0_ASIG     
 
    
    push bx
    call ES_LETRA_MIN   ;a-z
    cmp al,1
    je a0_ASIG
    
    
            
    jmp e5_ASIG
    

a2_ASIG:;1er CARACTER ES ESPACIO
    inc si
    jmp i_ASIG

    
a0_ASIG:;PASO AL CICLO
    mov di,0       
    mov al,read[si]
    mov nombreVar[di], al
    inc di
    
c_ASIG:;CICLO#1 
    inc si    
    cmp read[si], 32 ;ESPACIO
    je c_ASIG
    cmp read[si], 61 ;=
    je  a3_ASIG  
    cmp read[si],95 ;REVISA _
    je a_ASIG
    cmp read[si], 13 ;FIN
    je e2_ASIG 
    
    
    mov bh,0
    mov bl, read[si]
    
    push bx     
    call ES_NUMERO
    cmp al,1
    je a_ASIG
    
    push bx
    call ES_LETRA_MAY
    cmp al,1
    je a_ASIG 
    
    push bx
    call ES_LETRA_MIN
    cmp al,1
    je a_ASIG    
    
    jmp e_ASIG   ;ES UN CARACTER INCORRECTO
    
    
a_ASIG:     ;nombreVar = new caracter
    mov al,read[si]
    mov nombreVar[di], al
    inc di
    jmp c_ASIG 
    
a3_ASIG:    ;agrego =
    mov al,read[si]
    mov nombreVar[di], al
    inc di
    jmp a1_ASIG ;NOMBRE COMPLETO,VERIFICAR + CONDICIONES    
  
e_ASIG:    ;E=NOMBRE VAR INCORRECTA      
    mov bx, offset error1 
    push bx
    call IMPRIME_ERROR      
    jmp f_ASIG  
    
e2_ASIG:   ;E=ENTRADA INCORRECTA      
    mov bx, offset error2
    push bx
    call IMPRIME_ERROR       
    jmp f_ASIG
    
e3_ASIG:   ;E=ESPACIO INSUFICIENTE    
    mov bx, offset error3
    push bx
    call IMPRIME_ERROR      
    jmp f_ASIG 

e4_ASIG:     ;E=YA EXISTE UNA VARIABLE CON ESE NOMRBE
    mov bx, offset error4 
    push bx               
    call IMPRIME_ERROR      
    jmp f_ASIG
    
e5_ASIG:
    mov bx, offset error5
    push bx
    call IMPRIME_ERROR
    jmp f_ASIG 
    
e6_ASIG:
    mov bx, offset error12
    push bx
    call IMPRIME_ERROR
    pop di
    jmp f_ASIG  
    
a1_ASIG:    ;REVISAR SI ME QUEDA ESPACIO EN LA MEMORIA                       
    mov ax,IDX_MEM 
    add ax, di
    add ax, di
    add ax,4
        
    cmp ax, 512
    ja e3_ASIG
    
    ;VER SI EXISTE LA VARIABLE
    push si
    push di
    call EXISTE_VARIABLE                           
    pop di
    pop si
    
    cmp al,1
    je e4_ASIG
    
    push di
    call RELLENA_VALOR ;RELLENA DESPUES DEL ESPACIO
        cmp al, 0
        je e6_ASIG
    pop di
    
    mov cx,di  ;EN ESTE PUNTO YA SE QUE CAB EN MEMORIA, TAMBIEN VER LO QUE RETORNE EL SHUNTING YARD 
        
     
    
    mov si, offset MEMORIA
    mov si, IDX_MEM    
    mov MEMORIA[si],di ;MEMORIA[IDX_MEM]=LENGTH
    add si, 2
    mov di, 0

c2_ASIG:;CICLO#2
    mov al, nombreVar[di]
    cbw
    mov MEMORIA[si], ax
    add si, 2
    inc di
    loop c2_ASIG
    
    
    
    ;JEJEJE /***************************************************//////
    push si
    call Traductor
    pop si
    cmp bx, 0
    je p_ASIG
    
    mov bx, PILA_NPI[0]
    mov MEMORIA[si], bx        
    ;AKI PONER LO QUE RETORNA EL SHUTING YARD 
    add si, 2
    mov IDX_MEM, si
    call LIMPIA
    jmp f_ASIG

p_ASIG: 
    call DESHACER 
    call LIMPIA 
    

        
f_ASIG:
    ret
    
ASIGNACION endp 

;   **** /ASIGNACION ****  


DESHACER proc
    mov si, IDX_MEM
    mov cx, MEMORIA[si]
    inc cx
    
c_DESHACER:
    mov dx, 0
    mov MEMORIA[si], dx
    add si, 2
    loop c_DESHACER
    
    
    ret    
    
DESHACER endp



;   **** RELLENA VALOR ****
;CUANDO SE HACE UNA ASIGNACION RELLENA DESPUES DEL ESPACIO


RELLENA_VALOR proc
    push bp
    mov bp, sp
    mov cx, di
    mov al, 1
    
    inc si

c_RELL_V:
    
    mov bl, read[si]
    cmp bl, 13
    je f_RELL_V
    
    cmp bl, 32
    je a_RELL_V 
    
    cmp bl, 0
    je f_RELL_V
    
    mov nombreVar[di], bl
    inc di
    inc si
    
    jmp c_RELL_V
    
    
    
a_RELL_V:   ;SI ES ESPACIO EN BLANCO INCREMENTO EL SI
    
    inc si
    jmp c_RELL_V 
    

f_RELL_V:
    cmp cx, di
    jne i_F_RELL_V
    mov al, 0
    
    i_f_RELL_V:
    mov nombreVar[di], '$'
    pop bp
    ret     
    
RELLENA_VALOR endp

;   **** /RELLENA VALOR ****




;   **** EXISTE LA VARIABLE ****------------------------------------------
EXISTE_VARIABLE proc                                                     ;|
    mov bx, di ;BX=LenghtNombre                                          ;|
                                                                         ;|
    mov di, offset nombreVar                                             ;|
                                                                         ;|
    mov si, offset MEMORIA                                               ;|
    mov si, 0                                                            ;|
                                                                         ;|
c_EXIS_V:                                                                ;|
    cmp si, IDX_MEM                                                      ;|
    jae a_EXIS_V
     
    mov di,0                                                             ;|
    mov al,0                                                             ;|
                                                                         ;|
    mov cx, MEMORIA[si]                                                  ;|             
    cmp cx, bx                                                           ;|
    je a1_EXIS_V                                                         ;|
                                                                         ;|
i_c_EXIS_V:                                                              ;|
    cmp al, 1                                                            ;|
    je a0_EXIS_V                                                         ;|
                                                                         ;|
    add si, cx                                                           ;|
    add si, cx                                                           ;|
                                                                         ;|
    add si, 4                                                            ;|  
                                                                         ;|
                                                                         ;|
;    cmp si, IDX_MEM                                                      ;|
;    jae a_EXIS_V                                                         ;|
    jmp c_EXIS_V                                                         ;|
                                                                         ;|
                                                                         ;|
a1_EXIS_V:   ;SI LOS DOS TIENEN EL MISMO LENGTH                          ;|
    call IDENTICOS                                                       ;|
    jmp i_c_EXIS_V                                                       ;|
                                                                         ;|
a0_EXIS_V:    ;LA VARIABLE EXISTE EN MI MEMORIA                          ;|
    mov al, 1                                                            ;|
    jmp f_EXIS_V                                                         ;|
                                                                         ;|
                                                                         ;|
a_EXIS_V:     ;SI ME PASO DEL INDICE DEL ARRAY ES QUE NO LO ENCONTRE     ;|
    mov al,0                                                             ;|
                                                                         ;|
                                                                         ;|
f_EXIS_V:                                                                ;|
    ret                                                                  ;|
                                                                         ;|
EXISTE_VARIABLE endp                                                     ;|
                                                                         ;|
;   **** /EXISTE VARIABLE ****--------------------------------------------          
           
                    
                    
;   **** IDENTICOS ****----------------------------
                                                  ;|
;VERIFICA SI nombreVariable Y LA VARIABLE EN LA   ;|
;QUE SE ESTA APUNTANDO EN MEMORIA POR EL si       ;|
;TIENEN EL MISMO NOMBRE                           ;|
                                                  ;|
IDENTICOS proc                                    ;|
    push si                                       ;|
    push bx                                       ;|
                                                  ;|
    add si, 2                                     ;|
    mov al, 0                                     ;|
                                                  ;|
c_IDEN:                                           ;|
    mov bx, MEMORIA[si]                           ;|
    cmp bl, nombreVar[di]                         ;|
    je a_IDEN                                     ;|
                                                  ;|
    jmp f_IDEN                                    ;|
                                                  ;|
                                                  ;|
                                                  ;|
                                                  ;|
a_IDEN: ;VERIFICO SI ES UN = PARA TERMINAR        ;|
    cmp bx, '='                                   ;|
    je a1_IDEN                                    ;|
    inc di                                        ;|
    add si, 2                                     ;|
    jmp c_IDEN                                    ;|
                                                  ;|
                                                  ;|
a1_IDEN:    ;AMBOS SON = RETORNO TRUE             ;|
    mov al, 1                                     ;|
                                                  ;|
f_IDEN:                                           ;|
    pop bx                                        ;|
    pop si                                        ;|
    ret                                           ;|
                                                  ;|
IDENTICOS endp                                    ;|
                                                  ;|
;   **** /IDENTICOS ****---------------------------


                              
                              
;---**** COMPARACIONES ****--------------- 
                                         ;|
ES_LETRA_MAY proc ;---------------       ;|
    push bp                      ;|      ;|
    mov bp, sp                   ;|      ;|
    cmp [bp+4],65 ;REVISA A      ;|      ;|
    jb  a_ES_LETRA_MAY           ;|      ;|
    cmp [bp+4],90 ;REVISA Z      ;|      ;|
    jbe a0_ES_LETRA_MAY          ;|      ;|
                                 ;|      ;|
a_ES_LETRA_MAY:   ;FALSO         ;|      ;|
    mov al,0                     ;|      ;|
    jmp f_ES_LETRA_MAY           ;|      ;|
                                 ;|      ;|
a0_ES_LETRA_MAY:   ;VERDADERO    ;|      ;|
    mov al,1                     ;|      ;|
                                 ;|      ;|
                                 ;|      ;|
f_ES_LETRA_MAY:  ;RETORNA        ;|      ;|
    pop bp                       ;|      ;|
    ret 2                        ;|      ;|
ES_LETRA_MAY endp ;----------------      ;|
                                         ;|
                                         ;|
                                         ;|
ES_LETRA_MIN proc ;----------------      ;|
    push bp                       ;|     ;|
    mov bp, sp                    ;|     ;|
    cmp [bp+4], 97 ;REVISA a      ;|     ;|
    jb a_ES_LETRA_MIN             ;|     ;|
    cmp [bp+4], 122 ;REVISA z     ;|     ;|
    jbe a0_ES_LETRA_MIN           ;|     ;|
                                  ;|     ;|
a_ES_LETRA_MIN:   ;FALSO          ;|     ;|
    mov al,0                      ;|     ;|
    jmp f_ES_LETRA_MIN            ;|     ;|
                                  ;|     ;|
                                  ;|     ;|
a0_ES_LETRA_MIN:   ;VERDADERO     ;|     ;|
    mov al, 1                     ;|     ;|
                                  ;|     ;|
                                  ;|     ;|
f_ES_LETRA_MIN:     ;RETORNA      ;|     ;|
    pop bp                        ;|     ;|
    ret 2                         ;|     ;|
ES_LETRA_MIN endp ;----------------      ;|
                                         ;|
                                         ;|
                                         ;|
ES_NUMERO proc ;-------------------      ;|
    push bp                       ;|     ;|
    mov bp, sp                    ;|     ;|
    cmp [bp+4], 48 ;0             ;|     ;|
    jb a_ES_NUMERO                ;|     ;|
    cmp [bp+4], 57 ;9             ;|     ;|
    jbe a0_ES_NUMERO              ;|     ;|
                                  ;|     ;|
a_ES_NUMERO:    ;FALSO            ;|     ;|
    mov al,0                      ;|     ;|
    jmp f_ES_NUMERO               ;|     ;|
                                  ;|     ;|
a0_ES_NUMERO:   ;VERDADERO        ;|     ;|
    mov al,1                      ;|     ;|
                                  ;|     ;|
                                  ;|     ;|
f_ES_NUMERO:                      ;|     ;|
    pop bp                        ;|     ;|
    ret 2                         ;|     ;|
                                  ;|     ;|
ES_NUMERO endp ;-------------------      ;|
                                         ;|
;---**** /COMPARACIONES ****--------------



;   **** IMPRIME ERROR ****---
IMPRIME_ERROR proc           ;|
    call CAMBIO_LINEA        ;|
    push bp                  ;|
    mov bp, sp               ;|
    mov dx, [bp+4]           ;|
    mov ah,9                 ;|
    int 21h                  ;|
    pop bp                   ;|
    ret 2                    ;|
IMPRIME_ERROR endp           ;|
                             ;|
;   **** /IMPRIME ERROR ****--  


;   **** CAMBIO DE LINEA ****----
                                ;|
CAMBIO_LINEA proc               ;|
    mov AH,2                    ;|
    mov dl,10 ;NUEVA LINEA      ;|
    int 21h                     ;|
    mov dl,13 ;CORRE CARRETE    ;|
    int 21h                     ;|
    ret                         ;|
CAMBIO_LINEA endp               ;|
                                ;|
;   **** /CAMBIO DE LINEA ****--- 
                                                   

;   **** COMENTARIOS ****------
;Quita todo despues de #      ;|
                              ;|
                              ;|
COMENTARIOS proc              ;|
    mov si, offset read       ;|
    mov si, 1                 ;|
                              ;|
c_COMENT:                     ;|
    inc si                    ;|
    cmp read[si], 0           ;|
    je f_COMENT               ;|
    cmp read[si], 13          ;|
    je f_COMENT               ;|
    cmp read[si], 35          ;|
    je c2_COMENT              ;|
                              ;|
    jmp c_COMENT              ;|
                              ;|
c2_COMENT:                    ;|
    cmp read[si], 0           ;|
    je f_COMENT               ;|
    cmp read[si], 13          ;|
    je f_COMENT               ;|
    mov al, 0                 ;|
    mov read[si], al          ;|
    jmp c2_COMENT             ;|
                              ;|
f_COMENT:                     ;|
    ret                       ;|
                              ;|
                              ;|
                              ;|
COMENTARIOS endp              ;|
                              ;|
                              ;|
;   **** /COMENTARIOS ****-----                                                    

;   **** INDENTIFICA OP ****
INDENTIFICA_OP proc
    push si
    push di     
    mov si, 2
    call ES_UNSET 
    pop di
    pop si
    cmp al,1
    je a_UNSET
    
    push si
    push di     
    mov si, 2
    call ES_PRINT 
    pop di
    pop si
    cmp al, 1
    je a_PRINT
    
    push si
    push di     
    mov si, 2
    call ES_LIST 
    pop di
    pop si
    cmp al, 1
    je a_LIST
    
    
    push si
    push di     
    mov si, 2
    call ES_ASIGNACION 
    pop di
    pop si
    cmp al, 1
    je a_ASIGNACION
    
    jmp e_IDENT_OP
    
    
    
a_UNSET:
    call Unset 
    call CAMBIO_LINEA
    jmp f_IDENT_OP
    

a_PRINT:
    call PRINT
    jmp f_IDENT_OP

a_LIST:
    call List    
    jmp f_IDENT_OP

a_ASIGNACION:
    call ASIGNACION
    call CAMBIO_LINEA
    jmp f_IDENT_OP
    
e_IDENT_OP:
    mov bx, offset error9
    push bx
    call IMPRIME_ERROR     
        
    
f_IDENT_OP:    
    ret
          
INDENTIFICA_OP endp
;   **** /IDENTIFICA OP ****
               

               
               
ES_ASIGNACION proc
    mov al, 0
    
    
c_ES_ASIG:
    mov bh, 0
    mov bl, read[si]
    cmp bx, 32
    je a_ES_ASIG
    cmp bx, 0
    je f_ASIG
    cmp bx, 13
    je f_ASIG
    
    cmp bx, '='
    je a1_ES_ASIG
    inc si
    
    jmp c_ES_ASIG
            
            
a_ES_ASIG:  ;ES ESPACIO EN BLANCO
    inc si
    jmp c_ES_ASIG
    
a1_ES_ASIG:
    mov al,1
     
    
f_ES_ASIG:
    ret   
     
ES_ASIGNACION endp 

             
             
             
ES_UNSET proc 
    mov al, 0
    mov di, offset t_unset
    mov di, 0
    
    
c_ES_UNSET:
    mov bh, 0
    mov bl, read[si]
    cmp bx, 32
    je a_ES_UNSET
    cmp bx, 'u'
    je c2_ES_UNSET
    jmp f_ES_UNSET
    
    
a_ES_UNSET: ;ESPACIO EN BLANCO
    inc si
    jmp c_ES_UNSET
     

     
c2_ES_UNSET:    
    
    mov bl, t_unset[di]
    cmp bl, '$'
    je a2_ES_UNSET  
    
    mov bh, read[si]
    cmp bl, read[si]
    je a1_ES_UNSET
    
    jmp f_ES_UNSET  
    
    

a1_ES_UNSET:    ;INCREMENTO PARA COMPARA LOS SIGUIENTES CARACTERES
    inc di
    inc si
    jmp c2_ES_UNSET

a2_ES_UNSET:    ;LLEGUE AL FINAL DE t_unset, verifico siga espacio
    
    mov bl, read[si]
    cmp bl, 32
    jne f_ES_UNSET
    mov al, 1     
     
f_ES_UNSET:
    
    ret
    
ES_UNSET endp

         
         
         

ES_PRINT proc 
    mov al, 0
    mov di, offset t_print
    mov di, 0
    
    
c_ES_PRINT:
    mov bh, 0
    mov bl, read[si]
    cmp bx, 32
    je a_ES_PRINT
    cmp bx, 'p'
    je c2_ES_PRINT
    jmp f_ES_PRINT
    
    
a_ES_PRINT: ;ESPACIO EN BLANCO
    inc si
    jmp c_ES_PRINT
     

     
c2_ES_PRINT:    
    
    mov bl, t_print[di]
    cmp bl, '$'
    je a2_ES_PRINT  
    
    mov bh, read[si]
    cmp bl, read[si]
    je a1_ES_PRINT
    
    jmp f_ES_PRINT  
    
    

a1_ES_PRINT:    ;INCREMENTO PARA COMPARA LOS SIGUIENTES CARACTERES
    inc di
    inc si
    jmp c2_ES_PRINT

a2_ES_PRINT:    ;LLEGUE AL FINAL DE t_unset, verifico siga espacio
    
    mov bl, read[si]
    cmp bl, 32
    jne f_ES_PRINT
    mov al, 1     
     
f_ES_PRINT:
    
    ret
    
ES_PRINT endp 





ES_LIST proc 
    mov al, 0
    mov di, offset t_list
    mov di, 0
    
    
c_ES_LIST:
    mov bh, 0
    mov bl, read[si]
    cmp bx, 32
    je a_ES_LIST
    cmp bx, 'l'
    je c2_ES_LIST
    jmp f_ES_LIST
    
    
a_ES_LIST: ;ESPACIO EN BLANCO
    inc si
    jmp c_ES_LIST
     

     
c2_ES_LIST:    
    
    mov bl, t_list[di]
    cmp bl, '$'
    je a2_ES_LIST  
    
    mov bh, read[si]
    cmp bl, read[si]
    je a1_ES_LIST
    
    jmp f_ES_LIST  
    
    

a1_ES_LIST:    ;INCREMENTO PARA COMPARA LOS SIGUIENTES CARACTERES
    inc di
    inc si
    jmp c2_ES_LIST

a2_ES_LIST:    ;LLEGUE AL FINAL DE t_unset, verifico siga espacio
    
    mov bl, read[si]
    cmp bl, 13
    jne f_ES_LIST
    mov al, 1     
     
f_ES_LIST:
    
    ret
    
ES_LIST endp 






;   **** LIST ****
List proc
        call CAMBIO_LINEA
        mov si, offset MEMORIA
        mov si,0
    
    principalPrint:
        cmp si, IDX_MEM
        je finList
                    
        mov cx, MEMORIA[si]
        inc si
        inc si
        call Escritor
        inc si
        inc si
        mov bx, MEMORIA[si]
        pusha
        push bx
        call NUM_A_STRING
        popa
        call CAMBIO_LINEA
        inc si
        inc si
        jmp principalPrint
         
        finList:
        ret 
        
    List endp
    
    
    Escritor proc        
        ciclo:
            mov dx, MEMORIA[si]
            mov ah,2
            int 21h
            cmp dx, '='
            je finEscritor
            inc si
            inc si
            jmp ciclo
        
        finEscritor:
            ret 
                            
        
    Escritor endp

;   **** /LIST ****  


;   **** PRINT ****

PRINT proc   
    mov di, offset nombreVar
    mov di, -1
    mov si, 7
    
c_PRINT:
    inc si
    mov bl, read[si]
    
    cmp bl, 32
    je c_PRINT
    
    cmp bl, 0
    je i_PRINT
    
    cmp bl, 13
    je i_PRINT
    
    inc di
    mov nombreVar[di], bl
    jmp c_PRINT
    
    
i_PRINT:
    inc di           
    mov bl, '$'
    mov nombreVar[di], bl
    mov di, 0    
    call Traductor
    cmp bx, 0
    je f_PRINT 
    
    call CAMBIO_LINEA 
    
    
    mov bx, PILA_NPI[0]
    push bx
    call NUM_A_STRING  
    
f_PRINT:
    call LIMPIA
    call CAMBIO_LINEA
    ret
    
PRINT endp

;   **** /PRINT ****




;   **** UNSET ****

Unset proc
        
        mov si, offset read
        mov si, 8
        mov di, offset almacen
        mov di, 0                                            
                
        principalUnset:
            mov bl, read[si]
            cmp bl, 13
            je verExist
            mov almacen[di], bl
            inc si
            inc di
            jmp principalUnset
            
        verExist:
            mov almacen[di], '='                        
            inc di    
            call EXISTE_VAR2
            cmp al, 0
            je errorUnset
            mov di, si
            mov dx, MEMORIA[si]
            add dx, dx
            add si, 4
            add si,dx         
            
        c_Unset:    
            mov bx, MEMORIA[si]
            cmp IDX_MEM, si 
            je finUnset 
            mov MEMORIA[di], bx
            inc si
            inc si
            inc di
            inc di
            jmp c_Unset
            
        errorUnset:
            mov bx, offset error11
            push bx
            call IMPRIME_ERROR
            ret    
        
        finUnset:
            mov IDX_MEM, di
            ret          
            
            
Unset endp

;   **** /UNSET ****




;   **** NUM_A_STRING **** 

;IMPRIME UN NUMERO EN LA CONSOLA
;NO HACE CAMBIO DE LINEA      
      
NUM_A_STRING proc
    push bp
    
    xor cx,cx
    mov bp, sp
    mov ax, [bp+4] 
    
    cmp ax,0
    jne ini_N_S 
    
    add ax,48
    mov dx, ax
    mov ah, 2
    int 21h
    jmp f_N_S
    

ini_N_S:
    
    xor dx, dx 
    
    mov di, offset imprime
    mov di, 0
    
    cmp ax, 0
    jge c_N_S
    mov cx, 1
    mov bx, -1
    mul bx
    xor dx,dx 
    
    
c_N_S:
    cmp ax, 0
    je i_N_S
        
    mov bx, 10
    div bx
    
    add dx, 48
    
    mov imprime[di], dl    
    xor dx,dx    
    inc di
    jmp c_N_S
    
i_N_S:
    cmp cx, 1
    jne a_N_S
    mov ah, 2
    mov dl,45
    int 21h
     

a_N_S:
    dec di
    cmp di, -1
    je f_N_S
        
    mov ah, 2
    mov bl, imprime[di]
    mov dl, bl
    
    int 21h    
    jmp a_N_S
    
    

f_N_S:    
    pop bp
    ret 2
    
NUM_A_STRING endp

;   **** /NUM_A_STRING ****







;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


;   **** SUNTING_YARD ****----------------------------------------------------
                                                                            ;|
SUNTING_YARD proc                                                           ;|
                                                                            ;|
    mov si, offset OPERACION                                                ;|
    mov si, -2                                                              ;|
                                                                            ;|
c_SY:                                                                       ;|
    add si, 2                                                               ;|
    cmp OPERACION[si],'$'                                                   ;|
    je f_SY                                                                 ;|
                                                                            ;|
    mov bx, OPERACION[si]                                                   ;|
    push bx                                                                 ;|
    call ES_OPERADOR                                                        ;|
    cmp al, 1                                                               ;|
    je a0_SY                                                                ;|
                                                                            ;|
    mov bx, OPERACION[si]                                                   ;|
    push bx                                                                 ;|
    call ENCOLAR                                                            ;|
                                                                            ;|
    jmp c_SY                                                                ;|
                                                                            ;|
                                                                            ;|
                                                                            ;|
a0_SY:  ;ES OPERADOR                                                        ;|
    mov bx, OPERACION[si]                                                   ;|
                                                                            ;|
    cmp bx, '('                                                             ;|
    je a1_SY                                                                ;|
                                                                            ;|
    cmp bx, ')'                                                             ;|
    je a2_SY                                                                ;|
                                                                            ;|
    mov cx, IDX_PILA                                                        ;|
    cmp cx, 0                                                               ;|
    je a1_SY                                                                ;|
                                                                            ;|
    mov di, offset PILA_SY                                                  ;|
    mov di, IDX_PILA                                                        ;|
    sub di, 2                                                               ;|
                                                                            ;|
    mov dx, OPERACION[si]                                                   ;|
    push dx                                                                 ;|
    mov dx, PILA_SY[di]                                                     ;|
    push dx                                                                 ;|
    call MPRIORI                                                            ;|
    cmp al, 0                                                               ;|
    je a4_SY                                                                ;|
                                                                            ;|
    mov dx, OPERACION[si]                                                   ;|
    push dx                                                                 ;|
    call PUSH_P                                                             ;|
                                                                            ;|
    jmp c_SY                                                                ;|
                                                                            ;|
                                                                            ;|
                                                                            ;|
                                                                            ;|
a1_SY:  ;AGREGA A LA PILA ( || SI ESTA VACIA AGREGO                         ;|
    push bx                                                                 ;|
    call PUSH_P                                                             ;|
    jmp c_SY                                                                ;|
                                                                            ;|
a2_SY:  ;ENCONTRE ), SACO HASTA UN (                                        ;|
    mov cx, IDX_PILA                                                        ;|
    cmp cx,0                                                                ;|
    je e_SY                                                                 ;|
    mov di, offset PILA_SY                                                  ;|
    mov di, IDX_PILA                                                        ;|
    sub di, 2                                                               ;|
                                                                            ;|
    mov dx, PILA_SY[di]                                                     ;|
    cmp dx, '('                                                             ;|
    je a3_SY                                                                ;|
    call POP_P                                                              ;|
    push ax                                                                 ;|
    call ENCOLAR                                                            ;|
    jmp a2_SY                                                               ;|
                                                                            ;|
                                                                            ;|
                                                                            ;|
a3_SY:  ;ENCONTRE UN ( , BUDCANDO CON UN )                                  ;|
    call POP_P                                                              ;|
    jmp c_SY                                                                ;|
                                                                            ;|
                                                                            ;|
a4_SY:  ;SACAR HASTA DEJAR UN OPERADOR DE MENOR PRIORIDAD                   ;|
     call POP_P                                                             ;|
     push ax                                                                ;|
     call ENCOLAR                                                           ;|
                                                                            ;|
     mov dx, IDX_PILA                                                       ;|
     cmp dx, 0                                                              ;|
     je a5_SY                                                               ;|
                                                                            ;|
                                                                            ;|
     mov di, offset IDX_PILA                                                ;|
     mov di, dx                                                             ;|
     sub di, 2                                                              ;|
     mov dx, OPERACION[si]                                                  ;|
     push dx                                                                ;|
     mov dx, PILA_SY[di]                                                    ;|
     push dx                                                                ;|
     call MPRIORI                                                           ;|
     cmp al, 1                                                              ;|
     je a6_SY                                                               ;|
                                                                            ;|
                                                                            ;|
     jmp a4_SY                                                              ;|
                                                                            ;|
a5_SY:  ;BUSCANDO OPERADORES DE MENOR PRIORI DEJE LA PILA VACIA             ;|
    mov dx, OPERACION[si]    ;SALTO AL INICIO DEL CICLO                     ;|
    push dx                                                                 ;|
    call PUSH_P                                                             ;|
    jmp c_SY                                                                ;|
                                                                            ;|
a6_SY:                                                                      ;|
    mov bx, OPERACION[si]                                                   ;|
    push bx                                                                 ;|
    call PUSH_P                                                             ;|
    jmp c_SY                                                                ;|
                                                                            ;|
                                                                            ;|
e_SY:   ;E= MAL BALANCE                                                     ;|
    mov bx, offset error6                                                   ;|
    push bx                                                                 ;|
    call IMPRIME_ERROR                                                      ;|
    jmp f2_SY                                                               ;|
                                                                            ;|
                                                                            ;|
f_SY:                                                                       ;|
    mov di, offset PILA_SY                                                  ;|
    mov di, IDX_PILA                                                        ;|
    sub di, 2                                                               ;|
    cmp di, 0                                                               ;|
    jl f1_SY                                                                ;|
    mov bx, PILA_SY[di]                                                     ;|
    cmp bx, '('                                                             ;|
    je e_SY                                                                 ;|
                                                                            ;|
    call POP_P                                                              ;|
    push ax                                                                 ;|
    call ENCOLAR                                                            ;|
                                                                            ;|
    mov bx, IDX_PILA                                                        ;|
    cmp bx, 0                                                               ;|
    jne f_SY                                                                ;|
                                                                            ;|
                                                                            ;|
f1_SY:                                                                      ;|
    mov bx, '$'                                                             ;|
    push bx                                                                 ;|
    call ENCOLAR
    mov bx, 1                                                                ;|
    ret                                                                     ;|
                                                                            ;|
f2_SY:
    mov bx, 0
    ret                                                                     ;|
                                                                            ;|
                                                                            ;|
SUNTING_YARD endp                                                           ;|
                                                                            ;|
;   **** /SHUNTIGN_YARD ****-------------------------------------------------

                  
;   **** MAYOR PRIORIDAD ****------------------------------
MPRIORI proc                                              ;|
    ;RETORNA EL AL EL RES, 1 SI EL PRIMERO TIENE          ;|
    push bp   ;MAYOR PRIORIDAD                            ;|
    mov bp, sp                                            ;|
                                                          ;|
    mov bx, [bp+6] ;BX=OPERA#1                            ;|
                                                          ;|
    mov di, offset OPERADORES                             ;|
    mov di, 0                                             ;|
    mov dh, 0                                             ;|
                                                          ;|
c1_MPRIO:                                                 ;|
    mov dl, OPERADORES[di]                                ;|
    cmp bx, dx                                            ;|
    je a1_MPRIO                                           ;|
                                                          ;|
    inc di                                                ;|
                                                          ;|
    jmp c1_MPRIO                                          ;|
                                                          ;|
m_MPRIO:                                                  ;|
    mov bx, [bp+4]                                        ;|
                                                          ;|
c2_MPRIO:                                                 ;|
    mov dl, OPERADORES[di]                                ;|
    cmp bx, dx                                            ;|
    je a2_MPRIO                                           ;|
                                                          ;|
    inc di                                                ;|
                                                          ;|
    jmp c2_MPRIO                                          ;|
                                                          ;|
a1_MPRIO:   ;ENCONTRE EL PRIMER OPERADOR                  ;|
     mov ax, di                                           ;|
     mov di, offset PRIORIDAD                             ;|
     mov di, ax                                           ;|
     mov cl, PRIORIDAD[di] ; CL= PRIORI OPERA#1           ;|
     mov di, offset OPERADORES                            ;|
     mov di, 0                                            ;|
     jmp m_MPRIO                                          ;|
                                                          ;|
a2_MPRIO:   ;ENCONTRE EL SEGUNDO OPERADOR                 ;|
    mov ax, di                                            ;|
    mov di, offset PRIORIDAD                              ;|
    mov di, ax                                            ;|
    mov ch, PRIORIDAD[di] ;CH= PRIORI OPERA#2             ;|
                                                          ;|
    cmp cl, ch                                            ;|
    jg a3_MPRIO                                           ;|
    mov al, 0                                             ;|
    jmp f_MPRIO                                           ;|
                                                          ;|
                                                          ;|
a3_MPRIO:   ;EL PRIMERO TIENE MAYOR PRIORI                ;|
    mov al, 1                                             ;|
                                                          ;|
f_MPRIO:                                                  ;|
    pop bp                                                ;|
    ret 4                                                 ;|
                                                          ;|
MPRIORI endp                                              ;|
;   **** /MAYOR PRIORIDAD ****-----------------------------


;   **** ENCOLAR ****-------------------
                                       ;|
ENCOLAR proc ;RECIB 1 PARAMETRO        ;|
    push bp                            ;|
    mov bp, sp                         ;|
    mov bx, [bp+4]                     ;|
                                       ;|
    mov di, offset COLA_SY             ;|
    mov di, IDX_COLA                   ;|
    mov COLA_SY[di], bx                ;|
                                       ;|
    add di,2                           ;|
    mov IDX_COLA, di                   ;|
                                       ;|
    pop bp                             ;|
    ret 2                              ;|
ENCOLAR endp                           ;|
                                       ;|
;   **** /ENCOLAR ****------------------



;   **** POP ****---------------------
                                     ;|
POP_P proc ;RET EN EL AX             ;|
    mov di, offset PILA_SY           ;|
    mov di, IDX_PILA                 ;|
                                     ;|
    sub di, 2                        ;|
    mov ax, PILA_SY[di]              ;|
    mov PILA_SY[di], 0               ;|
    mov IDX_PILA, di                 ;|
    ret                              ;|
                                     ;|
POP_P endp                           ;|
                                     ;|
                                     ;|
;   **** /POP ****--------------------


;   **** PUSH_P ****------------------
                                     ;|
PUSH_P proc                          ;|
    push bp                          ;|
    mov bp, sp                       ;|
    mov di, offset PILA_SY           ;|
    mov di, IDX_PILA                 ;|
    mov bx, [bp+4]                   ;|
                                     ;|
    mov PILA_SY[di], bx              ;|
    add di, 2                        ;|
    mov IDX_PILA, di                 ;|
                                     ;|
                                     ;|
    pop bp                           ;|
    ret 2                            ;|
                                     ;|
PUSH_P endp                          ;|
                                     ;|
;   **** /PUSH_P ****----------------- 

     
     
;   **** ES_OPERADOR ****----------------------------
                                                   ;|
                                                   ;|
ES_OPERADOR proc  ;RETORNA EN AL 1 SI ES OPERADOR  ;|
    push bp                                        ;|
    mov bp, sp                                     ;|
    mov bx, [bp+4]                                 ;|
    mov al, 1                                      ;|
                                                   ;|
    cmp bx, '+'                                    ;|
    je f_ES_OPER                                   ;|
    cmp bx, '-'                                    ;|
    je f_ES_OPER                                   ;|
    cmp bx, '*'                                    ;|
    je f_ES_OPER                                   ;|
    cmp bx, '/'                                    ;|
    je f_ES_OPER                                   ;|
    cmp bx, '%'                                    ;|
    je f_ES_OPER                                   ;|
    cmp bx, '('                                    ;|
    je f_ES_OPER                                   ;|
    cmp bx, ')'                                    ;|
    je f_ES_OPER
    
    
    
    ;----------
    cmp bx, '^'
    je f_ES_OPER
    
    cmp bx, 170
    je f_ES_OPER
    
    cmp bx, 210
    je f_ES_OPER
    
    cmp bx, '>'                                   ;|
    je f_ES_OPER
    
    cmp bx, '<'
    je f_ES_OPER
    
    cmp bx, ':'
    je f_ES_OPER
    
    cmp bx, '|'
    je f_ES_OPER
    
    cmp bx, '&'
    je f_ES_OPER
    
    cmp bx, '!'
    je f_ES_OPER
    
    cmp bx, '~'
    je f_ES_OPER 
    
    cmp bx, '@'
    je f_ES_OPER
    
    mov al, 0                                     ;|
                                                   ;|
                                                   ;|
f_ES_OPER:                                         ;|
    pop bp                                         ;|
    ret 2                                          ;|
ES_OPERADOR endp                                   ;|
                                                   ;|
;   **** /ES_OPERADOR ****--------------------------         
         
         

;   **** EVALUADOR ****--------------------------------------------------------------
                                                                                    ;|
EVALUADOR proc                                                                      ;|
    mov si, offset COLA_SY                                                          ;|
    mov si, -2                                                                      ;|
    mov di, offset PILA_NPI                                                         ;|
    mov di, 0                                                                       ;|
                                                                                    ;|
c_EVAL:                                                                             ;|
    add si, 2                                                                       ;|
    mov bx, COLA_SY[si]                                                             ;|
    cmp bx, '$'                                                                     ;|
    je if_EVAL                                                                       ;|
    push bx                                                                         ;|
    call ES_OPERADOR                                                                ;|
    cmp al, 1                                                                       ;|
    je i_a_EVAL:                                                                       ;|
                                                                                    ;|
    jmp a1_EVAL                                                                     ;|
                                                                                    ;|

i_a_EVAL:
    cmp bx, '!'
    je invoca_UNARIO
    
    cmp bx, '~'
    je invoca_UNARIO


                                                                                    ;|
                                                                                    ;|
a_EVAL:  ;SI ES UN OPERADOR EVALUA LOS DOS NUMEROS QUE ESTAN EN EL TOPE             ;|
    push bx   ;PILA+=OPERADOR                                                       ;|
                                                                                    ;|
    sub di, 2                                                                       ;|
    mov bx, PILA_NPI[di]                                                            ;|
    mov PILA_NPI[di], 0                                                             ;|
    push bx   ;PILA+=#1                                                             ;|
                                                                                    ;|
    sub di, 2                                                                       ;|
    mov bx, PILA_NPI[di]                                                            ;|
    mov PILA_NPI[di], 0                                                             ;|
    push bx   ;PILA+=#2                                                             ;|
                                                                                    ;|
    call OPERA
     
    cmp bx, 0
    je f_EVAL
                                                                                    ;|
    mov PILA_NPI[di], ax                                                            ;|
    add di, 2                                                                       ;|
                                                                                    ;|
    jmp c_EVAL
    
    
invoca_UNARIO:
    push bx
    sub di, 2                                                                       ;|
    mov bx, PILA_NPI[di]                                                            ;|
    mov PILA_NPI[di], 0                                                             ;|
    push bx
    push bx
    call OPERA
    
    cmp bx, 0
    je f_EVAL
    
    mov PILA_NPI[di], ax
    add di, 2
    jmp c_EVAL 
    
                                                                          ;|
                                                                                    ;|
                                                                                    ;|
a1_EVAL:  ;SI NO ES OPERADOR METO EN LA PILA EN #                                   ;|
    ;sub di, 2
    mov PILA_NPI[di], bx                                                            ;|
    add di, 2                                                                       ;|
    jmp c_EVAL                                                                      ;|
                                                                                    ;|
                                                                                    ;|

if_EVAL:
    mov bx, 1                                                                                    ;|
                                                                                    ;|
f_EVAL:                                                                             ;|
    mov di, 0                                                                       ;|
    mov ax, PILA_NPI[di]                                                            ;|
    ret                                                                             ;|
                                                                                    ;|
EVALUADOR endp                                                                      ;|
                                                                                    ;|
;   **** /EVALUADOR ****--------------------------------------------------------------


;   **** OPERA ****----------------------------
                                              ;|
OPERA proc                                    ;|
    push bp                                   ;|
    mov bp, sp                                ;|
    push dx                                   ;|
    xor dx, dx                                ;|
                                              ;|
    mov cx, [bp+8]                            ;|
    mov ax, [bp+4]                            ;|
    mov bx, [bp+6]                            ;|
                                              ;|
    cmp cx, '+'                               ;|
    je sum_OPERA                              ;|
    cmp cx, '-'                               ;|
    je res_OPERA                              ;|
    cmp cx, '*'                               ;|
    je mul_OPERA                              ;|
    cmp cx, '/'                               ;|
    je div_OPERA                              ;|
    cmp cx, '%'                               ;|
    je mod_OPERA 
    
    
    ;----------------
    cmp cx, '^'
    je pot_OPERA
    
    cmp cx, 170     ;RAIZ
    je raiz_OPERA
    
    cmp cx, 210     ;SUMATORIA
    je sumatoria_OPERA
    
    cmp cx, '>'                                   ;|
    je shiftR_OPERA
    
    cmp cx, '<'
    je shiftL_OPERA
    
    cmp cx, ':'
    je log_OPERA
    
    cmp cx, '|'
    je or_OPERA
    
    cmp cx, '&'
    je and_OPERA
    
    cmp cx, '!'
    je fact_OPERA
    
    cmp cx, '~'
    je not_OPERA
    
    cmp cx, '@'
    je mul_OPERA                              ;|
                                              ;|
                                              ;|
sum_OPERA:                                    ;|
    pusha                                     ;|
    push ax                                   ;|
    push bx                                   ;|
    call REV_SUM_RES                          ;|
    cmp al, 0                                 ;|
    je e_OPERA                                ;|
                                              ;|
    popa                                      ;|
    add ax, bx 
    mov bx, 1                                ;|
    jmp f_OPERA
                                    ;|
                                              ;|
res_OPERA:                                    ;|
    pusha                                     ;|
    push ax                                   ;|
    push bx                                   ;|
    call REV_SUM_RES                          ;|
    cmp al, 0                                 ;|
    je e_OPERA                                ;|
                                              ;|
    popa                                      ;|
    sub ax, bx 
    mov bx, 1                                ;|
    jmp f_OPERA
                                  ;|
                                              ;|
mul_OPERA:                                    ;|
    pusha                                     ;|
    push ax                                   ;|
    push bx                                   ;|
    call REV_MUL                              ;|
    cmp al, 0                                 ;|
    je e_OPERA                                ;|
                                              ;|
    popa                                      ;|
    mul bx   
    mov bx, 1                                 ;|
    jmp f_OPERA
                                   ;|
                                              ;|
div_OPERA:     
    cmp bx, 0
    je e0_OPERA
    
    push dx
    cwd                                   ;|
    idiv bx
    pop dx 
    mov bx, 1                                    ;|
    jmp f_OPERA
                                  ;|
                                              ;|
mod_OPERA:
    cmp bx, 0
    je e0_OPERA
    
    push dx
    cwd                                    ;|
    idiv bx                             ;|
    mov ax, dx
    pop dx
    mov bx, 1                                ;|
    jmp f_OPERA 
    
    
pot_OPERA:    
    call POTENCIA
    cmp dx, 0
    je e1_OPERA
    mov bx, 1
    jmp f_OPERA 
    
    
raiz_OPERA:
    cmp ax, 0
    jl e2_OPERA
    call RAIZ 
    mov bx, 1
    jmp f_OPERA    


sumatoria_OPERA:
    cmp bx, ax
    ja e3_OPERA
    call SUMATORIA
    cmp dx, 0
    je e1_OPERA
    
    mov bx, 1
    jmp f_OPERA 
    


shiftR_OPERA:
    mov cl, bl
    sar ax, cl
    mov bx, 1
    jmp f_OPERA

shiftL_OPERA:
     mov cl, bl
     sal ax, cl
     mov bx, 1
     jmp f_OPERA


log_OPERA:
    cmp ax, 0
    jle e4_OPERA
    cmp bx, 0
    jle e4_OPERA
    
    call LOGARITMO
    mov bx,1
    jmp f_OPERA


or_OPERA:
    or ax, bx
    mov bx, 1
    jmp f_OPERA


and_OPERA:
    and ax, bx
    mov bx, 1
    jmp f_OPERA
 
 
fact_OPERA:  
    cmp ax, 0
    jl e4_OPERA
    push di
    call FACTORIAL
    pop di
    
    cmp dx, 0
    je e1_OPERA 
    
    mov bx, 1
    jmp f_OPERA
    

not_OPERA:
    not ax
    mov bx, 1
    jmp f_OPERA
    

             
e4_OPERA:
    mov bx, offset error15
    push bx
    call IMPRIME_ERROR
    mov bx, 0
    jmp f_OPERA    
    

e3_OPERA:
    mov bx, offset error14
    push bx
    call IMPRIME_ERROR
    mov bx, 0
    jmp f_OPERA

e2_OPERA:
    mov bx, offset error13
    push bx
    call IMPRIME_ERROR
    mov bx, 0
    jmp f_OPERA
    
    
e0_OPERA:   ;TRATO DE DIV * 0
    ;popa
    mov bx, offset error10
    push bx
    call IMPRIME_ERROR
    mov bx, 0
    jmp f_OPERA                               ;|
                                              ;|

e1_OPERA:
    mov bx, 0
    jmp f_OPERA
    
e_OPERA:                                      ;|
    popa
    mov bx, 0                                      ;|
                                              ;|
f_OPERA:                                      ;|
    pop dx                                    ;|
    pop bp                                    ;|
    ret 6                                     ;|
                                              ;|
OPERA endp                                    ;|
                                              ;|
;   **** /OPERA ****---------------------------

LOGARITMO proc
        mov dx, 1
        mov calculo, dx
        xor dx, dx 
        mov cx, bx
        mov bx, 2
    c_LOGARITMO:
        push ax
        push bx
        push cx
        
        call POW
        pop cx
        pop bx
        pop ax
        jc  f_LOGARITMO        
        cmp dx, cx
        jg f_LOGARITMO
        
        mov calculo, bx
        inc bx    
        
        jmp c_LOGARITMO
        
    
    f_LOGARITMO:
        mov ax, calculo
        ret
        
LOGARITMO endp
              
              
              
FACTORIAL proc  ;ok
    mov bx, ax
    c_FACTORIAL:
        
        dec bx
        cmp bx, 0
        je f_c_FACT
        mul bx             
        
        jc e_FACTORIAL        
        jmp c_FACTORIAL 
        
    f_c_FACT:
        mov dx, 1
        jmp f_factorial
    
    e_FACTORIAL:
       mov bx, offset error8
       push bx
       call IMPRIME_ERROR
       mov dx,0
       
    f_factorial:
        ret
    
FACTORIAL endp

 

SUMATORIA proc
    mov cx, bx
    sub cx, ax
    mov bx, ax
    cmp cx, 0
    jge c_SUMATORIA
    mov dx, cx
    mov cx, 0
    sub cx, dx
    
    c_SUMATORIA:      
        inc bx
        add ax,bx
        
        jo e_SUMATORIA
        
        loop c_SUMATORIA
        
        mov dx, 1
        jmp f_SUMATORIA
        
    
    e_SUMATORIA:
       mov bx, offset error8
       push bx
       call IMPRIME_ERROR
       mov dx,0
       
       
    f_SUMATORIA:
        ret      
SUMATORIA endp 




RAIZ proc
    mov dx, 1
    mov calculo, dx
    xor dx,dx  
    
     
    mov cx, ax
    dec cx

        
    c1_RAIZ:
        push bx
        push ax        
        push cx
        sub ax, cx
        call POW
        mov bx, bx
        pop cx        
        pop ax
        
        jc f_RAIZ
        cmp dx, ax
        jg f_RAIZ        
        mov calculo, bx 
        pop bx        
        loop c1_RAIZ
        
     f_RAIZ:
        pop bx
        mov ax, calculo  
        ret           
    
RAIZ endp


POW proc
    mov cx, bx
    dec cx
    mov bx, ax
    
c_POW:
    mul bx
    jc f_POW
    loop c_POW
    
    f_POW:
    mov dx, ax
    ret
     
POW endp      
      
      

POTENCIA proc
    push cx
    ;push dx
    xor dx,dx
    
    mov cx, bx
    dec cx
    mov bx, ax
    
c_POTENCIA:
    imul bx
    jc e_POTENCIA
    loop c_POTENCIA
    
    mov dx, 1
    jmp f_POTENCIA 
    
e_POTENCIA:                                 ;|
    mov bx, offset error8           ;|
    push bx                         ;|
    call IMPRIME_ERROR
    mov dx, 0
    
    f_POTENCIA:
    ;pop dx
    pop cx
    ret     
POTENCIA endp


;   **** REVISAR RANGO ****----------               
;RECIB 2 #                          ;|
REV_SUM_RES proc                    ;|
    push bp                         ;|
    mov bp, sp                      ;|
    mov al, 0                       ;|
    mov ax, [bp+4]                  ;|
    cmp ax, 0                       ;|
    jge i0_REV_S                    ;|
                                    ;|
    mov bx, -1                      ;|
    mul bx                          ;|
                                    ;|
i0_REV_S:                           ;|
    mov cx, ax                      ;|
    mov ax, [bp+6]                  ;|
    cmp ax, 0                       ;|
    jge i1_REV_S                    ;|
                                    ;|
    mov bx, -1                      ;|
    mul bx                          ;|
                                    ;|
i1_REV_S:                           ;|
    add ax, cx                      ;|
    cmp ax, 0                       ;|
    jl e_REV_S                      ;|
                                    ;|
    mov al,1                        ;|
    jmp f_REV_S                     ;|
                                    ;|
                                    ;|
e_REV_S:                            ;|
    mov bx, offset error8           ;|
    push bx                         ;|
    call IMPRIME_ERROR
    mov al, 0                       ;|
                                    ;|
                                    ;|
f_REV_S:                            ;|
    pop bp                          ;|
    ret 4                           ;|
                                    ;|
REV_SUM_RES endp                    ;|
                                    ;|
;/////////////////\\\\\\\\\\\\\\\\\\;|
                                    ;|
REV_MUL proc                        ;|
    push bp                         ;|
    mov bp, sp                      ;|
                                    ;|
                                    ;|
    mov ax, [bp+4]                  ;|
    cmp ax, 0                       ;|
    jge i_REV_M                     ;|
    mov bx, -1                      ;|
    mul bx                          ;|
                                    ;|
i_REV_M:                            ;|
    mov cx, ax                      ;|
    mov ax, 32767                   ;|
    xor dx,dx
    cmp cx, 0
    je f2_REV_M                       ;|
    div cx                               ;|

    mov cx, ax                      ;|
                                    ;|
    mov ax, [bp+6]                  ;|
    cmp ax, 0                       ;|
    jge i1_REV_M                    ;|
    mov bx, -1                      ;|
    mul bx                          ;|
                                    ;|
i1_REV_M:                           ;|
    cmp ax, cx                      ;|
    jg e_REV_M                      ;|
                                    ;|
    mov al, 1                       ;|
    jmp f_REV_M                     ;|
                                    ;|
                                    ;|
e_REV_M:                            ;|
    mov bx, offset error8           ;|
    push bx                         ;|
    call IMPRIME_ERROR
    mov al, 0                       ;|
                                    ;|
                                    ;|
f_REV_M:                            ;|
    pop bp                          ;|
    ret 4
    
f2_REV_M:
    pop bp
    mov al, 1
    ret 4
                           ;|
                                    ;|
REV_MUL endp                        ;|
                                    ;|
;   **** REVISAR RANGO ****----------

;---------------------NEW PEGADO ---------------------

Traductor proc
        
        mov si, offset nombreVar
        mov si, di
        mov di, offset OPERACION        
        mov di, 0 
        mov cx, 1
        
        
        principalTrad:
            mov dh, 0
            mov dl, nombreVar[si]
            cmp dx, '$'
            je result
            push dx
            call ES_NUMERO
            cmp al,1
            je numero
            push dx
            call ES_OPERADOR
            cmp al, 1
            je operador
            call Letter
            cmp cx, 0
            je errorGen
            jmp principalTrad
            
            
        numero:
            push dx
            xor dx,dx 
            push di
            call PARCEADOR
            pop di 
             
            cmp cx, 0
            je errorParce
            mov OPERACION[di], dx
            pop dx
            inc di
            inc di
            jmp principalTrad
            
        operador:
            call OperaTrad
            cmp cx, 0
            je errorGen
            jmp principalTrad
            
        errorParce:
            pop dx
            jmp finNoTrad
            
        errorGen:
            jmp finNoTrad           
            
        result:
            mov ax, '$'           
            mov OPERACION[di], ax
            jmp finTrad
        
        finNoTrad:
            mov bx, 0
            jmp fin
            
        finTrad:
            call SUNTING_YARD
            cmp bx,0
            je fin
            call EVALUADOR
        
        fin:
            ret              
Traductor endp
    
    
OperaTrad proc 
        mov dh, 0
        mov dl, nombreVar[si]
        cmp dx, '*'
        je metoEsp
        cmp dx, '/'
        je metoEsp
        cmp dx, '%'
        je metoEsp
        
        cmp dx, '^'
        je metoEsp 
        
        cmp dx, '>'                                   ;|
        je metoEsp
    
        cmp dx, '<'
        je metoEsp
    
        cmp dx, ':'
        je metoEsp
    
        cmp dx, '|'
        je metoEsp
    
        cmp dx, '&'
        je metoEsp
    
        cmp dx, '!'
        je metoEsp
    
        cmp dx, '~'
        je metoEsp
        
        cmp dx, '@'
        je metoEsp
         
            
        cmp dx, '('
        je meto
        cmp dx, ')'
        je meto
        cmp dx, '+'
        je mas
        cmp dx, '-'
        je menos
        
        mas:
            call U_metido
            cmp al, 0
            je meto
            jmp finOper
        
        menos:        
            call U_metido
            cmp al,0
            je meto
            mov OPERACION[di], -1
            inc di
            inc di
            mov OPERACION[di], '@'
            inc di
            inc di
            jmp finOper        
            
        inter_metoEsp:
            
            push di
            dec di
            dec di
            mov dx, OPERACION[di]
            pop di
            cmp dx, ')'
            jne error_OperaTrad
            jmp meto
            
        
        metoEsp:
        
            call U_Metido
            cmp al, 2
            je error_OperaTrad
            cmp al, 1
            je inter_metoEsp
            jmp meto
            
        error_OperaTrad:
            mov cx, 0
            mov bx, offset error6 
            push bx
            call IMPRIME_ERROR
            ret                 
        
        meto:
            
            mov OPERACION[di], dx
            inc di
            inc di
        
        finOper:
            inc si
            ret
OperaTrad endp
    
    
    
U_metido proc
                dec di
        dec di
        cmp di, 0
        jl nada 
        push dx
        mov dx, OPERACION[di]       
        
        cmp dx, ')'
        je fin2U_met
        
        cmp dx, '!'
        je fin2U_met
        
        cmp dx, '~'
        je fin2U_met
        
        push dx
        call ES_OPERADOR
        pop dx
        cmp al, 1
        je finU_met
        

        mov al, 0
        jmp finU_met 
        
        nada:
            mov al, 2
                    
        finU_met:
            inc di
            inc di
            ret 
        
        fin2U_met:
            mov al, 0
            inc di
            inc di
            pop dx
            ret
            
U_metido endp 


    
Letter proc
        
        push di
        mov di, offset almacen
        mov di, 0
        
        principalLet: 
            mov dh, 0
            mov dl, nombreVar[si]
            cmp dx, '$'
            je existe
            push dx
            call ES_OPERADOR
            cmp al, 1
            je existe
            mov almacen[di], dl
            inc di
            inc si
            jmp principalLet
            
        existe:
            mov almacen[di], '='
            inc di  
            push si
            call EXISTE_VAR2
            pop si 
            dec di   
            cmp al, 1
            je mete
            jmp error_Letter
            
        mete:
            mov di, offset OPERACION
            pop di
            
            mov OPERACION[di], dx
            ;inc di
;            inc di
            jmp finLet
            
        error_Letter:
            mov cx, 0
            mov bx, offset error11 
            push bx
            call IMPRIME_ERROR
            pop di
            
        finLet:
            inc di
            inc di
            ret 
Letter endp 





;+++++++++++++++++++++++++++++++++++++++++++++++++++++




;   **** EXISTE LA VARIABLE 2 ****-----------------------------------------
EXISTE_VAR2 proc                                                         ;|
    mov bx, di ;BX=LenghtNombre                                          ;|
                                                                         ;|
    mov di, offset almacen                                               ;|
                                                                         ;|
    mov si, offset MEMORIA                                               ;|
    mov si, 0                                                            ;|
                                                                         ;|
c_EXIS_V2:                                                               ;|
    mov di,0                                                             ;|
    mov al,0                                                             ;|
                                                                         ;|
    mov cx, MEMORIA[si]                                                  ;|             
    cmp cx, bx                                                           ;|
    je a1_EXIS_V2                                                        ;|
                                                                         ;|
i_c_EXIS_V2:                                                             ;|
    cmp al, 1                                                            ;|
    je a0_EXIS_V2                                                        ;|
                                                                         ;|
    add si, cx                                                           ;|
    add si, cx                                                           ;|
                                                                         ;|
    add si, 4                                                            ;|  
                                                                         ;|
                                                                         ;|
    cmp si, IDX_MEM                                                      ;|
    jae a_EXIS_V2                                                        ;|
    jmp c_EXIS_V2                                                        ;|
                                                                         ;|
                                                                         ;|
a1_EXIS_V2:   ;SI LOS DOS TIENEN EL MISMO LENGTH                         ;|
    call IDENTICOS2                                                      ;|
    jmp i_c_EXIS_V2                                                      ;|
                                                                         ;|
a0_EXIS_V2:    ;LA VARIABLE EXISTE EN MI MEMORIA                         ;|
    mov al, 1                                                            ;|
    jmp f_EXIS_V2                                                        ;|
                                                                         ;|
                                                                         ;|
a_EXIS_V2:     ;SI ME PASO DEL INDICE DEL ARRAY ES QUE NO LO ENCONTRE    ;|
    mov al,0                                                             ;|
                                                                         ;|
                                                                         ;|
f_EXIS_V2:                                                               ;|
                                                                         ;|
    ret                                                                  ;|
                                                                         ;|
EXISTE_VAR2 endp                                                         ;|
                                                                         ;|
;   **** /EXISTE VARIABLE 2 ****-------------------------------------------          
           
                    
                    
;   **** IDENTICOS 2 ****---------------------------
                                                  ;|
;VERIFICA SI nombreVariable Y LA VARIABLE EN LA   ;|
;QUE SE ESTA APUNTANDO EN MEMORIA POR EL si       ;|
;TIENEN EL MISMO NOMBRE                           ;|
                                                  ;|
IDENTICOS2 proc                                   ;|
    push si                                       ;|
    push bx                                       ;|
                                                  ;|
    add si, 2                                     ;|
    mov al, 0                                     ;|
                                                  ;|
c_IDEN2:                                          ;|
    mov bx, MEMORIA[si]                           ;|
    cmp bl, almacen[di]                           ;|
    je a_IDEN2                                    ;|
                                                  ;|
    jmp f_IDEN2                                   ;|
                                                  ;|
                                                  ;|
                                                  ;|
                                                  ;|
a_IDEN2: ;VERIFICO SI ES UN = PARA TERMINAR       ;|
    cmp bx, '='                                   ;|
    je a1_IDEN2                                   ;|
    inc di                                        ;|
    add si, 2                                     ;|
    jmp c_IDEN2                                   ;|
                                                  ;|
                                                  ;|
a1_IDEN2:    ;AMBOS SON = RETORNO TRUE            ;|
    mov al, 1                                     ;|
    add si, 2                                     ;|
    mov dx, MEMORIA[si]                           ;|
                                                  ;|
f_IDEN2:                                          ;|
    pop bx                                        ;|
    pop si                                        ;|
    ret                                           ;|
                                                  ;|
IDENTICOS2 endp                                   ;|
                                                  ;|
;   **** /IDENTICOS 2 ****--------------------------

;   **** PARCEADOR ****
 
;PARAMETROS, ARRAY,INDICE
;OJO: EL SI TIENE QUE ESTAR CON OFFSET nombreVar
;CUANDO RETORNE EL SI ESTARA MODIFICADO, RETORNA EN AX
PARCEADOR proc
    mov di, 0
    mov ax, 0                   
    mov cx, 10       
c_PARCEO:                   
    mov bh, 0                   
    mov bl, nombreVar[si]
    
    cmp bx, '$'
    je a_PARCEO
                       
    
    push bx   
    call ES_OPERADOR
    cmp al, 1
    je a_PARCEO    
    
    
    push bx
    call ES_NUMERO
    cmp al, 1
    je i_c_P
    
    
    jmp e_PARCEADOR
    
i_c_P: 
       
    cmp bx, 10
    je a_PARCEO
    cmp bx, 0
    je a_PARCEO
           
    sub bx, 48
    mov ax, dx
    
    push dx                  
    mul cx                
    add ax, bx  
    pop dx
    
    cmp ax, dx
    jl e2_PARCEADOR    
    
   
    mov dx, ax 
    inc si 

    jmp c_PARCEO
    
    
e_PARCEADOR:  ;PROBLEMA PARCEANDO
    mov cx, offset error7
    push cx
    call IMPRIME_ERROR 
    mov cx, 0
    jmp f_PARCEO
    
e2_PARCEADOR:   ;# MUY GRANDE
    mov cx, offset error8
    push cx
    call IMPRIME_ERROR
    mov cx, 0
    jmp f_PARCEO
    
a_PARCEO:   ;LLEGUE FIN PARCE OK
    mov cx, 1
                   
f_PARCEO:    
    ret 
    
PARCEADOR endp

;   **** /PARCEADOR ****



LIMPIA proc
    
    ;PILA NPI
    mov di, offset PILA_NPI
    mov di, -2
c_L_NPI:    
    add di, 2
    mov bx, PILA_NPI[di]
    
    cmp bx, 0
    je f_L_NPI
    
    cmp bx, '$'
    je f_L_NPI
    
    mov PILA_NPI[di], 0
    jmp c_L_NPI
    
f_L_NPI: 
    mov PILA_NPI[di], 0
    
    
    
    ;COLA_SY
    mov bx, 0
    mov IDX_COLA, bx    
    mov di, offset COLA_SY
    mov di, -2
c_L_COLASY:     
    add di, 2
    mov bx, COLA_SY[di]
    
    cmp bx, 0
    je f_L_COLASY
    
    cmp bx, '$'
    je f_L_COLASY
    
    mov COLA_SY[di], 0
    jmp c_L_COLASY
    
f_L_COLASY:
    mov COLA_SY[di], 0
    
    
     
    
    ;PILA_SY
    mov bx, 0
    mov IDX_PILA, bx    
    mov di, offset PILA_SY
    mov di, -2
c_L_PILASY:     
    add di, 2
    mov bx, PILA_SY[di]
    
    cmp bx, 0
    je f_L_PILASY    
    
    cmp bx, '$'
    je f_L_PILASY
    
    mov PILA_SY[di], 0
    jmp c_L_PILASY
    

f_L_PILASY: 
    mov PILA_SY[di], 0
    
    
    
    
    ;OPERACION
    mov bx, 0    
    mov di, offset OPERACION
    mov di, -2

c_L_OPERACION:     
    add di, 2
    mov bx, OPERACION[di]
    
    cmp bx, 0
    je f_L_OPERACION    
    
    cmp bx, '$'
    je f_L_OPERACION
    
    mov OPERACION[di], 0
    jmp c_L_OPERACION
    
    
f_L_OPERACION:
    mov OPERACION[di],0
    ret
    

LIMPIA endp


ARITMETICAS_AVANZADAS proc
    mov si, offset read
    mov si, 3
     
    
    c_ARTIMETICAS:
        inc si
        mov al, read[si]
        
        cmp al, 13
        je f_ARTIM
        
        cmp al, '*'
        je pos_Potencia
        
        cmp al, '_'
        je pos_Raiz
        
        cmp al, '.'
        je pos_Sum
        
        cmp al, '>'
        je pos_ShiftR
        
        cmp al, '<'
        je por_shiftL
        
        
        jmp c_ARTIMETICAS
        
    
    pos_Potencia:
        mov ah, read[si+1]
        cmp al, ah
        jne c_ARTIMETICAS
        mov read[si+1], 32
        mov read[si], '^'
        jmp c_ARTIMETICAS
        
    pos_Raiz:
        mov ah, read[si+1]
        cmp ah, 32
        jne c_ARTIMETICAS
        
        mov ah, read[si-1]
        cmp ah, 32
        jne c_ARTIMETICAS
        
        mov read[si], 170         
        jmp c_ARTIMETICAS
    
    
    pos_Sum:
        mov ah, read[si+1]
        cmp al, ah
        jne c_ARTIMETICAS
        mov read[si+1], 32
        mov read[si], 210
        jmp c_ARTIMETICAS
    
    
    pos_ShiftR:
        mov ah, read[si+1]
        cmp al, ah
        jne c_ARTIMETICAS
        mov read[si+1], 32
        jmp c_ARTIMETICAS
    
    
    por_shiftL:
        mov ah, read[si+1]
        cmp al, ah
        jne c_ARTIMETICAS
        mov read[si+1], 32
        jmp c_ARTIMETICAS
        
    
        
    f_ARTIM:
        ret
        
    
ARITMETICAS_AVANZADAS endp

                                                    
                                                    
end start ; set entry point and stop the assembler.
