#!/bin/bash

cd solver-eg-files-mpi/

#case 1: traffic on the day 
#docker run --rm -v $(pwd):/data -w /data minizinc/minizinc:latest minizinc model.mzn data_day_scenario.dzn --solver gecode --time-limit 5000 > results/results_day.txt

#case 2: traffic on the night
#docker run --rm -v $(pwd):/data -w /data minizinc/minizinc:latest minizinc model.mzn data_night_scenario.dzn --solver gecode --time-limit 5000 > results/results_night.txt

#case 3: peak traffic on the day
docker run --rm -v $(pwd):/data -w /data minizinc/minizinc:latest minizinc model.mzn data_day_peak_scenario.dzn --solver gecode > results/results_day_peak.txt