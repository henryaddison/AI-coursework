:-set_prolog_flag(toplevel_print_options, [max_depth(100)]).

% TEST STRATEGY & STATISTICS RECORDING

test_strategy(NumGames,P1Strat,P2Strat):-
	record_stats(NumGames,P1Strat,P2Strat,P1Wins,P2Wins,Draws,LongestGame,ShortestGame,TotalGameLength,TotalGameTime),
	output_stats(NumGames,P1Strat,P2Strat,P1Wins,P2Wins,Draws,LongestGame,ShortestGame,TotalGameLength,TotalGameTime).

output_stats(NumGames,P1Strat,P2Strat,P1Wins,P2Wins,Draws,LongestGame,ShortestGame,TotalGameLength,TotalGameTime):-
	write('Player 1 Strategy: '),write(P1Strat),nl,
	write('Player 2 Strategy: '),write(P2Strat),nl,
	write('Number of games: '),write(NumGames),nl,
	write('Number of draws: '),write(Draws),nl,
	write('Number of wins for player 1 (blue): '),write(P1Wins),nl,
	write('Number of wins for player 2 (red): '),write(P2Wins),nl,
	write('Longest (non-exhaustive) game: '),(var(LongestGame) -> write('no non-exhaustive game') ; write(LongestGame)),nl,
	write('Shortest game: '),write(ShortestGame),nl,
	
	AvgGameLength is TotalGameLength/NumGames,
	write('Average game length (including exhaustives): '),write(AvgGameLength),nl,
	
	AvgGameTime is TotalGameTime/NumGames,
	write('Average game time (ms): '),write(AvgGameTime),nl.

record_stats(1,P1Strat,P2Strat,P1Wins,P2Wins,Draws,LongestGame,ShortestGame,TotalGameLength,TotalGameTime):-
	time_play(P1Strat,P2Strat,RunTime,NumMoves,Winner),
	update_runtime(0,RunTime,TotalGameTime,0,NumMoves,TotalGameLength),
	update_results(Winner,0,P1Wins,0,P2Wins,0,Draws),
	ShortestGame is NumMoves,
	(Winner \= 'exhaust' -> LongestGame is NumMoves).

record_stats(NumGames,P1Strat,P2Strat,FinalP1Wins,FinalP2Wins,FinalDraws,FinalLongestGame,FinalShortestGame,FinalTotalGameLength,FinalTotalGameTime):-
	NumGames > 1,
	NextNumGames is NumGames - 1,
	record_stats(NextNumGames, P1Strat, P2Strat, P1Wins, P2Wins, Draws, LongestGame, ShortestGame, TotalGameLength, TotalGameTime),
	time_play(P1Strat,P2Strat,RunTime,NumMoves,Winner),
	update_runtime(TotalGameTime,RunTime,FinalTotalGameTime,TotalGameLength,NumMoves,FinalTotalGameLength),
	update_results(Winner,P1Wins,FinalP1Wins,P2Wins,FinalP2Wins,Draws,FinalDraws),
	(NumMoves < ShortestGame -> FinalShortestGame is NumMoves; FinalShortestGame is ShortestGame),
	((Winner \= 'exhaust',NumMoves > LongestGame) -> FinalLongestGame is NumMoves; FinalLongestGame is LongestGame).

time_play(P1Strat,P2Strat,RunTime,NumMoves,Winner):-
	statistics(walltime,[TStart|_]),
	play(quiet,P1Strat,P2Strat,NumMoves,Winner),
	statistics(walltime,[TEnd|_]),
	RunTime is TEnd - TStart.	

update_runtime(CurrentTime,LatestTime,NewTime,CurrentLength,LatestLength,NewLength):-
	NewTime is CurrentTime + LatestTime,
	NewLength is CurrentLength+LatestLength.

update_results('b', P1Wins, NewP1Wins, P2Wins, NewP2Wins, Draws, NewDraws):-
	NewP1Wins is P1Wins + 1,
	NewP2Wins is P2Wins,
	NewDraws is Draws.

update_results('r', P1Wins, NewP1Wins, P2Wins, NewP2Wins, Draws, NewDraws):-
	NewP1Wins is P1Wins,
	NewP2Wins is P2Wins + 1 ,
	NewDraws is Draws.

update_results('draw', P1Wins, NewP1Wins, P2Wins, NewP2Wins, Draws, NewDraws):-
	NewP1Wins is P1Wins,
	NewP2Wins is P2Wins,
	NewDraws is Draws+1.

update_results('exhaust', P1Wins, NewP1Wins, P2Wins, NewP2Wins, Draws, NewDraws):-
	NewP1Wins is P1Wins,
	NewP2Wins is P2Wins,
	NewDraws is Draws + 1.

update_results('stalemate', P1Wins, NewP1Wins, P2Wins, NewP2Wins, Draws, NewDraws):-
	NewP1Wins is P1Wins,
	NewP2Wins is P2Wins,
	NewDraws is Draws + 1.

% NEW STRATEGIES

% BLOODLUST

%Player colour dependent

bloodlust('b', [AliveBlues, AliveReds], [NewAliveBlues, AliveReds], Move):-
	bloodlust_move(AliveBlues, AliveReds, Move),
	alter_board(Move, AliveBlues, NewAliveBlues).

bloodlust('r', [AliveBlues, AliveReds], [AliveBlues, NewAliveReds], Move):-
	bloodlust_move(AliveReds, AliveBlues, Move),
	alter_board(Move, AliveReds, NewAliveReds).

%Player colour independent

bloodlust_move(Alive, OtherPlayerAlive, Move):-
  %get all the possible moves
	possible_moves(Alive, OtherPlayerAlive, PossMoves),
	%get the state of the cranked boards from these moves
	trial_cranked_board_states(Alive, OtherPlayerAlive, PossMoves, TrialMoveOutcomes),
	%from these cranked board states pick the move that is best according to bloodlust
	most_bloodlust(TrialMoveOutcomes, _, Move).

most_bloodlust([[_, TheirAlives, Move]], BestCount,BestMove):-
	!, length(TheirAlives, BestCount),
	BestMove = Move.

most_bloodlust([[_, TheirAlives, Move]|RemainingOutcomes], BestCount, BestMove):-
	most_bloodlust(RemainingOutcomes, BestRemainingCount, BestRemainingMove),
	((length(TheirAlives, ThisCount), ThisCount < BestRemainingCount) -> (length(TheirAlives, BestCount), BestMove = Move) ; (BestCount = BestRemainingCount, BestMove = BestRemainingMove)).	


% SELF PRESERVATION

self_preservation('b', [AliveBlues, AliveReds], [NewAliveBlues, AliveReds], Move):-
	selfpres_move(AliveBlues, AliveReds, Move),
	alter_board(Move, AliveBlues, NewAliveBlues).

self_preservation('r', [AliveBlues, AliveReds], [AliveBlues, NewAliveReds], Move):-
	selfpres_move(AliveReds, AliveBlues, Move),
	alter_board(Move, AliveReds, NewAliveReds).

selfpres_move(Alive, OtherPlayerAlive, Move):-
	possible_moves(Alive, OtherPlayerAlive, PossMoves),
	trial_cranked_board_states(Alive, OtherPlayerAlive, PossMoves, TrialMoveOutcomes),
	most_selfpres(TrialMoveOutcomes, _, Move).

most_selfpres([[MineAlives, _, Move]], BestCount,BestMove):-
	!, length(MineAlives, BestCount),
	BestMove = Move.

most_selfpres([[MineAlives, _, Move]|RemainingOutcomes], BestCount, BestMove):-
	most_selfpres(RemainingOutcomes, BestRemainingCount, BestRemainingMove),
	length(MineAlives, ThisCount),
	(ThisCount > BestRemainingCount -> (BestCount = ThisCount, BestMove = Move) ; (BestCount = BestRemainingCount, BestMove = BestRemainingMove)).

% LAND GRAB

land_grab('b', [AliveBlues, AliveReds], [NewAliveBlues, AliveReds], Move):-
	land_grab_move(AliveBlues, AliveReds, Move),
	alter_board(Move, AliveBlues, NewAliveBlues).

land_grab('r', [AliveBlues, AliveReds], [AliveBlues, NewAliveReds], Move):-
	land_grab_move(AliveReds, AliveBlues, Move),
	alter_board(Move, AliveReds, NewAliveReds).
	
land_grab_move(Alive, OtherPlayerAlive, Move):-
	possible_moves(Alive, OtherPlayerAlive, PossMoves),
	trial_cranked_board_states(Alive, OtherPlayerAlive, PossMoves, TrialMoveOutcomes),
	most_land_grab(TrialMoveOutcomes, _, Move).

most_land_grab([[MineAlives, TheirAlives, Move]], BestCount,BestMove):-
	!, length(MineAlives, MineCount), length(TheirAlives, TheirsCount), BestCount is MineCount - TheirsCount,
	BestMove = Move.

most_land_grab([[MineAlives, TheirAlives, Move]|RemainingOutcomes], BestCount, BestMove):-
	most_land_grab(RemainingOutcomes, BestRemainingCount, BestRemainingMove),
	length(MineAlives, MineCount),
	length(TheirAlives, TheirsCount),
	ThisCount is (MineCount - TheirsCount),
	(ThisCount > BestRemainingCount -> (BestCount = ThisCount, BestMove = Move) ; (BestCount = BestRemainingCount, BestMove = BestRemainingMove)).

% MINIMAX

minimax('b', [AliveBlues, AliveReds], [NewAliveBlues, AliveReds], Move):-
	minimax_move(AliveBlues, AliveReds, Move),
	alter_board(Move, AliveBlues, NewAliveBlues).

minimax('r', [AliveBlues, AliveReds], [AliveBlues, NewAliveReds], Move):-
	minimax_move(AliveReds, AliveBlues, Move),
	alter_board(Move, AliveReds, NewAliveReds).

minimax_move(Alive, OtherPlayerAlive, Move):-
	possible_moves(Alive, OtherPlayerAlive, PossMoves),
	trial_cranked_board_states(Alive, OtherPlayerAlive, PossMoves, TrialMoveOutcomes),
	best_minimax(TrialMoveOutcomes, _, Move).

best_minimax([[MineAlives, TheirAlives, Move]], BestMinimum, BestMove):-
	BestMove = Move,
	possible_moves(TheirAlives, MineAlives, []),!,
	%WHAT TO DO IN THE CASE THAT THE OPPONENT CAN'T MAKE A MOVE?
	%Assume that they make a fake move that has no effect on the board, so BestMininum is state of the trial board after my trial move
	length(MineAlives, MineCount),length(TheirAlives, TheirsCount),
	BestMinimum is MineCount - TheirsCount.

best_minimax([[MineAlives, TheirAlives, Move]], BestMinimum, BestMove):-
	BestMove = Move,
	%get the opponent's possible moves
	possible_moves(TheirAlives, MineAlives, PossMoves),!,
	%and then the board states after those moves
	trial_cranked_board_states(TheirAlives, MineAlives, PossMoves, TrialTheirMoveOutcomes),
	%find the best land grab move for this opponent
	most_land_grab(TrialTheirMoveOutcomes, TheirMinimum, _),
	%thanks to the symmetry of the heuristic used by land_grab, my utility function is just the negation of the utility function used by the opponent, so wish to maximize the negation of the of the opponent's land_grab utility
	BestMinimum is 0-TheirMinimum.

best_minimax([[MineAlives, TheirAlives, Move]|RemainingOutcomes], BestMinimum, BestMove):-
	best_minimax(RemainingOutcomes, RemainingBestMinimum, RemainingBestMove),
	best_minimax([[MineAlives, TheirAlives, Move]], ThisBestMinimum, ThisBestMove),
	(ThisBestMinimum > RemainingBestMinimum -> (BestMove = ThisBestMove, BestMinimum = ThisBestMinimum) ; (BestMove = RemainingBestMove, BestMinimum = RemainingBestMinimum)).

% HELPER METHODS 

%get all the possible moves
possible_moves(Alive, OtherPlayerAlive, PossMoves):-
	findall([A,B,MA,MB],(member([A,B], Alive),
	neighbour_position(A,B,[MA,MB]),
	\+member([MA,MB],Alive),
	\+member([MA,MB],OtherPlayerAlive)),
	PossMoves).

%for each move in a list get a list of board states with the corresponding move
trial_cranked_board_states(Alive, OtherPlayerAlive, PossMoves, TrialMoveOutcomes):-
	findall([CrankedNewAlive, CrankedOtherPlayerAlive, TrialMove],(member(TrialMove,PossMoves),alter_board(TrialMove,Alive,NewAlive),next_generation([NewAlive,OtherPlayerAlive],[CrankedNewAlive,CrankedOtherPlayerAlive])), TrialMoveOutcomes).

