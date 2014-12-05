-module (game21).
-import (game21_deck, [deck/0, shuffled/1,deal/2]).

%-define(SUITS, [diamond, heart, club, spade] ).
%-define(CARDS, [{ace},{2},{3},{4},{5},{6},{7},{8},{9},{10},{jack},{queen},{king}]).
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
    From! {started, 'Please join a room or make a bet of minimum 50 and maximum 500'},
    %what to save here: Pid, deck, bet, user point, dealer point, user card, dealer card.
    loop ([{From,make_deck(),0, [], [], 1000} |List]);

  {From, bet, N} ->
    Tuple = member(From, List),
    case Tuple of 
      undefined -> 
        From! {not_bet, 'You have to start first'},
        loop (List);
      _         -> 
        M = element(6,Tuple),
        %check if user can bet
        if M < 50 -> 
            From! {loose, 'You have less money than minimum bet, you loose, restart to continue'};
        M < N -> 
          From! {cannot_bet, 'You do not have enough money to bet'},
          loop(List);
        true -> 
        % after bet, deals 2 cards, let the player knows their point
          UsrC = deal(element(2,Tuple), 2), 
          New_deck = element(2, Tuple) -- UsrC,

          % also dealer deals 2 cards and save the points
          DlrC = deal(New_deck, 2),
          D = New_deck -- DlrC,

          %get the amount of money to show
          

          From!{bet, N, UsrC, hd(DlrC), M},
          loop([{Pid,D, N, UsrC, DlrC, M} || {Pid, _, _, _, _, _} <- List, Pid =:= From])
        end
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
          
          %get dealer cards to show to user
          DlrC = element(5, Tuple),

          %get money to show to user
          M = element(6,Tuple),
          %check if user loose or still in the game
          if
            UsrP =< 21 ->
              From!{usr_hit, New_UsrC, hd(DlrC), 'hit or stand?', M},
              loop([{Pid,D, N, New_UsrC, DlrC, M} || {Pid, _, N, _, _, _} <- List, Pid =:= From]);
            true       -> 
              New_Money = M - element(3,Tuple), 
              From! {usr_hit, New_UsrC, hd(DlrC), loose, New_Money},
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
        %get most of elements from the tuple
          D = element (2,Tuple),
          Bet  = element(3,Tuple),
          UsrC = element(4,Tuple),
          DlrC = element(5,Tuple),
          Money = element(6,Tuple),
        %calculate points
          UsrP = point(UsrC),
          DlrP = point(DlrC),
          
          if 
            %check if both natural blackjack -> push
            UsrP == 21 andalso length(UsrC) == 2 andalso DlrP == 21 andalso length(DlrC)==2 -> 
              From! {usr_stand, UsrC, DlrC, 'draw', Money},
              loop([{Pid,D, 0, 0, 0, Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
            %check is user has black jack
            UsrP == 21 andalso length(UsrC) == 2             -> 
              New_Money = Money + 1.5* Bet,
              From! {usr_stand, UsrC, DlrC, 'have blackjack', New_Money},
              loop([{Pid,D, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
             
            true                         -> 
            % else dealer will deal card (if neccessary to get over 16 points)
            %calculate dealer's new point and new deck
              New_DlrC = dealer_deal(D, DlrC),
              New_DlrP = point (New_DlrC),
              New_deck = D -- New_DlrC,
            %check if dealer has more than 21 -> win
              if New_DlrP > 21 -> 
                  New_Money = Money + Bet,
                  From! {usr_stand, UsrC, New_DlrC, win, New_Money},
                  loop([{Pid,D, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
                  %User had more points than dealer -> win
                New_DlrP < UsrP -> 
                  New_Money = Money + Bet,
                  From! {usr_stand, UsrC, New_DlrC, win, New_Money},                
                  loop([{Pid,New_deck, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
                  %User has same points as dealer -> draw
                New_DlrP == UsrP -> 
                  From! {usr_stand, UsrC, New_DlrC, draw, Money},
                  loop([{Pid,New_deck, 0, 0, 0, Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);         
                true -> 
                %User has less points than dealer -> loose
                  New_Money = Money - Bet,
                  From! {usr_stand, UsrC, New_DlrC, loose, New_Money},
                  loop([{Pid,New_deck, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From])
              end
          end
     end;

  {From, double}->
  %Check if the user has initial bet
       Tuple = member(From, List),
       case Tuple of 
    undefined -> 
       From! {not_bet, 'You have to bet first'},
       loop (List);
    _ -> 
      D = element (2,Tuple),
      Bet  = element(3,Tuple),
      UsrC = element(4,Tuple),
      DlrC = element(5,Tuple),
      Money = element(6,Tuple),
  
      % Get the initial bet, double it
      Double_bet= Bet*2,
      % Get one more new card, and add to user cards
      New_UsrC = UsrC ++ deal(D,1),
      New_deck= D -- New_UsrC,
      % Get the points user has before, add with new card's point
      User_newpoint= point(New_UsrC),
    % ----------------------------------------------------------
    % check if user point over 21, if yes then user lose
      if User_newpoint > 21 ->
        From! {busted, User_newpoint, DlrC, loose, New_Money}, %%Why not showing the amount of money?
        New_Money = Money - Double_bet,
        loop([{Pid,New_deck, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);

      % else get dealer's point, add card and calculate new point until dealer's point is bigger than 16   
      true  ->
        New_DlrC = dealer_deal(D, DlrC),
        New_DlrP = point (New_DlrC),
        %% New deck of card here! 
        %%You see, your dealer dealed more cards out, those have to be taken away from the deck too
      % check who has higher point and below 21
     
      if %%what if dealer has more than 21 points?
        New_DlrP < User_newpoint -> 
          New_Money = Money + Double_bet,
          From! {double, UsrC, New_DlrC, win, New_Money},                
          loop([{Pid,New_deck, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]);
      
        New_DlrP == User_newpoint -> 
          From! {double, UsrC, New_DlrC, draw, Money},
          loop([{Pid,New_deck, 0, 0, 0, Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From]); 
      
        true ->
          New_Money = Money - Double_bet,
          From! {double, UsrC, New_DlrC, loose, New_Money},
          loop([{Pid,New_deck, 0, 0, 0, New_Money} || {Pid, _, _, _, _, _} <- List, Pid =:= From])
        end
     end
  end
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
  if N < 50 orelse N > 500 ->
    io:format('Your bet is invalid ~n');
   true ->
    bjgame! {self(), bet, N},
    receive 
      {bet, Msg1, Msg2, Msg3, Msg4}     -> io:format('You bet ~p, your cards are ~p, dealer cards are ~p. You have ~p ~n', [Msg1, Msg2, Msg3, Msg4]);
      {not_bet, Msg} -> Msg;
      {loose, Msg} -> Msg;
      {cannot_bet, Msg} -> Msg
    after 1000 ->
      timeout  
    end
  end. 

% user chosen double down or hit or stay. once chosen hit, double down won't show in next turn, (only showing hit or stand)
% when chosen double, user will recive one more card and double the bet and game end.

usr_double_down()->
  bjgame! {self(), double},
  receive
      %%receive {not_bet, Msg}?
       {double, Msg } -> io:format('You ~p ~n', [Msg]);
       {busted, Msg } -> io:format('You ~p ~n', [Msg])
       %% Those two will NOT work, timeout would defenitely occurs.
       %% You sent message back with a tuple of 4,5 elements in loop but here the message are a tuple of 2 elements
       %% Check hit and stand for how I deal with multiple messages 
   after 1000 ->
     timeout 
  end.


% Hit or stand and get message win/lose/ask for another hit or stand
usr_hit () -> 
  bjgame! {self(), hit},
  receive  
    {not_bet, Msg} -> Msg;
    {usr_hit, Msg1, Msg2, Msg3, Msg4} -> io:format('Your cards are ~p, dealer card(s) are ~p, you ~p. You have ~p ~n', [Msg1, Msg2, Msg3, Msg4])
  after 1000 -> 
    timeout
  end.

usr_stand() ->  
  bjgame! {self(), stand},
  receive  
    {not_bet, Msg} -> Msg;
    {usr_stand, Msg1, Msg2, Msg3, Ms} -> io:format('Your cards are ~p, dealer card(s) are ~p, you ~p. You have ~p ~n', [Msg1, Msg2, Msg3, Ms])
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
 
%overload, to put ace in the end of the list
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

% will return a list of cards from Dealer's original cards 
% The way dealer deals is dependent on rules, he has to deal 1 card until his points is over 16
dealer_deal (_, DlrC, DlrP) when DlrP> 16                      -> DlrC;
dealer_deal (Deck, DlrC, DlrP) when DlrP >0 andalso DlrP =< 16 ->
  New_card = deal(Deck, 1),
  New_deck = Deck -- New_card,
  New_DlrC = DlrC ++ New_card, 
  New_DlrP = point(New_DlrC),
  dealer_deal (New_deck, New_DlrC, New_DlrP).

%overload, so we don't have to mention dealer's point (just to make it short and simple)
dealer_deal(Deck, DlrC) -> 
  DlrP = point(DlrC),
  dealer_deal(Deck, DlrC, DlrP).