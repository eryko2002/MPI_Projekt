enum SERVICE =
{
  %pierwszy łańcuch mikrousług
  FRONT,
  AUTH,   
  CATALOG_BROWSE,
  CATALOG_SEARCH,
  CART,           
  PAYMENT,         
  ORDER,     
  CACHE,     
  DB,      
  %drugi łańcuch mikrousług
  FRONTEND2,    
  CART2,
  PRODUCTCATALOG2,
  CURRENCY2,
  PAYMENT2,
  SHIPPING2,
  EMAIL2,
  CHECKOUT2,
  RECOMMENDATION2,
  AD2
};

% Lista serwerów w centrum danych
enum SERVER = { S1, S2, S3 };

%%%% =========================
%%%% PARAMETRY ZMIENNYCH DLA PARAMETRÓW SERWERÓW
%%%% =========================

int: idle_power;
int: unit_power_cpu;
int: unit_power_mem;

%%%% =========================
%%%% DEFINICJA ZMIENNYCH DLA PARAMETRÓW USŁUG
%%%% =========================
array[SERVER] of int: server_cpu_capacity;
array[SERVER] of float: server_mem_capacity;
array[SERVICE] of float: lambda_req;         %intensywność napływu żądań na sekundę
array[SERVICE] of float: cpu_req;          %zapotrzebowanie na cpu przez daną usługę
array[SERVICE] of float: mem_req;          %zapotrzebowanie na ram przez daną usługę
array[SERVICE] of float: cpu_limit;        %limit zużycia cpu przez daną usługę
array[SERVICE] of float: mem_limit;        %limit pamięci ram możliwej do użycia przez daną usługę
array[SERVICE] of int: replicas_min;       %minimalna liczba replik danej usługi
array[SERVICE] of int: replicas_max;       %maksymalna liczba replik danej usługi
array[SERVICE] of float: proc_time;        %czas spędzony na 1 vCPU podczas przetwarzania pojedynczego żądania przez daną usługę
array[SERVICE] of float: threshold;        %próg obciążeniowy dla instancji danej usługi
array[SERVICE] of float: capacity_inst; %maksymalna liczba żądań na sekundę możliwa do obsłużenia przez instancję danej usługi
%%%% =========================
%%%% ZMIENNE DECYZYJNE
%%%% =========================

% Liczba instancji usługi m na serwerze s
array[SERVICE, SERVER] of var 0..100: instances;

% Czy serwer jest włączony (1) czy wyłączony (0)
array[SERVER] of var bool: server_on;

% Łączna liczba instancji usługi m
function var int: total_instances(SERVICE: m) =
    sum(s in SERVER)(instances[m, s]);
    
% Zużycie CPU na serwerze s (w vCPU)
array[SERVER] of var float: server_cpu_usage =
    [ sum(m in SERVICE)( cpu_req[m] * instances[m, s]) | s in SERVER ];

% Zużycie RAM na serwerze s (w GB)
array[SERVER] of var float  : server_mem_usage =
    [ sum(m in SERVICE)( mem_req[m] * instances[m, s]) | s in SERVER ];


%%%% =========================
%%%% OGRANICZENIA
%%%% =========================

% a) Minimalna liczba replik danej usługi musi być większa od 0.
% b) Minimalna liczba instancji usługi m musi zostać spełniona zgodnie z minimalną wartością replicas_min[m] określoną dla każdej usługi.
% c) Maksymalna liczba instancji usługi m nie może być większa od ustalonej wartości replicas_max[m]
constraint
  forall(m in SERVICE) (
    total_instances(m) >= replicas_min[m] /\
    total_instances(m) <= replicas_max[m]
  );

% d) Suma przepustowości wszystkich instancji usługi m musi być większa od zapotrzebowania λ_req[m]
constraint
  forall(m in SERVICE) (
    total_instances(m) * capacity_inst[m] >= lambda_req[m]
  );

% e) Suma vCPU wymaganych przez wszystkie instancje usługi m na serwerze s nie może przekroczyć dostępnej pojemności
constraint
  forall(s in SERVER) (
    server_cpu_usage[s] <= server_cpu_capacity[s] * bool2int(server_on[s])
  );

% f) Suma pamięci RAM wymaganej przez wszystkie instancje usługi m na serwerze s nie może przekroczyć dostępnej pamięci RAM serwera s
constraint
  forall(s in SERVER) (
    server_mem_usage[s] <= server_mem_capacity[s] * bool2int(server_on[s])
  );

% g) Sprawdzenie czy serwer s jest aktywny. Jeśli server_on[s] = 0, to nie może być na nim żadnej instancji
constraint
  forall(s in SERVER) (
    sum(m in SERVICE)(instances[m, s]) > 0 -> server_on[s]
  );

% h) Intensywność napływu żądań do pojedynczej instancji usługi m musi być mniejsza niż
constraint
  forall(m in SERVICE) (
    lambda_req[m] <= capacity_inst[m] * total_instances(m)
  );
  
% i) Dla każdej usługi m, średnie wykorzystanie CPU per instancja nie może przekroczyć progu threshold[m]
constraint 
  forall(m in SERVICE) (
    lambda_req[m] * proc_time[m] <= threshold[m] * cpu_limit[m] * total_instances(m)
  );

% j) Zapewnienie, że jeśli serwer s jest włączony => server_on[s] = 1, to wtedy liczba instancji uslugi m na tym serwerze jest większa bądź równa 1 => instances[m,s] >= 1
constraint
  forall(m in SERVICE, s in SERVER) (
    server_on[s] -> (instances[m,s] >= 1) 
  );
 
%%%% =========================
%%%% FUNKCJA CELU
%%%% =========================

var float: total_energy =
    sum(s in SERVER)(
        (idle_power * bool2int(server_on[s])) + (unit_power_cpu * server_cpu_usage[s]) + (unit_power_mem * server_mem_usage[s]));

solve minimize total_energy;

%%%% =========================
%%%% OUTPUT
%%%% =========================

output
[
  "total_energy = ", show(total_energy), "\n",
  "inst:\n"
]
++
[
  "  " ++ show(m) ++ ": "
  ++ join(", ", [ show(instances[m,s]) ++ "@" ++ show(s) | s in SERVER ])
  ++ "\n"
  | m in SERVICE
]
++
[
  "server_on:\n"
]
++
[
  "  " ++ show(s) ++ " = " ++ show(server_on[s]) ++ "\n"
  | s in SERVER
]
++
[
  "server_cpu_usage:\n"
]
++
[
  "  " ++ show(s) ++ " = " ++ show(server_cpu_usage[s]) ++ "\n"
  | s in SERVER
]
++
[
  "server_mem_usage:\n"
]
++
[
  "  " ++ show(s) ++ " = " ++ show(server_mem_usage[s]) ++ "\n"
  | s in SERVER
];




