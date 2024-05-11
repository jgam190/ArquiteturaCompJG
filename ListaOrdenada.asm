# Constantes
.eqv index  $t0
.eqv char   $s0
.eqv digit  $s1
.eqv num    $s2
.eqv multiplicador $t1
.eqv index_sw $t2

.data
File: .asciiz "lista.txt"      # Arquivo para leitura
Fout: .asciiz "lista_ordenada.txt"      # Arquivo de saída
buffer: .space 500
        .align 2
lista_numeros: .space 400
n: .word 100
str:   .space 5       # bytes para a versão string do número
comma: .asciiz ","
newline: .asciiz "\n"
.text

# Abrir e ler arquivo
li   $v0, 13          # chamada de sistema para abrir arquivo
la   $a0, File        # nome do arquivo
li   $a1, 0           # flag de leitura
li   $a2, 0           # ignorar modo
syscall
move $s3, $v0         # salvar descritor de arquivo

# Ler números do arquivo
li $v0, 14                      # chamada de sistema para leitura
move $a0, $s3
la $a1, buffer
li $a2, 500
syscall

li  index, 0
li  index_sw, 0

init:
    li  multiplicador, 1
    li  num, 0

# Loop para ler cada caractere do buffer
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

# Armazenar o número na memória
armazena:
	mul	num, num, multiplicador
	sw	num, lista_numeros(index_sw)
	add	index_sw, index_sw, 4
	beq	char,$zero, exit 
	j	init

# Tratar sinal negativo
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

# Algoritmo de ordenação Bubble Sort
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

loop:
    beqz $t1, end_loop                              # Se $t1 == 0, encerra o loop
    lw $a0, 0($t0)                                  # Carrega o elemento atual do array em $a0
    la $a1, str                                     # Carrega o endereço da string em $a1
    jal int2str                                     # Chama a função int2str

    addi $t0, $t0, 4                                # Move para o próximo elemento do array
    addi $t1, $t1, -1                               # Decrementa o tamanho
    j loop                                          # Volta para o início do loop

end_loop:
    # Continua com o resto do código

# Função para converter um número inteiro em uma string
int2str:
    addi $sp, $sp, -4         # para evitar problemas, salve os registradores $t- usados neste procedimento na pilha
    sw   $t0, ($sp)           # para que os valores não mudem no chamador. Usamos apenas $t0 aqui, então salve isso.
    bltz $a0, neg_num         # o número é < 0 ?
    j    next0                # senão, vá para 'next0'

neg_num:                  # corpo de "se num < 0:"
    li   $t0, '-'
    sb   $t0, ($a1)           # *str = ASCII de '-' 
    addi $a1, $a1, 1          # str++
    li   $t0, -1
    mul  $a0, $a0, $t0        # num *= -1

next0:
    li   $t0, -1
    addi $sp, $sp, -4         # faça espaço na pilha
    sw   $t0, ($sp)           # e salve -1 (marcador de fim de pilha) na pilha do MIPS

push_digits:
    blez $a0, next1           # num < 0? Se sim, encerra o loop (vá para
    li   $t0, 10              # caso contrário, corpo do loop while aqui
    div  $a0, $t0             # faça num / 10. LO = Quociente, HI = resto
    mfhi $t0                  # $t0 = num % 10
    mflo $a0                  # num = num // 10  
    addi $sp, $sp, -4         # faça espaço na pilha
    sw   $t0, ($sp)           # armazene num % 10 calculado acima na pilha
    j    push_digits          # e loop

next1:
    lw   $t0, ($sp)           # $t0 = retira "dígito" da pilha MIPS
    addi $sp, $sp, 4          # e 'restaura' pilha

bltz $t0, pop_digits      # se dígito <= 0, vá para pop_digits (ou seja, num = 0)

neg_digit:
    li   $t0, '0'
    sb   $t0, ($a1)           # *str = ASCII de '0'
    addi $a1, $a1, 1          # str++
    j    next2                # pule para next2

pop_digits:
    bltz $t0, next2           # se dígito <= 0 vá para next2 (fim do loop)
    addi $t0, $t0, '0'        # caso contrário, $t0 = ASCII do dígito
    sb   $t0, ($a1)           # *str = ASCII do dígito
    addi $a1, $a1, 1          # str++
    lw   $t0, ($sp)           # dígito = retira da pilha MIPS
    addi $sp, $sp, 4          # restaura pilha
    j    pop_digits           # e loop

next2:
    sb  $zero, ($a1)          # *str = 0 (marcador de fim de string)

    # Calcular o tamanho da string
    la $t0, str
    sub $v0, $a1, $t0

    lw   $t0, ($sp)           # restaura valor $t0 antes da função ser chamada
    addi $sp, $sp, 4          # restaura pilha
    jr  $ra                   # pule para o chamador


 la $t0, lista_numeros                # Carrega o endereço base do array
    lw $t1, n                 # Carrega o tamanho do array

 # Abre o arquivo para escrita
    la $a0, Fout                 # Endereço do nome do arquivo
    li $a1, 1                    # Modo de abertura (1 para escrita)
    li $v0, 13                   # Código do sistema para abrir um arquivo
    syscall                      # Abre o arquivo
    move $s6, $v0                # Salva o descritor do arquivo

loopWrite:
    lw $a1, 0($t0)               # Carrega o valor do array no $a1
    la $t2, str                  # Carrega o endereço da string em $t2
    jal int2str                  # Chama a função int2str
    move $t3, $v0                # Salva o tamanho da string

    move $a0, $s6                # Descritor do arquivo
    move $a1, $t2                # Dados a serem escritos
    move $a2, $t3                # Tamanho dos dados a serem escritos
    li $v0, 15                   # Código do sistema para escrever em um arquivo
    syscall                      # Escreve no arquivo

exitWrite:
    move $a0, $s6                # Descritor do arquivo
    li $v0, 16                   # Código do sistema para fechar um arquivo
    syscall                      # Fecha o arquivo

    li $v0, 10                   # Código do sistema para sair
    syscall                      # Finaliza o programa
