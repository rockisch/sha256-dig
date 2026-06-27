# Atividade Prática 2

Este projeto consiste na modelagem e implementação em hardware de um núcleo criptográfico **SHA-256 (Secure Hash Algorithm de 256 bits)** utilizando a linguagem **VHDL**. O sistema é capaz de receber um bloco de mensagem de **512 bits** e calcular o seu hash correspondente de **256 bits** através de uma arquitetura síncrona.

---

# Equipe

- **Otavio Patricio Goulart** — Matrícula: **25204059**
- **João Carneiro Haas** - Matrícula: **25204064**
- **João Henrique dos Santos Chalegre** - Matrícula: **25203061**
- **Vinicius Rodrigues Duarte** Matrícula: **25203682**

---

# Descrição

O circuito foi desenvolvido adotando as melhores práticas de projeto de hardware, separando a lógica em uma **Base de Controle (Unidade de Controle)** e uma **Base Operativa (Fluxo de Dados)**. O encapsulamento final é realizado pelo arquivo de nível superior **`sha256.vhdl`**, responsável por instanciar e conectar ambas as bases.

A arquitetura é composta pelos seguintes módulos:

## Base de Controle (`sha256_bc.vhdl`)

Implementada como uma **Máquina de Estados Finitos (FSM)** com cinco estados principais:

- `S_IDLE`
- `S_INIT`
- `S_R1`
- `S_R2`
- `S_DONE`

A FSM é responsável por coordenar toda a execução do algoritmo, determinando o momento em que a Base Operativa deve:

- carregar os dados e a mensagem na janela;
- executar as 64 rodadas, cada uma dividida em dois subestados (`S_R1`/`S_R2`);
- sinalizar o término da operação.

Cada rodada é dividida em `S_R1` e `S_R2` para encurtar o caminho crítico. A expansão da mensagem (*Message Schedule*) e a compressão são intercaladas dentro do mesmo laço de rodadas, em vez de serem etapas separadas.

---

## Base Operativa (`sha256_bo.vhdl`)

É o módulo responsável pelo processamento do algoritmo SHA-256.

Contém:

- a janela deslizante `W` de 16 palavras utilizada pelo **Message Schedule**;
- registradores de trabalho `a`, `b`, `c`, `d`, `e`, `f`, `g` e `h`.

A janela `W` guarda apenas 16 palavras (em vez das 64 do algoritmo padrão), com taps fixos (W(0)=i-16, W(1)=i-15, W(9)=i-7, W(14)=i-2). Isso evita o multiplexador de leitura 64:1 e o decodificador de escrita de 64 vias que a memória completa exigiria. A cada rodada a janela é deslocada uma posição e a nova palavra entra no fim.

As operações de uma rodada se distribuem em dois subestados. Em `S_R1` calcula-se a palavra do schedule `wt`, a soma parcial `temp1_part` (h + Σ1(e) + Ch + K[i]) e `temp2` (Σ0(a) + Maj). Em `S_R2` completa-se `temp1 = temp1_part + wt` e atualizam-se os registradores de trabalho.

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

O trecho abaixo mostra os dois subestados de uma rodada. Em `S_R1` calculam-se a palavra do schedule e as somas parciais; em `S_R2` completa-se `temp1` e atualizam-se os registradores.

```vhdl
elsif c_r1 = '1' then
    loop_i := to_integer(loop_count);

    -- Funções auxiliares combinatórias (small sigma, big sigma, ch e maj)
    s0     := sha_ssig0(W(1));
    s1     := sha_ssig1(W(14));
    s0_big := sha_bsig0(a);
    s1_big := sha_bsig1(e);
    ch     := sha_ch(e, f, g);
    maj    := sha_maj(a, b, c);

    -- Palavra do schedule: direto da mensagem nas 16 primeiras rodadas,
    -- depois pela recorrência lida em posições fixas da janela
    if loop_count < 16 then
        wt := W(0);
    else
        wt := std_logic_vector(unsigned(W(0)) + unsigned(s0) + unsigned(W(9)) + unsigned(s1));
    end if;

    temp1_part := std_logic_vector(unsigned(h) + unsigned(s1_big) + unsigned(ch) + unsigned(K(loop_i)));
    temp2      := std_logic_vector(unsigned(s0_big) + unsigned(maj));

    -- Desloca a janela uma posição e insere a palavra atual no fim
    for j in 0 to 14 loop
        W(j) <= W(j + 1);
    end loop;
    W(15) <= wt;

elsif c_r2 = '1' then
    temp1 := std_logic_vector(unsigned(temp1_part) + unsigned(wt));
    h := g;
    g := f;
    f := e;
    e := std_logic_vector(unsigned(d) + unsigned(temp1));
    d := c;
    c := b;
    b := a;
    a := std_logic_vector(unsigned(temp1) + unsigned(temp2));
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
├── sha256.vhdl              # Top-Level do núcleo
├── sha256_bc.vhdl           # Base de Controle (FSM)
├── sha256_bo.vhdl           # Base Operativa (Datapath)
├── counter64.vhdl           # Contador das 64 rodadas
├── sha256_pkg.vhdl          # Tipos e funções auxiliares do SHA-256
├── sha256_tb.vhdl           # Testbench do núcleo
├── sha256_adaptor.vhdl      # Adaptador (recebe a mensagem em fatias de 128 bits)
├── sha256_adaptor_bc.vhdl   # Base de Controle do adaptador (FSM)
└── sha256_adaptor_tb.vhdl   # Testbench do adaptador
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
R1 ──► R2 ──┐  (64 rodadas: R2 volta para R1 até o contador estourar)
  ▲         │
  └─────────┘
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
