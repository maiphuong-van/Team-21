-module(game21_deck).
-export([deck/0, shuffled/1]).

-define(SUITS, [diamond, heart, club, spade] ).
-define(CARDS, [{ace,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9},{10,10},{jack,10},{queen,10},{king,10}]).
%sign the number and the value to each card, not sure if need to sign one more {ace,11}??


deck() ->
     F = fun(S) -> [{S, C, V} || {C, V} <- ?CARDS] end,
 	lists:flatten(lists:map(F, ?SUITS)).
 	%to sign cards and suits together,
    %use lists:flatten to flat the 4 different lists to become one total list



shuffled(List) ->
	    %randomlise the list by 100%, 
	    %add the random:seed(), to change the random number generater differently in each process 
	    {A1,A2,A3} = now(),
        random:seed(A1, A2, A3),
        randomize(round(math:log(length(List)) + 1), List).


randomize(1, List) ->
                     randomize(List);
randomize(T, List) ->
                    lists:foldl(fun(_E, Acc) ->
                    randomize(Acc)
               end, 
                    randomize(List), lists:seq(1, (T - 1))).
                    %lists:seq()get all the value from the first element in list to the second last one
randomize(List) ->
                    D = lists:map(fun(A) -> {random:uniform(), A} end, List),
                    {_, D1} = lists:unzip(lists:keysort(1, D)), 
                   D1.
%Peili