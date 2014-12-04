-module (game21).
-import (game21_deck, [deck/0, shuffled/1,deal/2]).

%-define(SUITS, [diamond, heart, club, spade] ).
%-define(CARDS, [{ace,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9},{10,10},{jack,10},{queen,10},{king,10}]).
-export([start/0,stop/0, init/0,usr_bet/1,
  usr_double_down/0,usr_hit/0,usr_stand/0,make_deck/0,usr_start/0,point/1, member/2]).

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
  if Pid == element(1, hd (L)) -> hd(L);
     true                      -> member(Pid,tl(L))
  end.

% Loop gotta have deck, bet, point from usr n dealer
loop(List) -> 
  receive 
  {From, start} ->
    From! {started, 'Please make a bet'},
    %what to save here: Pid, deck, bet, user point, dealer point, user card, dealer card.
    loop ([{From,make_deck(),0, [], [], 1000} |List]);

  {From, bet, N} ->
    Tuple = member(From, List),
    case Tuple of 
      undefined -> 
        From! {not_bet, 'You have to start first'},
        loop (List);
      _         -> 
        % after bet, deals 2 cards, let the player knows their point
        UsrC = deal(element(2,Tuple), 2), 
        New_deck = element(2, Tuple) -- UsrC,

        % also dealer deals 2 cards and save the points
        DlrC = deal(New_deck, 2),
        D = New_deck -- DlrC,

        From!{bet, N, UsrC, hd(DlrC)},
        loop([{Pid,D, N, UsrC, DlrC, M} || {Pid, _, _, _, _, M} <- List, Pid =:= From])
    end;

    {From, hit} ->
    Tuple = member(From, List),
      case Tuple of 
        undefined -> 
          From! {not_bet, 'You have to start first'},
          loop (List);
        _         -> 
        %Deal 1 card and calculate points
          UsrC = deal(element(2,Tuple), 1), 
          New_UsrC = element(4, Tuple) ++ UsrC,
          UsrP = point(New_UsrC),
          D = element(2, Tuple) -- UsrC,
          
          DlrC = element(5, Tuple),
          %check if user loose or still in the game
          if
            UsrP =< 21 ->
              From!{usr_hit, New_UsrC, hd(DlrC), 'hit or stand?'},
              loop([{Pid,D, N, New_UsrC, DlrC, M} || {Pid, _, N, _, _, M} <- List, Pid =:= From]);
            true       ->  
              From! {usr_hit, New_UsrC, hd(DlrC), loose},
              New_Money = element(6, Tuple) - element(3,Tuple),
              loop([{Pid,D, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From])
          end
      end;

  {From, stand}->
  %Check if user has started the game
  Tuple = member(From, List),
      case Tuple of 
        undefined -> 
          From! {not_bet, 'You have to start first'},
          loop (List);
        _         -> 
          D = element (2,Tuple),
          Bet  = element(3,Tuple),
          UsrC = element(4,Tuple),
          DlrC = element(5,Tuple),
          Money = element(6,Tuple),
          UsrP = point(UsrC),
          DlrP = point(DlrC),
          
          if 
            UsrP == 21 andalso length(UsrC) == 2 andalso DlrP == 21 andalso length(DlrC)==2 -> 
              From! {usr_stand, UsrC, DlrC, 'draw'},
              loop([{Pid,D, 0, 0, 0, Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
            UsrP == 21 andalso length(UsrC) == 2             -> 
              From! {usr_stand, UsrC, DlrC, 'have blackjack'},
              New_Money = Money + 1.5* Bet,
              loop([{Pid,D, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
             DlrP == 21 andalso length(DlrC) == 2 ->
              From! {usr_stand, UsrC, DlrC, loose},
              New_Money = Money - Bet,
              loop([{Pid,D, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
           
            true                         -> 
              New_DlrC = dealer_deal(D, DlrC, DlrP),
              New_DlrP = point (New_DlrC),
              New_deck = D -- New_DlrC,
              if New_DlrP > 21 -> 
                  From! {usr_stand, UsrC, New_DlrC, win},
                  New_Money = Money + Bet,
                  loop([{Pid,D, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
                New_DlrP < UsrP -> 
                  From! {usr_stand, UsrC, New_DlrC, win},
                  New_Money = Money + Bet,
                  loop([{Pid,New_deck, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
                New_DlrP == UsrP -> 
                  From! {usr_stand, UsrC, New_DlrC, draw},
                  loop([{Pid,New_deck, 0, 0, 0, Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);         
                true -> 
                  From! {usr_stand, UsrC, New_DlrC, loose},
                  New_Money = Money - Bet,
                  loop([{Pid,New_deck, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From])
              end
            end
        end

  %{From, double}->
  %Check if the user has initial bet
    %case  of 
      %undefined -> 
      %From! {not_bet, 'You have to bet first'},
     % loop (List);
    %_ -> 
      % Get the initial bet, double it
      %double_bet= element(2,menber(From, List))*2,
      %Get one more new card
      %new_card = deal(element(1,menber(From, List))),
      %Get the points user has before, add with new card's point
      %user_newpoint= element(4,menber(From,List)+element(2, 
      %(check if user point over 21, if yes then user lose) 
      % else get dealer's point
      % add card and calculate new point until dealer's point is bigger than 16   
      %dealer_point=
      % check who has higher point and below 21
      %if  
        %check funtion with if its over 21
        %compare user with dealer points, user win then send win messgage
       %   From! {double, win} 
        %true
        %  From! {double, lose}
      %end
      %calculate how much money is left, if win , plus with double_bet, loose, minus that
      %user_moneyleft=
      % new deck is the deck before -- all cards dealt 
      % new_deck=  cards left in deck 

      %loop initial bet, new deck, no point for user, dealer, no card dealt, new amount of money
      %loop([{Pid, D, N, 0, 0, [],[]}|| {Pid, _, N, _,_,_,_} <- List, Pid == From, D==new_deck])  
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
    {bet, Msg1, Msg2, Msg3}     -> io:format('You bet ~p, your cards are ~p, dealer cards are ~p. ~n', [Msg1, Msg2, Msg3]);
    {not_bet, Msg} -> Msg
  after 1000 ->
    timeout  
  end. 



% user chosen double down or hit or stay. once chosen hit, double down won't show in next turn, (only showing hit or stand)
% when chosen double, user will recive one more card and double the bet and game end.
usr_double_down()->  ok.
%     bjgame! {self(), double},
%receive
%     {double, Msg } -> io:format('You ~p ~n', [Msg]);
% after 1000 ->
%   timeout 
%end.

% Hit or stand and get message win/lose/ask for another hit or stand
usr_hit () -> 
  bjgame! {self(), hit},
  receive  
    {not_bet, Msg} -> Msg;
    {usr_hit, Msg1, Msg2, Msg3} -> io:format('Your cards are ~p, dealer card(s) are ~p, you ~p. ~n', [Msg1, Msg2, Msg3])
  after 1000 -> 
    timeout
  end.

usr_stand() ->  
  bjgame! {self(), stand},
  receive  
    {not_bet, Msg} -> Msg;
    {usr_stand, Msg1, Msg2, Msg3} -> io:format('Your cards are ~p, dealer card(s) are ~p, you ~p. ~n', [Msg1, Msg2, Msg3])
  after 1000 -> 
    timeout
  end.

%point is to check card's point since we have ace as special case
%ace should be evaluated in the end
point([], UsrP)        -> UsrP;
point(Card_List, UsrP) -> 
  C = hd(Card_List), 
  case element(1,C) of 
    ace   -> 
      if UsrP =< 10 -> New_UsrP = UsrP + 11;
         true       -> New_UsrP = UsrP +1
      end;
    jack  -> New_UsrP = UsrP + 10;
    queen -> New_UsrP = UsrP + 10;
    king  -> New_UsrP = UsrP + 10;
    _     -> 
      New_UsrP = UsrP + element(1,C)
  end, 
  point(tl(Card_List), New_UsrP).
  
point(Card_List) -> 
  Ace = member(ace, Card_List),
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


dealer_deal (_, DlrC, DlrP) when DlrP> 16                      -> DlrC;
dealer_deal (Deck, DlrC, DlrP) when DlrP >0 andalso DlrP =< 16 ->
  New_card = deal(Deck, 1),
  New_deck = Deck -- New_card,
  New_DlrC = DlrC ++ New_card, 
  New_DlrP = point(New_DlrC),
  dealer_deal (New_deck, New_DlrC, New_DlrP).