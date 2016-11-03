-module (gen_game21).
-behaviour(gen_server).

-import (game21_deck, [deck/0, shuffled/1,deal/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).
-export([start_link/0, usr_new_game/1, game_stop/1]).

%%% Client API
start_link() -> gen_server:start_link(?MODULE, [], []).

%%Synchronous call 

usr_new_game (Pid) -> gen_server:call(Pid, {new}).

%%usr_bet(Pid, Amount) -> gen_server:call(Pid,{bet, Amount}).

%%usr_double_down(Pid) -> gen_server:call(Pid,{double}).

%%usr_hit(Pid) -> gen_server:call(Pid,{hit}).

%%usr_stand(Pid) -> gen_server:call(Pid,{stand}).

game_stop(Pid) -> gen_server:call(Pid, terminate).

%%Server function

init([]) -> {ok, []}.

terminate(normal, List) -> ok.

handle_call(terminate, _From, List) -> {stop, normal, ok, List};

handle_call({new}, _From, List) -> 
	{reply, "Welcome", [make_deck(), 0, [],[], 1000]}.

%%handle_call({bet, Amount}, _From, List) ->
%%	Money = lists:nth(5, List)
%%	if  Money < 50 -> {reply, "No money, you loose", []},
%%		Money < Amount -> {reply, "Not enough credits", List},
%%		true -> 	



%%handle_call({double}, _From, List)

%%handle_call({hit}, _From, List)  

%%handle_call({stand}, _From, List)  


handle_cast(Msg, List) ->
    {noreply, List}.

handle_info(Msg, List) ->
    io:format("Unexpected message: ~p~n",[Msg]),
    {noreply, List}.

code_change(_OldVsn, State, _Extra) ->
    %% No change planned. The function is there for the behaviour,
    %% but will not be used. Only a version on the next
    {ok, State}. 

%Private helper functions

%point is to check card's point since we have ace as special case
%ace should be evaluated in the end
point([], UsrPoint)        -> UsrPoint;
point([C|T], UsrPoint) when element(1,C) == a ->
      if UsrPoint =< 10 -> New_UsrPoint = UsrPoint + 11;
         true       -> New_UsrPoint = UsrPoint +1
      end;
point([C|T], UsrPoint) when element(1,C) == j; element(1,C) == q; element(1,C) == k  -> New_UsrPoint = UsrPoint + 10;
point([C|T], UsrPoint)     -> New_UsrPoint = UsrPoint + element(1,C),
point(T, New_UsrPoint).
 
%overload, to put ace in the end of the list
point(Card_List) -> 
  Ace = find(a, Card_List),
  %Check if we have Ace
  %Not, just check the point
  %Have ace then put ace in the end
  case Ace of
   undefined -> point(Card_List,0);
   _ ->
   New_List1 = Card_List -- [Ace],
   New_List = New_List1 ++ [Ace],
   point (New_List, 0)
  end.

% will return a list of cards from Dealer's original cards 
% The way dealer deals is dependent on rules, he has to deal 1 card until his points is over 16
dealer_deal (_, DlrC, DlrP) when DlrP> 16                      -> DlrC;
dealer_deal (Deck, DlrC, DlrP) when DlrP >0 , DlrP =< 16 ->
  New_card = deal(Deck, 1),
  New_deck = Deck -- New_card,
  New_DlrC = DlrC ++ New_card, 
  New_DlrP = point(New_DlrC),
  dealer_deal (New_deck, New_DlrC, New_DlrP).

%overload, so we don't have to mention dealer's point (just to make it short and simple)
dealer_deal(Deck, DlrC) -> 
  DlrP = point(DlrC),
  dealer_deal(Deck, DlrC, DlrP).

make_deck() -> shuffled(deck()).

find(_Value,L) when L == []-> undefined;
find(Value,L)   -> 
  if Value == element(1, hd (L)) -> hd(L);
     true                        -> find(Value,tl(L))
  end.
