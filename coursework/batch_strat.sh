games=$1;
p1strat=$2;
p2allstrats=( random bloodlust self_preservation land_grab );
for p2strat in  "${p2allstrats[@]}"; do
  ./run_strat.sh $games $p1strat $p2strat;
  sleep 300;
done;
