; multi-segment executable file template.

data segment
    ; add your data here!
    pkey db "press any key...$"
    
    imprime db 6 dup(?),'$' 
    t_unset db "unset$"        
    t_print db "print$"         
    t_list db "list$"
    
    
    almacen db 512 dup(?)    
    read db 255,255 dup(?)                        
    nombreVar db 255 dup(?)
    
    OPERACION dw 512 dup(?);ARRAY QUE SE LE PASA AL SY
    MEMORIA dw 2,'f','=',4,3,'g','a','=',10  ;MEMORIA GENERAL DEL EVALUADOR. FORMATO = [#LengthNombre,"Nombre"+'=',#Valor]
    IDX_MEM dw 20           ;INDICE DE LA MEMORIA    
    
    COLA_SY dw 512 dup(0) ;COLA DEL SHUTING YARD
    IDX_COLA dw 0         ;INDICE DE LA COLA
    PILA_SY dw 512 dup(0) ;PILA DEL SHUTING YARD
    IDX_PILA dw 0         ;INDICE DE LA COLA DEL SHUTING YARD    
    PILA_NPI dw 512 dup(0);PILA PARA HACER LA EVALUACION (NOTACION POLACA INVERSA)
    
    
    PRIORIDAD db 0,0,1,1,1,-1,-1
    OPERADORES db "+-*/%()"
    
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
    
    
    ;---------------------------
     
    MEMORIA_FUNC dw 512 dup (?)
    IDX_MEM_FUNC dw ?
    
    variables db 512 dup(?)
    t_remplaza db 512 dup(?)
    temp db 512 dup(?)   
    nombreFunc db 512 dup(?)
    
    
ends

stack segment
    dw   128  dup(0)
ends

code segment
start:
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax

    ; add your code here
     
     
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
        
     ;call COMENTARIOS               
     cmp read[1],0
     je FIN_PRINC  
     
     call ASIGNACION_FUNC        
     ;PROBANDO ASIGNACION ----ok sin el ShutY 
     ;call ASIGNACION
     
     jmp LEER
     
FIN_PRINC: 
     call CAMBIO_LINEA
     call CAMBIO_LINEA  
     
     
     
     
     
     
            
    lea dx, pkey
    mov ah, 9
    int 21h        ; output string at ds:dx
    
    ; wait for any key....    
    mov ah, 1
    int 21h
    
    mov ax, 4c00h ; exit to operating system.
    int 21h    
ends

      
      
      
      
      
ASIGNACION_FUNC proc ;LA COMPROBACION DEL ) SE REALIZA EN IDENTIFICADOR DE FUNCIONES
    
    mov si, 2
i_ASIG_FUNC:
    cmp read[si],32 ;ES ESPACIO
    je a2_ASIG_FUNC  
    
    cmp read[si],95 ;ES _
    je a0_ASIG_FUNC 
    
    mov bh,0
    mov bl,read[si]
    push bx
    
    call ES_LETRA_MAY  ;A-Z
    cmp al,1
    je a0_ASIG_FUNC     
 
    
    push bx
    call ES_LETRA_MIN   ;a-z
    cmp al,1
    je a0_ASIG_FUNC
    
    
            
    jmp e5_ASIG_FUNC
     
    
a2_ASIG_FUNC:;1er CARACTER ES ESPACIO
    inc si
    jmp i_ASIG_FUNC

    
a0_ASIG_FUNC:;PASO AL CICLO
    mov di,0       
    mov al,read[si]
    mov nombreVar[di], al
    inc di
    
c_ASIG_FUNC:;CICLO#1 
    inc si    
    cmp read[si], 32 ;ESPACIO
    je c_ASIG_FUNC
    cmp read[si], 61 ;=
    je  a3_ASIG_FUNC  
    cmp read[si],95 ;REVISA _
    je a_ASIG_FUNC
    cmp read[si], 13 ;FIN
    je e2_ASIG_FUNC 
    
    
    mov bh,0
    mov bl, read[si]
    
    push bx     
    call ES_NUMERO
    cmp al,1
    je a_ASIG_FUNC
    
    push bx
    call ES_LETRA_MAY
    cmp al,1
    je a_ASIG_FUNC 
    
    push bx
    call ES_LETRA_MIN
    cmp al,1
    je a_ASIG_FUNC  
    
    cmp bx, '('
    je a_ASIG_FUNC
    
    cmp bx, ')'
    je a_ASIG_FUNC
    
    cmp bx, ','
    je a_ASIG_FUNC  
    
    jmp e_ASIG_FUNC   ;ES UN CARACTER INCORRECTO
    
    
a_ASIG_FUNC:     ;nombreVar = new caracter
    mov al,read[si]
    mov nombreVar[di], al
    inc di
    jmp c_ASIG_FUNC
    
a3_ASIG_FUNC:    ;agrego =
    mov al,read[si]
    mov nombreVar[di], al
    inc di
    jmp a1_ASIG_FUNC ;NOMBRE COMPLETO,VERIFICAR + CONDICIONES


;ERRORES    
e_ASIG_FUNC:    ;E=NOMBRE VAR INCORRECTA      
    mov bx, offset error1 
    push bx
    call IMPRIME_ERROR      
    jmp f_ASIG_FUNC  
    
e2_ASIG_FUNC:   ;E=ENTRADA INCORRECTA      
    mov bx, offset error2
    push bx
    call IMPRIME_ERROR       
    jmp f_ASIG_FUNC
    
e3_ASIG_FUNC:   ;E=ESPACIO INSUFICIENTE    
    mov bx, offset error3
    push bx
    call IMPRIME_ERROR      
    jmp f_ASIG_FUNC 

e4_ASIG_FUNC:     ;E=YA EXISTE UNA VARIABLE CON ESE NOMRBE
    mov bx, offset error4 
    push bx               
    call IMPRIME_ERROR      
    jmp f_ASIG_FUNC
    
e5_ASIG_FUNC:
    mov bx, offset error5
    push bx
    call IMPRIME_ERROR
    jmp f_ASIG_FUNC

e6_ASIG_FUNC:
    mov bx, offset error12
    push bx
    call IMPRIME_ERROR
    jmp f_ASIG_FUNC 
    
e7_ASIG_FUNC:
    pusha
    jmp f_ASIG_FUNC
    
;/ERRORES

a1_ASIG_FUNC:
    
    ;VER SI YA ESXISTE LA FUNCION
    push si
    push di
    call EXISTE_FUNCION                           
    pop di
    pop si
    
    cmp al,1
    je e4_ASIG_FUNC
    
    
    
    push di   
    call RELLENA_VALOR_F
    cmp al, 0
    je e6_ASIG_FUNC  
    mov ax, di
    add ax, di
    add ax, 2 ;$
    pop di 
    
    ;IMPORTANTE---------------
    pusha        
    call REMPLAZA_FUNC
        cmp al, 0
        je e7_ASIG_FUNC
    popa
    ;IMPORTANTE --------------
     
    ;REVISAR ESPACIO    
    add ax,IDX_MEM_FUNC 

        
    cmp ax, 512
    ja e3_ASIG_FUNC
    
    
    ;COPIAR PARA MEMORIA
    mov cx, di 
    mov di, 0
    mov si, offset MEMORIA_FUNC
    mov si, IDX_MEM_FUNC
    
c2_ASIG_FUNC:
    mov al, nombreVar[di]
    cbw
    cmp ax, '$'
    je f0_ASIG_FUNC 
    mov MEMORIA_FUNC[si], ax
    add si, 2
    inc di
    jmp c2_ASIG_FUNC
     
f0_ASIG_FUNC:
    mov ax, '$'
    mov MEMORIA_FUNC[si],ax
    add si,2 
    mov IDX_MEM_FUNC, si

f_ASIG_FUNC:
    ret

ASIGNACION_FUNC endp




;----------------------------------------------------------------------

REMPLAZA_FUNC proc
    mov si, offset nombreVar
    mov si, 0
    
    
c_REM_F:
    mov al, nombreVar[si]
    cmp al, '='    
    je i_REM_F
    inc si      
    jmp c_REM_F

i_REM_F:
    inc si
    
    
c2_REM_F:
    mov bl, nombreVar[si]
    mov bh, 0
    
    cmp bx, '$'
    je f_REM_F
    
    
    push bx
    call ES_LETRA_MAY
    cmp al, 1
    je a_c2_REM
    
    push bx
    call ES_LETRA_MIN
    cmp al, 1
    je a_c2_REM
        
    inc si
    jmp c2_REM_F 

    

a_c2_REM: ;VEO SI ES UNA FUNCION O UNA VARIABLE, SI ES UNA FUNCION, SUSTITUIRLA, CORRER
    mov dx, si;dx, indice por donde me quede
    
    c3_REM_F:
            inc si
            mov bl, nombreVar[si]
            
            cmp bl, '$'
            je f_REM_F
            
            cmp bl, '('
            je posible_FUNC

            
            mov bh,0
            push bx
            call ES_OPERADOR
            cmp al, 1
            je c2_REM_F
            
            jmp c3_REM_F 
            
            
e_REM_F:    ;NO SE ENCONTRO LA FUNCIO
    mov al,0
    ret
    
                 


posible_FUNC:   ;REVISAR SI ES UNA FUNCION
     push si
     
     mov si, dx
     dec si
               
     call COPIA_NOMBRE
     call COPIA_VARIABLES     
     call SWAP_NOMBRE_FUNC 
     call EXISTE_FUNCION2    
     pop si
     cmp al, 0
     je e_REM_F
     
     ;METODO DE RANDY AKIIIIIII
     
     ;ver el incremento del si  / es si+tamano de la nueva expre
     
     ;evaluar la funcion ver si funciona ok
     
     jmp c2_REM_F
    
       
    
f_REM_F:
    mov al, 1
    ret
    
REMPLAZA_FUNC endp 

;----------------------------------------------------------------------



COPIA_VARIABLES proc
    mov di, offset variables
    mov di, 0
    
c_COPIA_V:
    mov al, nombreVar[si]
    cmp al, '('
    je i_COPIA_V
    inc si
    jmp c_COPIA_V
    
    
i_COPIA_V:
    inc si
    c2_COPIA_V:
        mov al, nombreVar[si]
        cmp al, ')'
        je f_COPIA_V
        
        mov variables[di], al
        inc di
        inc si
        jmp c2_COPIA_V
    
    
    f_COPIA_V:    
    mov variables[di], '$'
    ret
    
COPIA_VARIABLES endp



SWAP_NOMBRE_FUNC proc
    mov si, offset almacen
    mov si, 0
    mov di, offset nombreFunc
    mov di, 0
    
    c_SWAP_N_F:
        mov al, almacen[si]
        mov nombreFunc[di], al
        
        cmp al, '='
        je f_SWAP_N_F
        inc si
        inc di
        jmp c_SWAP_N_F
        
    f_SWAP_N_F:
    ret
    
SWAP_NOMBRE_FUNC endp


;   **** RELLENA VALOR FUNCION ****
;CUANDO SE HACE UNA ASIGNACION RELLENA DESPUES DEL ESPACIO


RELLENA_VALOR_F proc
    push bp
    mov bp, sp
    
    mov cx, di
    mov al, 1
    
    inc si

c_RELL_V_F:
    
    mov bl, read[si]
    cmp bl, 13
    je f_RELL_V_F
    
    cmp bl, 32
    je a_RELL_V_F 
    
    cmp bl, 0
    je f_RELL_V_F
    
    mov nombreVar[di], bl
    inc di
    inc si
    
    jmp c_RELL_V_F
    
    
    
a_RELL_V_F:   ;SI ES ESPACIO EN BLANCO INCREMENTO EL SI
    
    inc si
    jmp c_RELL_V_F 
    

f_RELL_V_F:
    cmp cx, di
    jne i_F_RELL_V_F
    mov al, 0
    
    i_f_RELL_V_F:
    mov nombreVar[di], '$'
    pop bp
    ret     
    
RELLENA_VALOR_F endp

;   **** /RELLENA VALOR FUNCION ****




;   **** EXISTE LA FUNCION ****------------------------------------------
EXISTE_FUNCION proc                                                      ;|
                                                                         ;|
                                                                         ;|
    mov di, offset nombreVar                                             ;|
                                                                         ;|
    mov si, offset MEMORIA_FUNC                                          ;|
    mov si, -2                                                           ;|

                                                                         ;|
c_EXIS_F:
    add si,2                                                             ;|
    cmp si, IDX_MEM_FUNC                                                 ;|
    jae a_EXIS_F
     
    mov di,0                                                             ;|
    mov al,0                                                             ;|
                                                                         ;|
    call IDENTICOS_FUNC                                                  ;|
    cmp al, 1                                                            ;|
    je a0_EXIS_F                                                         ;|
    
    jmp c2_EXIS_F                                                        ;|
    

c2_EXIS_F:
    add si, 2
    mov bx, MEMORIA_FUNC[si]
    cmp bx, '$'
    je c_EXIS_F
    jmp c2_EXIS_F                                                        ;|
                                                                         ;|
                                                                         ;|
                                                                         ;|
a0_EXIS_F:    ;LA VARIABLE EXISTE EN MI MEMORIA
                             ;|
    mov al, 1
    ;add si,2                                                            ;|
    jmp f_EXIS_F                                                         ;|
                                                                         ;|
                                                                         ;|
a_EXIS_F:     ;SI ME PASO DEL INDICE DEL ARRAY ES QUE NO LO ENCONTRE
    push si    
    mov si, offset nombreVar
    mov si, -1
    call COPIA_NOMBRE
    pop si
    call EXISTE_VAR2
    
                                                                 ;|
                                                                         ;|
                                                                         ;|
f_EXIS_F:                                                                ;|
    ret                                                                  ;|
                                                                         ;|
EXISTE_FUNCION endp                                                      ;|
                                                                         ;|
;   **** /EXISTE VARIABLE ****--------------------------------------------          
           
                    
                    
;   **** IDENTICOS FUNC ****-----------------------
                                                  ;|
;VERIFICA SI nombreVariable Y LA VARIABLE EN LA   ;|
;QUE SE ESTA APUNTANDO EN MEMORIA POR EL si       ;|
;TIENEN EL MISMO NOMBRE                           ;|
                                                  ;|
IDENTICOS_FUNC proc                               ;|
    push si                                       ;|
    push bx
                                         ;|
    
    
                                                  ;|
    ;add si, 2                                    ;|
    mov al, 0                                     ;|
                                                  ;|
c_IDEN_F:                                         ;|
    mov bx, MEMORIA_FUNC[si]                      ;|
    cmp bl, nombreVar[di]                         ;|
    je a_IDEN_F                                   ;|
                                                  ;|
    jmp f_IDEN_F                                  ;|
                                                  ;|
                                                  ;|
                                                  ;|
                                                  ;|
a_IDEN_F: ;VERIFICO SI ES UN = PARA TERMINAR      ;|
     
    cmp bx, '('                                   ;|
    je a1_IDEN_F                                  ;|
    inc di                                        ;|
    add si, 2                                     ;|
    jmp c_IDEN_F                                  ;|
                                                  ;|
                                                  ;|
a1_IDEN_F:    ;AMBOS SON = RETORNO TRUE
                   ;|
    mov al, 1 
    mov cx, si
    add cx, 2                                     ;|
                                                  ;|
f_IDEN_F:
                                            ;|
    pop bx                                        ;|
    pop si                                        ;|
    ret                                           ;|
                                                  ;|
IDENTICOS_FUNC endp                               ;|
                                                  ;|
;   **** /IDENTICOS FUNC ****----------------------  

COPIA_NOMBRE proc
    ;push di
    push si
    
;    mov si, offset nombreVar
;    mov si, -1
    mov di, offset almacen
    mov di, -1
    
c_COPIA_N:
    inc si
    inc di
    mov al, nombreVar[si]
    cmp al, '('
    je f_COPIA
    mov almacen[di], al
    jmp c_COPIA_N
        
    
f_COPIA:
    mov almacen[di], '='    
    inc di    
    pop si
    ;pop di
    
    ret
COPIA_NOMBRE endp

  
  
;   **** CORRIMIENTOS ****

CORRER proc
    
    push bp
    mov bp, sp 
    push si         
             
    mov di, offset almacen 
    
    mov bx, [bp+6] ; ESTA
    sub bx, [bp+4] ; NEW
    ;BX=DIF
    
    cmp bx, 0
    je f_CORRER ;Dif=0
    
    cmp bx, 0
    jg a_CORRER
    
    
    ;Dif<0 
    mov cx, 0
    sub cx, bx
    mov bx, cx ;Dif= |Dif|
    
    call CORRER_DER
    
    jmp f_CORRER
    
a_CORRER:   ;0<Dif OK!
    mov di, si      
    add si, [bp+4]  ;START= IDX+|ESTA|
    add di, [bp+6]  ;SUST_EN= IDX+|NEW|
    mov cx, 512
    call CORRER_IZQ      
     
    
f_CORRER:
    pop si    
    pop bp
    ret 4
CORRER endp


;SI=INICIO, DI=SUST_EN, PARADA 
CORRER_IZQ proc
    
    
c_CORRER_I:
    mov al, almacen[di]
    mov almacen[si], al
    cmp al, '$'
    je f_CORRER_I
    inc si
    inc di
    jmp c_CORRER_I
     
f_CORRER_I:     
    
    ret 
    
CORRER_IZQ endp




CORRER_DER proc
    
c_BUS_$:
    cmp almacen[si], '$'
    je i_CORRER_D
    inc si
    jmp c_BUS_$
    
    
i_CORRER_D:
    mov di, offset almacen
    mov di, si ;INICIO
    add si, bx ;SUST_EN
    
    mov cx, bx
    dec dx
c_CORRER_D:
    mov al, almacen[di]
    mov almacen[si], al
    dec si
    dec di
    loop c_CORRER_D
    
    ret
CORRER_DER endp

;   **** /CORRIMIENTOS ****



;   **** EXISTE LA FUNCION2 ****------------------------------------------
EXISTE_FUNCION2 proc                                                      ;|
                                                                         ;|
                                                                         ;|
    mov di, offset almacen                                             ;|
                                                                         ;|
    mov si, offset MEMORIA_FUNC                                          ;|
    mov si, -2                                                           ;|

                                                                         ;|
c_EXIS_F2:
    add si,2                                                             ;|
    cmp si, IDX_MEM_FUNC                                                 ;|
    jae a_EXIS_F2
     
    mov di,0                                                             ;|
    mov al,0                                                             ;|
                                                                         ;|
    call IDENTICOS_FUNC2                                                  ;|
    cmp al, 1                                                            ;|
    je a0_EXIS_F2                                                         ;|
    
    jmp c2_EXIS_F2                                                        ;|
    

c2_EXIS_F2:
    add si, 2
    mov bx, MEMORIA_FUNC[si]
    cmp bx, '$'
    je c_EXIS_F2
    jmp c2_EXIS_F2                                                        ;|
                                                                         ;|
                                                                         ;|
                                                                         ;|
a0_EXIS_F2:    ;LA VARIABLE EXISTE EN MI MEMORIA
                             ;|
    mov al, 1
    ;add si,2                                                            ;|
    jmp f_EXIS_F2                                                         ;|
                                                                         ;|
                                                                         ;|
a_EXIS_F2:     ;SI ME PASO DEL INDICE DEL ARRAY ES QUE NO LO ENCONTRE
    mov al, 0    
                                                                 ;|
                                                                         ;|
                                                                         ;|
f_EXIS_F2:                                                                ;|
    ret                                                                  ;|
                                                                         ;|
EXISTE_FUNCION2 endp                                                      ;|
                                                                         ;|
;   **** /EXISTE VARIABLE ****--------------------------------------------          
           
                    
                    
;   **** IDENTICOS FUNC2 ****-----------------------
                                                  ;|
;VERIFICA SI nombreVariable Y LA VARIABLE EN LA   ;|
;QUE SE ESTA APUNTANDO EN MEMORIA POR EL si       ;|
;TIENEN EL MISMO NOMBRE                           ;|
                                                  ;|
IDENTICOS_FUNC2 proc                               ;|
    push si                                       ;|
    push bx
                                         ;|
    
    
                                                  ;|
    ;add si, 2                                    ;|
    mov al, 0                                     ;|
                                                  ;|
c_IDEN_F2:                                         ;|
    mov bx, MEMORIA_FUNC[si]
    cmp bx, '('
    je patch_IDEN2
                            ;|
    cmp bl, almacen[di]                         ;|
    je a_IDEN_F2                                   ;|
                                                  ;|
    jmp f_IDEN_F2                                  ;|
                                                  ;|
                                                  ;|

patch_IDEN2:
    mov bl, almacen[di]
    cmp bl, '='
    je a1_IDEN_F2
    
    jmp f_IDEN_F2
                                                  ;|
                                                  ;|
a_IDEN_F2: ;VERIFICO SI ES UN = PARA TERMINAR      ;|
     
    cmp bx, '('                                   ;|
    je a1_IDEN_F2                                  ;|
    inc di                                        ;|
    add si, 2                                     ;|
    jmp c_IDEN_F2                                  ;|
                                                  ;|
                                                  ;|
a1_IDEN_F2:    ;AMBOS SON = RETORNO TRUE
                   ;|
    mov al, 1 
    mov cx, si
    add cx, 2                                     ;|
                                                  ;|
f_IDEN_F2:
                                            ;|
    pop bx                                        ;|
    pop si                                        ;|
    ret                                           ;|
                                                  ;|
IDENTICOS_FUNC2 endp                               ;|
                                                  ;|
;   **** /IDENTICOS FUNC ****---------------------- 


;"""""""""""""""""""""""""""""""""""""""""""""""""""""
;       RANDY
;"""""""""""""""""""""""""""""""""""""""""""""""""""""


    

;"""""""""""""""""""""""""""""""""""""""""""""""""""""
;       RANDY
;"""""""""""""""""""""""""""""""""""""""""""""""""""""

;/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\/\/\/\/
;/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//\/\/\/\/\/\/\/\/\/\/
;/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

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
    je f_ES_OPER                                   ;|
                                                   ;|
    mov al,0                                       ;|
                                                   ;|
                                                   ;|
f_ES_OPER:                                         ;|
    pop bp                                         ;|
    ret 2                                          ;|
ES_OPERADOR endp                                   ;|
                                                   ;|
;   **** /ES_OPERADOR ****-------------------------- 

;/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\/\/\/\/\/\/
;/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//\/\/\/\/\/\/\/\/\/\/
;/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/




    
    
    


end start ; set entry point and stop the assembler.
