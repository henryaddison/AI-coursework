echo "Running $1 games of $2 vs $3";
sicstus -l my_wol_cl_wrap.pl --goal "cl_test_strategy($1,$2,$3)." > trials/${1}_${2}_${3}.txt 2>>error.txt

