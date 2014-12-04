-module(game21_deck).
-export([deck/0, shuffled/1,deal/2]).

-define(SUITS, [diamond, heart, club, spade] ).
-define(CARDS, [{ace},{2},{3},{4},{5},{6},{7},{8},{9},{10},{jack},{queen},{king}]).


deck() ->
     F = fun(S) -> [{C, S} || {C} <- ?CARDS] end,
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

deal(_,0) -> [];
deal(List, N)  ->  
    if length(List) =< 12 -> 
        Deck = shuffled(deck());
    true -> Deck = List end,
    [hd(Deck)] ++ deal(tl(List), N-1).


                   
%Peili