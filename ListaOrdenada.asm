# Constantes
.eqv index  $t0
.eqv char   $s0
.eqv digit  $s1
.eqv num    $s2
.eqv multiplicador $t1
.eqv index_sw $t2

.data
File: .asciiz "lista.txt"      # Arquivo para ler
Fout: .asciiz "lista_out.txt"      # Arquivo de saída
buffer: .space 500
        .align 2
lista_numeros: .space 400
n: .word 100
str:   .space 128         # bytes for string version of the number
comma: .asciiz ","
newline: .asciiz "\n"
.text


# Abrir e ler arquivo
li   $v0, 13          # system call abrir arquivo
la   $a0, File        # Nome do arquivo
li   $a1, 0           # flag de leitura
li   $a2, 0           # Ignorar modo
syscall
move $s3, $v0         # Salvar file descriptor

# Ler números do arquivo
li $v0, 14                      # syscall read
move $a0, $s3
la $a1, buffer
li $a2, 500
syscall

li  index, 0
li  index_sw, 0

init:
    li  multiplicador, 1
    li  num, 0


for:
	lb	char, buffer(index)	
	add	index, index, 1
	beq	char,$zero, armazena 
	beq	char, ',',armazena
	beq	char, '-', sinal
	sub	digit, char, 0x30
	mul	num, num, 10
	add	num, num, digit
	j	for

armazena:
	mul	num, num, multiplicador
	sw	num, lista_numeros(index_sw)
	add	index_sw, index_sw, 4
	beq	char,$zero, exit 
	j	init

sinal:
    li  multiplicador, -1
    j for

exit:
# Fechar o arquivo de entrada
li $v0, 16
move $a0, $s3
syscall

main:
    la $a0, lista_numeros
    lw $a1, n
    jal bubblesort
    j out

bubblesort:
    # Reservar espaço na pilha para salvar $ra e $a1
    addi $sp, $sp, -8
    sw $ra, 4($sp)      # Salvar $ra na pilha
    sw $a1, 0($sp)      # Salvar $a1 na pilha

    move $t0, $a0        # $t0 = endereço inicial da lista
    move $t1, $a1        # $t1 = número de elementos na lista

outer_loop:
    addi $t1, $t1, -1    # Decrementar contador do loop externo
    blez $t1, end_outer_loop   # Se $t1 <= 0, terminar o loop externo
    move $t2, $t0        # $t2 = $t0 (inicialização do loop interno)
    move $t3, $t1        # $t3 = $t1 (número de iterações do loop interno)

inner_loop:
    lw $t4, 0($t2)      # $t4 = valor atual
    lw $t5, 4($t2)      # $t5 = próximo valor
    ble $t4, $t5, skip_swap   # Se $t4 <= $t5, pule para skip_swap
    sw $t5, 0($t2)      # Trocar valores: armazenar $t5 na posição atual
    sw $t4, 4($t2)      # Trocar valores: armazenar $t4 na próxima posição

skip_swap:
    addi $t2, $t2, 4    # Avançar para a próxima posição
    addi $t3, $t3, -1   # Decrementar contador do loop interno
    bgtz $t3, inner_loop   # Se $t3 > 0, continuar o loop interno

    j outer_loop        # Voltar ao início do loop externo

end_outer_loop:
    lw $ra, 4($sp)      # Restaurar $ra da pilha
    lw $a1, 0($sp)      # Restaurar $a1 da pilha
    addi $sp, $sp, 8    # Liberar espaço na pilha
    jr $ra              # Retornar ao endereço de retorno


out:

    la $t0, lista_numeros                           # Carrega o endereço do array em $t0
    lw $t1, n                                       # Carrega o tamanho do array em $t1
    la $a0, Fout                                    # Carrega o endereço do arquivo de saída em $a0
    li $a1, 1                                       # Abre para escrita
    li $v0, 13                                      # Chamada de sistema para abrir arquivo
    syscall
    move $s6, $v0                                   # Salva o descritor do arquivo

loop:
    beqz $t1, end_loop                              # Se $t1 == 0, encerra o loop
    lw $a0, 0($t0)                                  # Carrega o elemento atual do array em $a0
    la $a1, str                                     # Carrega o endereço da string em $a1
    jal int2str                                     # Chama a função int2str

    # Escreve a string no arquivo
    move $a0, $s6                                   # Descritor do arquivo
    la $a1, str                                     # Endereço da string
    li $a2, 128                                     # Tamanho da string
    li $v0, 15                                      # Chamada de sistema para escrever no arquivo
    syscall

    # Escreve uma vírgula no arquivo, exceto para o último elemento
    addi $t0, $t0, 4                                # Move para o próximo elemento do array
    addi $t1, $t1, -1                               # Decrementa o tamanho
    beqz $t1, end_write                             # Se $t1 == 0, pula para end_write
    move $a0, $s6                                   # Descritor do arquivo
    la $a1, comma                                   # Endereço da vírgula
    li $a2, 1                                       # Tamanho da vírgula
    li $v0, 15                                      # Chamada de sistema para escrever no arquivo
    syscall

    j loop                                          # Volta para o início do loop

end_write:
    # Escreve uma nova linha no arquivo
    move $a0, $s6                                   # Descritor do arquivo
    la $a1, newline                                 # Endereço da nova linha
    li $a2, 1                                       # Tamanho da nova linha
    li $v0, 15                                      # Chamada de sistema para escrever no arquivo
    syscall

end_loop:
    # Fecha o arquivo
    move $a0, $s6                                   # Descritor do arquivo
    li $v0, 16                                      # Chamada de sistema para fechar o arquivo
    syscall

    j exitInt       

int2str:
addi $sp, $sp, -4         # to avoid headaches save $t- registers used in this procedure on stack
sw   $t0, ($sp)           # so the values don't change in the caller. We used only $t0 here, so save that.
bltz $a0, neg_num         # is num < 0 ?
j    next0                # else, goto 'next0'

neg_num:                  # body of "if num < 0:"
li   $t0, '-'
sb   $t0, ($a1)           # *str = ASCII of '-' 
addi $a1, $a1, 1          # str++
li   $t0, -1
mul  $a0, $a0, $t0        # num *= -1

next0:
li   $t0, -1
addi $sp, $sp, -4         # make space on stack
sw   $t0, ($sp)           # and save -1 (end of stack marker) on MIPS stack

push_digits:
blez $a0, next1           # num < 0? If yes, end loop (goto 'next1')
li   $t0, 10              # else, body of while loop here
div  $a0, $t0             # do num / 10. LO = Quotient, HI = remainder
mfhi $t0                  # $t0 = num % 10
mflo $a0                  # num = num // 10  
addi $sp, $sp, -4         # make space on stack
sw   $t0, ($sp)           # store num % 10 calculated above on it
j    push_digits          # and loop

next1:
lw   $t0, ($sp)           # $t0 = pop off "digit" from MIPS stack
addi $sp, $sp, 4          # and 'restore' stack

bltz $t0, neg_digit       # if digit <= 0, goto neg_digit (i.e, num = 0)
j    pop_digits           # else goto popping in a loop

neg_digit:
li   $t0, '0'
sb   $t0, ($a1)           # *str = ASCII of '0'
addi $a1, $a1, 1          # str++
j    next2                # jump to next2

pop_digits:
bltz $t0, next2           # if digit <= 0 goto next2 (end of loop)
addi $t0, $t0, '0'        # else, $t0 = ASCII of digit
sb   $t0, ($a1)           # *str = ASCII of digit
addi $a1, $a1, 1          # str++
lw   $t0, ($sp)           # digit = pop off from MIPS stack 
addi $sp, $sp, 4          # restore stack
j    pop_digits           # and loop

next2:
sb  $zero, ($a1)          # *str = 0 (end of string marker)

lw   $t0, ($sp)           # restore $t0 value before function was called
addi $sp, $sp, 4          # restore stack
jr  $ra                   # jump to caller

exitInt:
    li $v0, 10   
    syscall       