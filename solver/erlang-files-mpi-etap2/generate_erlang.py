#!/usr/bin/env python3

import numpy as np
from scipy.special import gammaincc

def erlang_b(E, N):
    """Erlang B blocking probability - iterative"""
    if N == 0:
        return 1.0
    b = 1.0
    for k in range(N):
        b = (E * b) / (k + 1 + E * b)
    return b

def find_min_N_for_E(E, P_block=0.01, max_N=100):
    """Minimalna liczba instancji dla ruchu E i P_block"""
    for N in range(1, max_N):
        if erlang_b(E, N) <= P_block:
            return N
    return max_N


def generate_erlang_flat(lambda_req, avg_hold_times, P_block=0.01):
    """Generuje PŁASKĄ tablicę [19,14] dla MiniZinc"""
    print("%%%% TABLICA ERLANGA array[1..19, 1..14] of float [code:1]")
    print("service_erlang_table = [|")
    
    services = [
        'FRONT','AUTH','CATALOG_BROWSE','CATALOG_SEARCH','CART','PAYMENT','ORDER','CACHE','DB',
        'FRONTEND2','CART2','PRODUCTCATALOG2','CURRENCY2','PAYMENT2','SHIPPING2','EMAIL2','CHECKOUT2','RECOMMENDATION2','AD2'
    ]
    
    for i, service in enumerate(services):
        E = round(lambda_req[i] * avg_hold_times[i], 1)
        min_N = find_min_N_for_E(E, P_block)
        
        # 7 wierszy: E stałe, N = min_N + offset
        row = []
        for j in range(7):
            row.extend([E, max(1, min_N + j)])
        
        print(f"  % {i+1}={service:15} | " + ", ".join(f"{x:g}" for x in row) + " |")
    
    print("|];")
    print("\n%%%% UŻYWAJ w constraint:")
    print("abs(lambda_req[m]*avg_session_time[m] - service_erlang_table[id,2*row-1]) <= 0.1 /\\")
    print("total_instances(m) == service_erlang_table[id,2*row]")

if __name__ == "__main__":
    # lambdy dzienne
    lambda_req = [200,120,120,40,60,20,10,128,83,200,60,120,50,30,40,20,50,60,10]
    
    # średnie czasy trwania sesji dla wszystkich usług [s]
    avg_hold_times = [0.1,0.5,0.3,0.4,0.3,1.0,2.0,0.05,1.5,0.1,0.3,0.3,0.2,1.0,0.5,0.4,0.3,0.2,0.3]
    
    generate_erlang_flat(lambda_req, avg_hold_times, P_block=0.01)
