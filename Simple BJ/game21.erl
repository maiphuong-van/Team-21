-module (game21).
-import (game21_deck, [deck/0, shuffled/1,deal/2]).

%-define(SUITS, [diamond, heart, club, spade] ).
%-define(CARDS, [{ace},{2},{3},{4},{5},{6},{7},{8},{9},{10},{jack},{queen},{king}]).
-export([start/0,stop/0, init/0,usr_bet/2,
  usr_double_down/1,usr_hit/1,usr_stand/1,make_deck/0,usr_start/1,point/1, member/2]).

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

usr_start(Name) -> 
  bjgame! {self(), {start, Name}},
  receive 
    {_Pid, started, Msg, Msg1} -> io:format('You are ~p. ~p ~n', [Msg, Msg1])
  after 1000 ->
    timeout  
  end.

%usr has to bet first then can hit or stand.
usr_bet(Name, N) -> 
  if N < 50 orelse N > 500 ->
    io:format('Your bet is invalid ~n');
   true ->
    bjgame! {self(), {bet, Name, N}},
    receive 
      %% Msg == user reference, Msg1 == bet, Msg2 == user's card list, Ms3 == dealer's 1st card, Msg4 == User's money
      {_Pid, bet, Msg, Msg1, Msg2, Msg3, Msg4} -> io:format('You are ~p. You bet ~p, your cards are ~p, dealer cards are ~p. You have ~p ~n', [Msg,Msg1, Msg2, Msg3, Msg4]);
      %% Msg == warning that user hasn't started
      {_Pid, not_start, Msg} -> Msg;
      %% Msg == User has less money than minimum bet, has to restart to play again
      {_Pid, loose, Msg} -> Msg;
      %% Msg == User tried to bet more than what they have, so they cannot bet 
      {_Pid, cannot_bet, Msg} -> Msg
    after 1000 ->
      timeout  
    end
  end. 

% user chosen double down or hit or stay. once chosen hit, double down won't show in next turn, (only showing hit or stand)
% when chosen double, user will recive one more card and double the bet and game end.
usr_double_down(Name)->
  bjgame! {self(), {double, Name}},
  receive 
    %% Msg == User hasn't started the game
    {_Pid, not_start, Msg} -> Msg;
    %% Msg == User hasn't bet
    {_Pid, not_bet, Msg} -> Msg;
    %% Msg Msg == User reference, Msg1 == warning user cannot double down
    {_pid, no_double, Msg, Msg1} -> io:format('You are ~p. ~p ~n', [Msg, Msg1]);
    %% Msg == user reference, Msg1 == user's card list, Msg2 == dealer's card, Msg3 == win or lose or draw, Msg4 == User's money
    {_Pid, double, Msg, Msg1, Msg2, Msg3, Msg4} -> io:format('You are ~p. Your cards are ~p, dealer card(s) are ~p, you ~p. You have ~p ~n', [Msg, Msg1, Msg2, Msg3, Msg4])
   after 1000 ->
     timeout 
  end.

% Hit or stand and get message win/lose/ask for another hit or stand
usr_hit (Name) -> 
  bjgame! {self(), {hit, Name}},
  receive  
    %% Msg == User hasn't started the game
    {_Pid, not_start, Msg} -> Msg;
    %% Msg == User hasn't bet
    {_Pid, not_bet, Msg} -> Msg;
    %% Msg == User reference, Msg1 == List of user's cards, Msg2 == Dealer's 1st card, Msg3 == Loose or can countinue, Msg4 == User's money
    {_Pid, usr_hit, Msg, Msg1, Msg2, Msg3, Msg4} -> io:format('You are ~p. Your cards are ~p, dealer card(s) are ~p, you ~p. You have ~p ~n', [Msg, Msg1, Msg2, Msg3, Msg4])
  after 1000 -> 
    timeout
  end.

usr_stand(Name) ->  
  bjgame! {self(), {stand, Name}},
  receive  
    %% Msg == User hasn't started the game
    {_Pid, not_start, Msg} -> Msg;
    %% Msg == User hasn't bet
    {_Pid, not_bet, Msg} -> Msg;
    %% Msg == User reference, Msg1 == List of user's cards, Msg2 == Dealer's cards, Msg3 == Loose or win or draw, Msg4 == User's money
    {_Pid, usr_stand, Msg, Msg1, Msg2, Msg3, Msg4} -> io:format('You are ~p. Your cards are ~p, dealer card(s) are ~p, you ~p. You have ~p ~n', [Msg, Msg1, Msg2, Msg3, Msg4])
  after 1000 -> 
    timeout
  end.

init() -> loop ([]).

% Loop gotta have deck, bet, point from usr n dealer
loop(List) -> 
  receive 
  {From, {start, Name}} ->
    From! {self(), started, Name, 'Please join a room or make a bet of minimum 50 and maximum 500'},
    %what to save here: Pid, deck, bet, user point, dealer point, user card, dealer card.
    loop ([{From, Name, make_deck(),0, [], [], 1000} |List]);

  {From, {bet, Name, N}} ->
    Tuple = member(From, Name, List),
    case Tuple of 
      undefined -> 
        From! {self(), not_start, 'You have to start first'},
        loop (List);
      _         -> 
        M = element(7,Tuple),
        %check if user can bet
        if M < 50 -> 
            From! {self(), loose, 'You have less money than minimum bet, you loose, restart to continue'};
        M < N -> 
          From! {self(), cannot_bet, 'You do not have enough money to bet'},
          loop(List);
        true -> 
        % after bet, deals 2 cards, let the player knows their point
          UsrC = deal(element(3,Tuple), 2), 
          New_deck = element(3, Tuple) -- UsrC,

          % also dealer deals 2 cards and save the points
          DlrC = deal(New_deck, 2),
          D = New_deck -- DlrC,

          From!{self(), bet, Name, N, UsrC, hd(DlrC), M},
          New_tuple = [{Pid, Nm, D, N, UsrC, DlrC, M} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm =:= Name],
          loop(New_tuple ++ List -- [Tuple])
    end
  end;

  {From, {hit, Name}} ->
    Tuple = member(From, Name, List),
      case Tuple of 
        undefined -> 
          From! {self(), not_start, 'You have to start first'},
          loop (List);
        _         -> 
        case element(4, Tuple) of
          0 -> From! {self(), not_bet, 'You have to bet first'},
            loop (List);
          _ -> 
          %Deal 1 card and calculate points
            UsrC = deal(element(3,Tuple), 1), 
            New_UsrC = element(5, Tuple) ++ UsrC,
            UsrP = point(New_UsrC),
            D = element(3, Tuple) -- UsrC,
            
            %get dealer cards to show to user
            DlrC = element(6, Tuple),

            %get money to show to user
            M = element(7,Tuple),
            %check if user loose or still in the game
            if UsrP =< 21 ->
              From!{self(), usr_hit, Name, New_UsrC, hd(DlrC), 'hit or stand?', M},
              New_tuple = [{Pid, Nm,D, N, New_UsrC, DlrC, M} || {Pid, Nm, _, N, _, _, _} <- List, Pid =:= From, Nm == Name] ,
              loop(New_tuple ++ List -- [Tuple]);
            true       -> 
              New_Money = M - element(4,Tuple), 
              From! {self(), usr_hit, Name, New_UsrC, hd(DlrC), loose, New_Money},
              New_tuple = [{Pid, Nm, D, 0, 0, 0, New_Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
              loop(New_tuple ++ List -- [Tuple])
            end
          end
      end;

  {From, {stand, Name}}->
  %Check if user has started the game
  Tuple = member(From, Name, List),
      case Tuple of 
        undefined -> 
          From! {self(), not_bet, 'You have to start first'},
          loop (List);
        _         -> 
        case element(4, Tuple) of
          0 -> From! {self(), not_bet, 'You have to bet first'},
            loop (List);
          _ -> 
        %get most of elements from the tuple
          D = element (3,Tuple),
          Bet  = element(4,Tuple),
          UsrC = element(5,Tuple),
          DlrC = element(6,Tuple),
          Money = element(7,Tuple),
        %calculate points
          UsrP = point(UsrC),
          DlrP = point(DlrC),
          
          if 
            %check if both natural blackjack -> push
          UsrP == 21 andalso length(UsrC) == 2 andalso DlrP == 21 andalso length(DlrC)==2 -> 
            From! {self(), usr_stand, Name, UsrC, DlrC, 'draw', Money},
            New_tuple = [{Pid, Nm, D, 0, 0, 0, Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
            loop(New_tuple ++ List -- [Tuple]);

            %check is user has natural blackjack
          UsrP == 21 andalso length(UsrC) == 2 -> 
            New_Money = Money + 1.5* Bet,
            From! {self(), usr_stand, Name, UsrC, DlrC, 'have blackjack', New_Money},
            New_tuple = [{Pid, Nm, D, 0, 0, 0, New_Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
            loop(New_tuple ++ List -- [Tuple]);
             
          true -> 
              % else dealer will deal card (if neccessary to get over 16 points)
              %calculate dealer's new point and new deck
              New_DlrC = dealer_deal(D, DlrC),
              New_DlrP = point (New_DlrC),
              New_deck = D -- New_DlrC,
              %check if dealer has more than 21 -> win
              if New_DlrP > 21 orelse New_DlrP < UsrP-> 
                  New_Money = Money + Bet,
                  From! {self(), usr_stand, Name, UsrC, New_DlrC, win, New_Money},
                  New_tuple = [{Pid, Nm, New_deck, 0, 0, 0, New_Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
                  loop(New_tuple ++ List -- [Tuple]);
                New_DlrP == UsrP -> 
                  From! {self(), usr_stand, Name, UsrC, New_DlrC, draw, Money},
                  New_tuple = [{Pid, Nm, New_deck, 0, 0, 0, Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
                  loop(New_tuple ++ List -- [Tuple]);
                true -> 
                %User has less points than dealer -> loose
                  New_Money = Money - Bet,
                  From! {self(), usr_stand, Name, UsrC, New_DlrC, loose, New_Money},
                  New_tuple = [{Pid, Nm, New_deck, 0, 0, 0, New_Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
                  loop(New_tuple ++ List -- [Tuple])
              end
            end
          end
     end;

  {From, {double, Name}}->
  %Check if the user has initial bet
   Tuple = member(From, Name, List),
   case Tuple of 
    undefined -> 
       From! {self(), not_bet, 'You have to start first'},
       loop (List);
    _ -> 
    case element(4, Tuple) of
      0 -> From! {self(), not_bet, 'You have to bet first'},
        loop (List);
      _ -> 
        UsrC = element(5,Tuple),
        if
          length(UsrC) == 2 ->
            D = element (3,Tuple),
            Bet  = element(4,Tuple),
            DlrC = element(6,Tuple),
            Money = element(7,Tuple),
        
            % Get the initial bet, double it
            Double_bet = Bet*2,
            % Get one more new card, and add to user cards
            New_UsrC = UsrC ++ deal(D,1),
            New_deck = D -- New_UsrC,
            % Get the points user has before, add with new card's point
            User_newpoint= point(New_UsrC),
          
            % check if user point over 21, if yes then user lose
            if User_newpoint > 21 ->
              New_Money = Money - Double_bet,
              From! {self(), double, Name, New_UsrC, hd(DlrC), loose, New_Money},
              New_tuple = [{Pid, Nm, D, 0, 0, 0, New_Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
              loop(New_tuple ++ List -- [Tuple]);
            % else get dealer's point, add card and calculate new point until dealer's point is bigger than 16   
            true  ->
              New_DlrC = dealer_deal(D, DlrC),
              New_DlrP = point (New_DlrC),
              Final_Deck = New_deck -- New_DlrC,
           
              if New_DlrP > 21 orelse New_DlrP < User_newpoint-> 
                New_Money = Money + Double_bet,
                From! {self(), double, Name, New_UsrC, New_DlrC, win, New_Money},
                New_tuple = [{Pid, Nm, Final_Deck, 0, 0, 0, New_Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
                loop(New_tuple ++ List -- [Tuple]);

              New_DlrP == User_newpoint -> 
                From! {self(), double, Name, New_UsrC, New_DlrC, draw, Money},
                New_tuple = [{Pid, Nm, Final_Deck, 0, 0, 0,Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
                loop(New_tuple ++ List -- [Tuple]);

              true ->
                New_Money = Money - Double_bet,
                From! {self(), double, Name, New_UsrC, New_DlrC, loose, New_Money},
                New_tuple = [{Pid, Nm, Final_Deck, 0, 0, 0, New_Money} || {Pid, Nm, _, _, _, _, _} <- List, Pid =:= From, Nm == Name],
                loop(New_tuple ++ List -- [Tuple])
              end
            end; 
        true -> 
          From! {self(), no_double, Name, 'You cannot double down'},
          loop(List)
        end 
      end
  end
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

make_deck() -> shuffled(deck()).

member(_Pid,L) when L == []-> undefined;
member(Pid,L)   -> 
  if Pid == element(1, hd (L)) -> hd(L);
     true                      -> member(Pid,tl(L))
  end.

member(_Pid, _Name, L) when length(L) == 0-> undefined;
member(Pid, Name, L)                      -> 
  if Pid == element(1, hd (L)) andalso Name == element(2, hd(L)) -> hd(L);
     true                                                        -> member(Pid, Name,tl(L))
  end.