-module (game21).
-import (game21_deck, [deck/0, shuffled/1,deal/1]).

%-define(SUITS, [diamond, heart, club, spade] ).
%-define(CARDS, [{ace,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9},{10,10},{jack,10},{queen,10},{king,10}]).
-export([start/0,stop/0, init/0,usr_bet/1,
  usr_double_down/0,usr_hit/0,usr_stand/0,make_deck/0,usr_start/0]).

start() ->
  Bj_Pid = whereis(bjgame),
  case Bj_Pid of 
    undefined ->   
      register (bjgame, Pid = spawn(game21,init,[])),
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
   _          -> 
    exit(Bj_Pid, kill),
    stopped
  end.

make_deck() -> shuffled(deck()).

init() -> loop ([]).

member(_Pid,L) when L == []-> undefined;
member(Pid,L)   -> 
  if Pid == element(1, hd (L)) -> {element(2, hd (L)),element(3, hd (L)),element(4, hd (L)), element(5, hd (L)), element(6, hd (L))};
      true                     -> member(Pid,tl(L))
  end.

% Loop gotta have deck, bet, point from usr n dealer
loop(List) -> 
  receive 
  {From, start} ->
    From! {started, 'Please make a bet'},
    %what to save here: Pid, deck, bet, user point, dealer point, user card, dealer card.
    loop ([{From,make_deck(),0,0,0, [], []} |List]);

  {From, bet, N} ->
    case member(From, List) of 
      undefined -> 
        From! {not_bet, 'You have to start first'},
        loop (List);
      _ -> 
        Num = N,
        % after bet, deals 2 cards, let the player knows their point
        % also dealer deals 2 cards and save the points
        From! {bet, N},
        loop ([{Pid,D, N, UsrP, DlrP, UsrC, DlrC} || {Pid, D, _, UsrP, DlrP, UsrC, DlrC} <- List, Pid == From])
    end


  %{From, double}->
    %case member(From, List) of 
      %undefined -> 
      %From! {not_bet, 'You have to start first'},
     % loop (List);
    %_ -> 
      %double_bet= element(2,menber(From, List))*2,
      %new_card = deal(element(1,menber(From, List))),
      %user_newpoint= element(4,menber(From,List)+element(2, 
         
      %dealer_point=

      %if  
        %check funtion with if its over 21
        %compare user with dealer points, user win then send win messgage
       %   From! {double, win} 
        %true
        %  From! {double, lose}
      %end
      %user_moneyleft=
      % new_deck=  cards left in deck 

      %loop([{Pid, D, N, 0, 0, [],[]}|| {Pid, _, N, _,_,_,_} <- List, Pid == From, D==new_deck])  
    
  %end.

  end.


usr_start() -> 
  bjgame! {self(), start},
  receive 
    {started, Msg} ->Msg
  after 1000 ->
    timeout  
  end.

%usr has to bet first then can hit or stand.
usr_bet(N) -> 
  bjgame! {self(), bet, N},
  receive 
    {bet, Msg}     -> io:format('You bet ~p ~n', [Msg]);
    {not_bet, Msg} -> Msg
  after 1000 ->
    timeout  
  end. 



% user chosen double down or hit or stay. once chosen hit, double down won't show in next trun, (only showing hit or stand)
% when chosen double, user will recive one more card and double the bet and game end.
%usr_double_down()-> 
%     bjgame! {self(), double},
%receive
%     {double, Msg } -> io:format('You ~p ~n', [Msg]);
% after 1000 ->
%   timeout 
%end.

% Hit or stand and get message win/lose/ask for another hit or stand
usr_hit () -> ok.

usr_stand() -> ok.
