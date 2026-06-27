stateDiagram-v2
    S_IDLE-->S_IDLE: rdy = 0
    S_IDLE-->S_INIT: rdy = 1
    S_INIT-->S_R1
    S_R1-->S_R2
    S_R2-->S_R1: o_loop_last = 0
    S_R2-->S_DONE: o_loop_last = 1
    S_DONE-->S_IDLE
