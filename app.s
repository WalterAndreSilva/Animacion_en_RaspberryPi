.equ SCREEN_WIDTH,      640
.equ SCREEN_HEIGH,      480
.equ BITS_PER_PIXEL,    32

.equ DILEY_AMOUNT,      50000 // velocidad
.equ DILEY_REPETITION,  100   // 

.globl main
main:
    // Dispocicion de los registros
    //cant nombres     uso
    //(9)  x0  - x8    variables locales y contadores (para bajar los valores de x20-x27)
    //(1)  x9          variable temporal
    //(9)  x10 - x18   pinceles
    //(1)  x19         valor de llamado y retorno de las funciones
    //(8)  x20 - x27   mantienen valores durante todo el programa
    //(1)  x28         color del pixel superior a pintar
    //(1)  x29         color del pixel inferior a pintar
    //(1)  x30 (LR)    direccion de retorno para los br
    
    // Espacio direccionable: 0x0000 0000 -> 0x0012 BFFC (aprox) = 1 228 800
    
    // Formato del color 64 bits (se almacenan 32 en el framebuffer)
    // 0x 0000 0000 0000 0000 0000 0000 0000 0001 0000 0000 1111 1111 1111 1111 1111 1111
    //                                        |               |   |     |   |     |   |
    //                                        1               F   F     F   F     F   F
    //                                       flag             rojo      verde     azul
    
    // Formato del cuadrado en 64 bits
    // 0x 0000 0000 0000 0000 0000 0000 0000 0000 1111 1111 1111 1111 0000 0000 0000 0000
    //   |  (32 bits) posicion del cuadrado      |(16 bits) posicion |  (16 bits) largo  |
    //                                              linea vertical 2      del cuadrado
    
    // Variables locales
    // x0 direccion base
    // x1 direccio del final
    // x2 largo de x
    // x3 largo de y
    // x4 largo del cuadrado 1
    // x5 largo del cuadrado 2
    // x6 color del tunel
    // x7 color del puente
    // x8 largo de la linea central
    
// Configuracion Inicial:
    mov x20, x0               // X0 contiene la direccion base del framebuffer
    movz x21,0x0012, lsl 16   // ultima posicion del framebuffer
    movk x21,0xbffc, lsl 00
 
    movz x22, 0x0009, lsl 48  // posicion inicial de los cuadrados (239*640+240)*4 = 612 800
    movk x22, 0x59c0, lsl 32  // posicion del cuadrado
    movk x22, 0x027c, lsl 16  // posicion de segunda linea (largo interno) (a0-1)*4
    movk x22, 0x00a0, lsl 00  // largo inicial del cuadrado (640-480) = 160
    
    mov x23,x22               // posicion inicial del primer cuadrado
    
    movz x24, 0x0004, lsl 48  // posicion inicial del cuadrado 2 (119*640+(320-200))*4 = 305 120
    movk x24, 0xa7e0, lsl 32  // posicion del cuadrado
    movk x24, 0x063c, lsl 16  // posicion de segunda linea (largo interno) (400-1)*4 =  1596 posiciones de memoria
    movk x24, 0x0190, lsl 00  // largo inicial del cuadrado (640-480/2) = 400  pixeles  
    
    movz x26, 0x0060, lsl 0   // flag , color inicial del tunel
    mov x27,XZR               // flag , color inicial del puente
   
// Ciclo Principal:
nuevo_frame:                   //PINTAR EL FRAME      
    mov x0, x20                // posicion inicial del array
    add x1, x0, x21            // posicion del ultimo pixel del array
    mov x3, SCREEN_HEIGH       // tamaño de Y 
    and x4, x23, 0xffff        // largo del cuadrado 1
    and x5, x24, 0xffff        // largo del cuadrado 2
    mov x6, x26                // color inicial tunel
    mov x7, x27                // color inicial puente
    movz x8, 0x009e, lsl 00    // largo inicial de la linea
    
    lsr x10, x23 , 32
    add x10, x0, x10           // posicion del inicio del cuadrado 1
    add x11, x10, 2560         // posicion primera linea vertical
    lsr x12, x23, 16
    and x12, x12, 0xffff
    add x12,x12,x11            // posicion segunda linea vertical
    
    lsr x13, x24 , 32
    add x13, x0, x13           // posicion del inicio del cuadrado 2
    add x14, x13, 2560         // posicion primera linea vertical
    lsr x15, x24, 16
    and x15, x15, 0xffff
    add x15,x15,x14            // posicion segunda linea vertical
 
    movz x16,0x0008, lsl 00    // posicion inicial de las diagonal 1
    add x16, x0, x16 
    
    movz x17,0x09f4, lsl 00    // posicion inicial de la diagonal 2
    add x17, x0, x17
    
    movz x18, 0x0009, lsl 16   // posicion inicial de la linea cerntal
    movk x18, 0x59c4, lsl 00
    add x18, x0,x18
    
    mov x29, x6                // color inicial
 
nuevo_renglon:
    mov x2, SCREEN_WIDTH       // tamaño de X

nuevo_pixel:
    mov x28, x6                // color inicial 
    
box1_horizontal:               // cuadrado interno
    cmp x0,x10
    b.ne box1_vertical_01      // chequeo si pinto la linea horizontal
    stur WZR, [x0]             // pinto negro 
    stur WZR, [x1]             // pinto negro
    sub x4, x4, 1             
    cbz x4, descontar_contadores
    add x10, x10, 4            // x10 copia a x0 asta acabar la linea
    b descontar_contadores    
box1_vertical_01:              // cheque si es el pixel de la primera linea vertical
    cmp x0,x11
    b.ne box1_vertical_02      // si no lo es sigo chequeando
    stur WZR, [x0]             // pinto de negro
    stur WZR, [x1]             // pinto de negro
    add x11, x11, 2560         // cada vez que pinto un pixel cambio al siguiente
    b descontar_contadores
box1_vertical_02:              // chequeo si es el pixel de la segunda linea verical
   cmp x0,x12
    b.ne box2_horizontal       // si no lo es entonces es un color del degrade
    stur WZR, [x0]             // pinto de negro
    stur WZR, [x1]             // pinto de negro
    add x12, x12, 2560         // cada vez que pinto un pixel cambio al siquiente
    b descontar_contadores

box2_horizontal:   
    cmp x0,x13
    b.ne box2_vertical_01      // chequeo si pinto la linea horizontal
    stur WZR, [x0]             
    stur WZR, [x1]
    sub x5, x5, 1               
    cbz x5,descontar_contadores
    add x13, x13, 4            // x10 copia a x0 asta acabar la linea
    b descontar_contadores    
box2_vertical_01:              // cheque si es el pixel de la primera linea vertical
    cmp x0,x14
    b.ne box2_vertical_02      // si no lo es sigo chequeando
    stur WZR, [x0]
    stur WZR, [x1] 
    add x14, x14, 2560         // cada vez que pinto un pixel cambio al siguiente
    b descontar_contadores
box2_vertical_02:              // chequeo si es el pixel de la segunda linea verical
    cmp x0,x15
    b.ne linea_central         // si no lo es entonces es un color del degrade       
    stur WZR, [x0]             // pinto de negro
    stur WZR, [x1]
    add x15, x15, 2560         // cada vez que pinto un pixel cambio al siquiente
    b descontar_contadores

linea_central:                 // cuadrado interno
    cmp x0,x18
    b.ne diagonal1             // chequeo si pinto la linea horizontal
    stur w28, [x0]             
    stur WZR, [x1]              
    sub x8, x8, 1             
    cbz x8, descontar_contadores
    add x18, x18, 4            // x10 copia a x0 asta acabar la linea
    b descontar_contadores        

diagonal1:
    cmp x0,x16
    b.ne diagonal2              
    stur w28, [x0]             // pinto el pixel superior de un color
    stur WZR, [x1]             // pinto el pixel inferior de otro
    mov x29, x7                // cambio al color del puente
    b descontar_contadores
    
diagonal2:
    cmp x0,x17
    b.ne pintar_degrade         
    stur w28, [x0]             
    stur WZR, [x1]
    mov x29, x6                // cambio al color del tunel
    b descontar_contadores
    
pintar_degrade:
    stur w28, [x0]             // pinto el degrade
    stur w29, [x1]
    
descontar_contadores:
    add x0, x0, 4              // siguiente pixel
    sub x1, x1, 4              // siguiente pixel
    sub x2, x2, 1              // descuento un pixel pintado en X
    cbnz x2, nuevo_pixel       // si X no es 0, pinto el siguiente pixel
    
    add x16, x16, 2564         // inclinacion de las diagonales
    add x17, x17, 2556

    mov x19, x6               
    bl cambiar_color           // degrade del tunel
    mov x6, x19               
    
    mov x19, x7                
    bl cambiar_color           // degrade del puente
    mov x7, x19 
    
    sub x3, x3, 2              // descuento un renglon pintado a Y
    cbnz x3, nuevo_renglon     // si Y no es 0, pinto el siguiente renglon
                        
                               // TERMINO DE PINTAR, CAMBIOS PARA EL PROXIMO FRAME
    mov x19, x23         
    bl aumento_cuadrado        // cuadrado 1
    mov x23, x19
    
    mov x19, x24
    bl aumento_cuadrado        // cuadrado 2
    mov x24, x19
    
    mov x19, x26               
    bl cambiar_color           // cabio el color inicial de los extremos tunel
    mov x26, x19  
    
    mov x19, x27               
    bl cambiar_color           // cabio el color inicial de los extremos puente
    mov x27, x19 
                         
    bl diley_loop              // DILEY

    b nuevo_frame              // PINTAR UN NUEVO FRAME
    
// Funcines:

cambiar_color:
    lsr x9, x19, 32
    cbz x9, color_up           // si es 0 el color esta creciendo
    b color_down               // sino el color esta decreciendo
    
color_up:
    and x9, x19, 0x00ff        // extraigo el valor del azul
    cmp x9, 0x00ff             // comparo si llego a su maximo
    b.eq azul_full
    add x19, x19, 1            // sumo y devuelvo el valor en x19
    br lr                      // retorno al ciclo principal
 azul_full:
    lsr x9, x19, 8             // quito el azul
    and x9, x9, 0x000ff        // quito el rojo y queda el verde
    cmp x9, 0x00ff             // comparo si llego a su maximo
    b.eq verde_full
    add x19, x19, 256          // 256 = 0x0100
    br lr
verde_full:
    lsr x9, x19, 16            // quito el verde y el azul
    and x9, x9, 0x000ff        // quito el flag
    cmp x9, 0x00ff             // comparo si llego a su maximo
    b.eq rojo_full
    add x19, x19, 65536        // 65536 = 0x01 0000
    br lr
rojo_full:
    movk x19, 0x01, lsl 32     // si llegamos hasta aca entonces el color es balnco
    br lr

color_down:                    // vamos del 0xFF FFFF asta 0x00 0000
    and x9, x19, 0x00ff        //  azul   
    cmp x9, 0x0000
    b.eq azul_null
    sub x19, x19, 1
    br lr
azul_null:
    lsr x9, x19,8              // trabajamos el verde
    and x9, x9, 0x00ff
    cmp x9, 0x0000             // comparo si es el minimo
    b.eq verde_null
    sub x19, x19, 256          // 256 = 0x0100
    br lr
verde_null:
    lsr x9, x19, 16            // rojo
    and x9, x9, 0x00ff         // quito el flag
    cmp x9, 0x0000             // comparo si es el minimo 
    b.eq rojo_null
    sub x19, x19, 65536        // 65536 = 0x01 0000
    br lr
rojo_null:                     // si llegamos hasta aca el color es 0x00 0000
    movk x19, 0x00, lsl 32     // cambiamos el flag para que cresca el color
    br lr
 
aumento_cuadrado: 
    mov x9,x19                 // largo del cuadrado
    and x9, x9, 0xffff
    cmp x9, SCREEN_WIDTH       // si llego al ancho de la pantalla reinicio el cuadrado
    b.eq reinicio_cuadrado
    movz x9, 0x0a04, lsl 32
    sub x19, x19, x9           // resto la pocion origen del cuadrado
    movz x9, 0x0008, lsl 16
    add x19, x19, x9
    add x19, x19, 2            // aumento 2 al largo del cuadrado
    br lr
reinicio_cuadrado:
    mov x19, x22               // vuelvo a la posicion inicial de los cuadrados 
    br lr
    
diley_loop:
    mov x8, DILEY_REPETITION   // sirve para repetir el diley y bajar mas la velocidad
diley_loop_02:
    mov x9, DILEY_AMOUNT       // cargo en x9 el valor del diley
diley_loop_01:
    sub x9, x9, 1              // se queda restando hasta que llege a 0
    cbnz x9, diley_loop_01
    sub x8, x8, 1              // se queda restando hasta que llege a 0
    cbnz x8, diley_loop_02
    br lr
