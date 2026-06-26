# Atividade Prática 2

Este projeto consiste na modelagem e implementação em hardware de um núcleo criptográfico **SHA-256 (Secure Hash Algorithm de 256 bits)** utilizando a linguagem **VHDL**. O sistema é capaz de receber um bloco de mensagem de **512 bits** e calcular o seu hash correspondente de **256 bits** através de uma arquitetura síncrona.

---

# Equipe

- **Otavio Patricio Goulart** — Matrícula: **25204059**
-
-
-

---

# Descrição

O circuito foi desenvolvido adotando as melhores práticas de projeto de hardware, separando a lógica em uma **Base de Controle (Unidade de Controle)** e uma **Base Operativa (Fluxo de Dados)**. O encapsulamento final é realizado pelo arquivo de nível superior **`sha256.vhdl`**, responsável por instanciar e conectar ambas as bases.

A arquitetura é composta pelos seguintes módulos:

## Base de Controle (`sha256_bc.vhdl`)

Implementada como uma **Máquina de Estados Finitos (FSM)** com cinco estados principais:

- `S_IDLE`
- `S_INIT`
- `S_SCHED`
- `S_COMP`
- `S_DONE`

A FSM é responsável por coordenar toda a execução do algoritmo, determinando o momento em que a Base Operativa deve:

- carregar os dados;
- expandir a mensagem (*Message Schedule*);
- executar as 64 rodadas de compressão;
- sinalizar o término da operação.

---

## Base Operativa (`sha256_bo.vhdl`)

É o módulo responsável pelo processamento do algoritmo SHA-256.

Contém:

- memória `W` utilizada pelo **Message Schedule**;
- registradores de trabalho `a`, `b`, `c`, `d`, `e`, `f`, `g` e `h`.

Durante cada ciclo de clock são executadas as operações principais do algoritmo, incluindo o cálculo dos valores temporários **T1** e **T2**, responsáveis pela atualização dos registradores de trabalho.

---

## Contador Inteligente (`counter64.vhdl`)

Contador reutilizável responsável por controlar as **64 rodadas** do algoritmo SHA-256.

Seu diferencial é a geração do sinal **`overflow`** de forma **puramente combinacional**, permitindo que a máquina de estados identifique imediatamente o término da contagem sem introduzir atrasos adicionais de sincronização.

---

## Pacote de Funções (`sha256_pkg.vhdl`)

Arquivo que centraliza todas as funções matemáticas exigidas pelo padrão SHA-256, incluindo:

- `Ch`
- `Maj`
- `Σ0`
- `Σ1`
- `σ0`
- `σ1`

Essa separação torna o código da Base Operativa mais limpo, organizado e modular.

---

# Exemplo de Código (Base Operativa)

O trecho abaixo mostra a atualização dos registradores durante o laço principal de compressão.

```vhdl
elsif c_loop_comp = '1' then
    loop_i := to_integer(loop_count);

    T1 := std_logic_vector(
            unsigned(h)
          + unsigned(sha_bsig1(e))
          + unsigned(sha_ch(e, f, g))
          + unsigned(K(loop_i))
          + unsigned(W(loop_i)));

    T2 := std_logic_vector(
            unsigned(sha_bsig0(a))
          + unsigned(sha_maj(a, b, c)));

    h := g;
    g := f;
    f := e;
    e := std_logic_vector(unsigned(d) + unsigned(T1));
    d := c;
    c := b;
    b := a;
    a := std_logic_vector(unsigned(T1) + unsigned(T2));
```

---

# Simulação

A validação do circuito foi realizada utilizando um **Testbench** (`sha256_tb.vhdl`), que injeta a string de teste `"abc"` juntamente com as constantes de inicialização definidas pelo padrão SHA-256.

Durante a simulação foram monitorados:

- a evolução da Máquina de Estados;
- os sinais internos do datapath;
- o sinal de finalização (`fin`).

Quando `fin` é ativado, o testbench aguarda **5 ns** para garantir a propagação completa do último ciclo de clock e imprime no console o hash final de **256 bits**, obtido pela concatenação dos oito registradores finais em formato hexadecimal.

O resultado produzido foi:

```text
BA7816BF8F01CFEA414140DE5DAE2223
B00361A396177A9CB410FF61F20015AD
```

Esse valor corresponde exatamente ao hash oficial da mensagem `"abc"` definido pelo padrão SHA-256, comprovando a corretude tanto da implementação do **Datapath** quanto da sincronização entre a Base de Controle e a Base Operativa.

---

# Estrutura do Projeto

```text
.
├── sha256.vhdl          # Top-Level
├── sha256_bc.vhdl       # Base de Controle (FSM)
├── sha256_bo.vhdl       # Base Operativa (Datapath)
├── counter64.vhdl       # Contador das 64 rodadas
├── sha256_pkg.vhdl      # Funções auxiliares do SHA-256
└── sha256_tb.vhdl       # Testbench
```

---

# Fluxo de Execução

```text
IDLE
  │
  ▼
INIT
  │
  ▼
SCHED
  │
  ▼
COMP (64 ciclos)
  │
  ▼
DONE
  │
  ▼
IDLE
```

---

# Principais Desafios Encontrados

## Sincronização dos sinais

Um dos maiores desafios encontrados durante o desenvolvimento foi o correto sincronismo entre o contador e a máquina de estados.

Inicialmente, o sinal `overflow` era registrado, provocando um atraso de um ciclo de clock. Como consequência, a Base Operativa ainda executava uma iteração adicional, ocasionando um erro de **index-out-of-bounds**, no qual o algoritmo tentava acessar posições inválidas da memória `W`.

A solução adotada foi implementar o `overflow` como um sinal **estritamente combinacional**, permitindo que a FSM encerrasse imediatamente o laço de compressão ao atingir a última rodada.

---

## Visualização da memória W

Outro desafio foi a limitação dos simuladores na exibição de sinais bidimensionais.

Arquivos de ondas no formato **`.vcd`**, visualizados pelo **EPWave**, apresentam dificuldades para renderizar corretamente estruturas como a memória `W` e o vetor de saída `H`.

Como alternativa, utilizou-se a função:

```vhdl
report to_hstring(...)
```

para imprimir diretamente no console os valores relevantes durante a simulação, tornando o processo de depuração significativamente mais confiável.

---

# Resultado

Arquitetura modular dividida em Base de Controle e Base Operativa.

Implementação completa do algoritmo SHA-256 em VHDL.

Execução correta das 64 rodadas de compressão.

Hash gerado idêntico ao resultado oficial para a mensagem de teste `"abc"`.

Projeto validado por simulação utilizando Testbench.
