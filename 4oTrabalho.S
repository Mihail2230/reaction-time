; Ficheiro:  4ºTrabalho.S
; Descricao: Programa do 4º Trabalho.
; Autor:     Mihail Arcus (nº50870) e Paulo Torres (nº50867) 
; Data:      9-6-2023

; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	CPSR_BIT_I, 0b010000          ; Mascara para o bit I do registo CPSR

	.equ	STACK_SIZE, 64                ; Dimensao do stack - 64 B

	; Definicoes do porto de entrada
	.equ	INPORT_ADDRESS, 0xFF80        ; Endereco do porto de entrada FF80

	; Definicoes do porto de saida
	.equ	OUTPORT_ADDRESS, 0xFFC0       ; Endereco do porto de saida FFC0

	.equ	OUTPORT_INIT_VAL, 0           ; Valor inicial do porto de saida

	; Definicoes do circuito pTC

	.equ	PTC_ADDRESS,  0xFF00         ; Endereco do circuito pTC FF00


	.equ	PTC_TCR, 0                    ; Deslocamento do registo TCR do pTC
	.equ	PTC_TMR, 2                    ; Deslocamento do registo TMR do pTC
	.equ	PTC_TC,  4                    ; Deslocamento do registo TC do pTC
	.equ	PTC_TIR, 6                    ; Deslocamento do registo TIR do pTC

	.equ	PTC_CMD_START, 0              ; Comando para iniciar a contagem no pTC
	.equ	PTC_CMD_STOP, 1               ; Comando para parar a contagem no pTC

	;Definições das frequencias do temporizador
	.equ	SYSCLK_FREQ, 0x000A   ;Lê a cada segundo    
	.equ	SYSCLK_FREQ2, 0x0001	;Lê a cada 0,1 segundos


	.section startup

	b	_start
	ldr	pc, isr_addr
_start:
	ldr	sp, tos_addr
	ldr	pc, main_addr

tos_addr:
	.word	tos
main_addr:
	.word	main
isr_addr:
	.word	isr

	.text

;R3 - variavel auxiliar
;R4 - variavel auxiliar
;R5 - guarda o tempo que o utilizador definiu

main:
	push r5
main_loop:
;bits todos a 1
    mov r0, #0xFF
    bl outport_write
;User 1 ou 0
	bl inport_read
    mov r1, #1
    and r2, r1, r0
    cmp r2, r1
    bne main_loop
;Inicialização
	mov r3, #0
	ldr r1, SYSCLK_ADDR2
	str r3, [r1,#0]
    mov r0, #1
    bl outport_write
    mov	r0, #SYSCLK_FREQ
	bl	ptc_init
	mrs	r0, cpsr
	mov	r1, #CPSR_BIT_I
	orr	r0, r0, r1
	msr	cpsr, r0
	mov r3, #0
	ldr r1, SYSCLK_ADDR
	str r3, [r1,#0]
main_loop2:

;Ler user 1 ou 0
    bl inport_read
    mov r1, #1
    and r2, r1, r0
    cmp r2, r1
    bne main

;Ler timer
	bl inport_read
	lsr r0, r0, #4
	mov r5, r0

;Ler variavel global/contador
	ldr r1, SYSCLK_ADDR
	ldrb r3, [r1,#0]

;Compara variavel global com timer
	cmp r3, r5
	Blo main_loop2

;Inicializar o contador
	push r4
    mov r3, #0
	mov r4, #1

;Contador a 0
	ldr r1, SYSCLK_ADDR
	strb r3, [r1,#0]

	bl ptc_stop
	mov r0, #SYSCLK_FREQ2
	bl ptc_init

;Estimulo a 0
	mov r0, #0
	bl outport_write

	mov r5, #1
	
loop:
;Fica em loop enquanto user for 1
    bl inport_read
    and r5 , r4, r0
    cmp r5, r4
    beq loop
;Vai buscar o valor do contador e apresenta o tempo do estimulo a 0,1 segundos
	ldr r1, SYSCLK_ADDR
	ldrb r0, [r1, #0]
	lsl r0, r0, #1
    bl outport_write
	pop r4
	pop r5
;Reniciar o temporizador a cada segundo
	bl ptc_stop
	mov r0, #SYSCLK_FREQ
	bl ptc_init
	mov r3, #0
	ldr r1, SYSCLK_ADDR
	strb r3, [r1,#0]
resultado_loop:
;Apresenta o resultado por 5 segundos
	mov r0, #5
	ldrb r2, [r1,#0]
	cmp r2, r0
    blo resultado_loop
	b main

SYSCLK_ADDR2:
	.word SYSCLK_ADDR

; Rotina:    isr
; Descricao: Incrementa o valor da variável global sysclk.
isr:

	push r0
	push r1
	push r2

	ldr r0, SYSCLK_ADDR
	ldr r1, [r0, #0]
	add r1, r1, #1
	str r1, [r0, #0]

	mov r2, #0
	ldr r0, PTC_ADDR
	strb r2, [r0, #PTC_TIR]

	pop r2
	pop r1
	pop r0
	movs pc, lr

SYSCLK_ADDR:
	.word	sysclk

inport_read:
	ldr	r1, inport_addr
	ldrb	r0, [r1, #0]
	mov	pc, lr


inport_addr:
	.word	INPORT_ADDRESS

outport_write:
	ldr	r1, outport_addr
	strb	r0, [r1, #0]
	mov	pc, lr

outport_addr:
	.word	OUTPORT_ADDRESS

ptc_start:
	ldr	r0, PTC_ADDR
	mov	r1, #PTC_CMD_START
	strb	r1, [r0, #PTC_TCR]
	mov	pc, lr

ptc_stop:
	ldr	r0, PTC_ADDR
	mov	r1, #PTC_CMD_STOP
	strb	r1, [r0, #PTC_TCR]
	mov	pc, lr

ptc_init:

	push lr
	push r0

	bl ptc_stop

	pop r0
	ldr r1, PTC_ADDR
	strb r0,[r1, #PTC_TMR]

	bl ptc_start
	pop pc

PTC_ADDR:
	.word	PTC_ADDRESS

; Seccao:    bss
; Descricao: Guarda as variáveis globais sem valor inicial definido
;
	.bss

sysclk:
	.space	2

; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
tos:
