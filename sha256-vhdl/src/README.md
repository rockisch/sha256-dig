# Projeto SHA-256 VHDL

Implementação do algorítmo SHA-256 em VHDL.

---

# Equipe

- **Otavio Patricio Goulart** — Matrícula: **25204059**
- **João Carneiro Haas** - Matrícula: **25204064**
- **João Henrique dos Santos Chalegre** - Matrícula: **25203061**
- **Vinicius Rodrigues Duarte** Matrícula: **25203682**

---

# Descrição

Este projeto implementa o algoritmo SHA-256 como um componente VHDL. A implementação utiliza a separação entre bloco operativo e bloco de controle visto em aula.

O componente recebe como input o chunk (`chunk[512]`) e o estado (`h_in[256]`) atual, e retorna o próximo estado (`h_out[256]`). Enquanto seria possível definir uma interface com somente o chunk de input e o h_out de output, a implementação escolhida possibilita o cálculo do hash para mensagens maiores do que 447 bits sem atrelar o mesmo a nenhum modelo específico de acesso a memória.

Devido a esse modelo, é responsabilidade de quem executa o algorítmo garantir que os valores de 'h_in' e 'chunk' sigam a especificação do SHA-256. Mais especificamente, 'h_in' deve ter como valor inicial algunas constantes; depois de cada processamento do chunk 'h_in' deve receber 'h_out'; e o ultimo 'chunk' deve receber um 'padding' especial.

> [!NOTE]
> O número 447 vem do fato que o algorítmo requer que no mínimo 1 + 64 bits sejam 'apendados' no fim da mensagem. Portanto, qualquer bloco maior do que 447 bits irá necessariamente requerer 2 processamentos de chunk.

## Algorítmo

No geral, o algorítmo foi baseado na parte de processamento de chunk do pseudocódigo disponivel na página da wikipédia: https://en.wikipedia.org/wiki/SHA-2#Pseudocode

Uma modificação consideravel que foi feita foi mudar o 'message schedule' ('w') para ser um 'sliding window' dos ultimos 16 valores, ao invés de ser um array de 64 valores populados no começo do algorítmo. Inicialmente haviamos feito como no algorítmo, mas como precisavamos indexar esse valor depois, isso acabou criando um mux 64:1, o que deixou muito dificil a implementação do datapath.

Porém, olhando o algorítmo de população, é possivel ver que o valor `w[i]` só depende dos ultimos 16 valores, e o uso de 'w' depois é incremental. Portanto, é possivel sempre calcular o 'proximo' valor de 'w' a medida que o mesmo é requerido desde que os ultimos 16 valores de 'w' tenham sido salvos.

Além dessa optimização, também foi separado o cálculo de 'temp1' entre 2 clocks para a redução do caminho crítico, já que precisamos calcular o 'w' no mesmo clock que o algorítmo original faz o 'assignment' para 'temp1'.

## FSM

O bloco de controle define esses estados:

- `S_IDLE`
- `S_INIT`
- `S_R1`
- `S_R2`
- `S_DONE`

'S_R1' e 'S_R2' executam 64 vezes em um loop, e assim como descrito acima, são os estados responsáveis pelo que é chamado o 'bloco de compressão'. Seria possível unificar os 2 estados em 1 só, mas como mencionado acima, eles foram separados para a redução do caminho crítico.

## Contador com Overflow

Um detalhe de implementação interessante, é que como o nosso loop alinha em uma potência de 2 (64), implementamos o nosso contador como um sinal de 6 bits, e no último estado deixamos ele dar overflow de volta para 0, enquanto o sinal de overflow é usado para sinalizar o bloco de controle que o loop foi finalizado.

Como existem 2 estados no loop, seria possível utilizar o segundo para resetar o contador, mas esse jeito deixa o código mais simples.

## Adaptor Wrapper

Enquanto o componente funciona normalmente quando instanciado por outro componente, muitas placas tem um número limitado de pinos de input/output. Isso causa problemas na hora de sintetizar o projeto no quartus, já que a maioria das placas que que estávamos tentando utilizar tem um limite de 512 pinos, enquanto o nosso projeto tem `512 (chunk) + 256 (h_in) + 256 (h_out) = 1024`.

Para solucionar isso, foi criado um 'sha256_adaptor.vhdl', que recebe o 'chunk' e o 'h_in' em pedaços menores, e concatena eles em um sinal interno antes de chamar o componente principal. Um bloco de controle auxiliar 'sha256_adaptor_bc.vhdl' foi crido para o auxílio dessa concatenação.

## Testes / Simulação

Para testar o circuito e também obter valores de simulação, foram utilizados 2 testbenches:

- 'sha256_tb.vhdl': Verifica o funcionamento do componente principal
- 'sha256_adaptor_tb.vhdl': Verifica o funcionamento do adaptor

Tirando o componente testado, os 2 testbenches são iguais.

Neles, se testa 2 payloads de mensagens e se verifica que o valor retornado bate com o esperado. O primeiro payload cabe em 1 chunk só, mas o segundo requer a execução do algorítmo 2 vezes.

É possivel rodar os 2 testbenches usando GHDL com os scripts `scripts/run_tb.sh` e `scripts/run_adaptor_tb.sh`.
