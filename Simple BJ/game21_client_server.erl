-module (game21_client_server).
-import (game21_deck, [deck/0, shuffled/1]).

%-define(SUITS, [diamond, heart, club, spade] ).
%-define(CARDS, [{ace,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9},{10,10},{jack,10},{queen,10},{king,10}]).
-export([start/0,stop/0, init/0,add_deck/1,usr_bet/1,
  usr_double_down/0,usr_hit/0,usr_stand/0,make_deck/0,usr_start/0]).

start() ->
  Bj_Pid = whereis(bjgame),
  case Bj_Pid of 
    undefined ->   
      register (bjgame, Pid = spawn(game21_client_server,init,[])),
      {ok, Pid};
    _         -> 
      {ok, Bj_Pid}      
  end.
% if sts is undefined, process already stopped
% else, send message stop and display stopped message
stop() ->
  Bj_Pid = whereis(bjgame),
  case Bj_Pid of
    undefined -> already_stopped;
   _ -> 
    exit(Bj_Pid, kill),
    stopped
  end.

make_deck() -> shuffled(deck()).

init() -> loop ([]).

member(_Pid,L) when length (L) == 0 -> undefined;
member(Pid,L) when length (L) >=1    -> 
  if Pid == element(1, hd (L)) -> element(2, hd (L));
        %assuming there is only one value return for 1 Pid and 1 key, no recursion after finding the value
      true                     -> member(Pid,tl(L))
  end.

% Loop gotta have deck, bet, point from usr n dealer
loop(List) -> 
  receive 
  {From, start} -> 
    From! {started, 'Please make a bet'},
    loop ([ {From,make_deck(),0,0} |List]);
  {From, add_deck, N} -> 
    Num = N,
    Deck = member(From, List),
    case Deck of 
      undefined -> 
        From! {not_added, 'You have to start first'},
        loop (List);
      _ -> 
        From! {added, Num},
        Add = lists:append(lists:duplicate(Num, make_deck())),
        New_deck = Add ++ Deck,
        loop ([ {Pid, New_deck, B, P} || {Pid, _, B, P} <- List]) %
    end
  end.

add_deck(N) -> 
  bjgame! {self(), add_deck, N},
  receive 
    {added, Msg} -> io:format('Added ~p decks to current deck ~n', [Msg]);
    {not_added, Msg} -> Msg
  after 1000 ->
    timeout  
  end. 

usr_start() -> 
  bjgame! {self(), start},
  receive 
    {started, Msg} -> Msg 
  after 1000 ->
    timeout  
  end.

%usr has to bet/double down first then can hit or stand.
usr_bet(_N) -> ok.

usr_double_down()-> ok.

% Hit or stand and get message win/lose/ask for another hit or stand
usr_hit () -> ok.

usr_stand() -> ok.

%take out a card
deal() -> ok.