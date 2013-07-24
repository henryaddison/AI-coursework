:-consult(war_of_life).
:-consult(my_wol).

cl_test_strategy(NumGames, P1Strat, P2Strat):-
  test_strategy(NumGames,P1Strat,P2Strat), halt.