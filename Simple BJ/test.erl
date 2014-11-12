
-module(test).
-import(game21, [start/0,stop/0, init/0,usr_bet/1,
  usr_double_down/0,usr_hit/0,usr_stand/0,make_deck/0,usr_start/0]).
-export([test/0]).

test() ->
 start(),
 spawn(fun() ->
 io:format("Process ~p started!\n", [self()]),
 io:format("~p user start: ~p\n", [self(), usr_start()]),
 io:format("~p User bet: ~p\n", [self(), usr_bet(10)]),
 io:format("~p User bet: ~p\n", [self(), usr_bet(10)]),
 io:format("~p User bet: ~p\n", [self(), usr_bet(20)])
 end),
 spawn(fun() ->
io:format("Process ~p started!\n", [self()]),
 io:format("~p user start: ~p\n", [self(), usr_start()]),
 io:format("~p User bet: ~p\n", [self(), usr_bet(30)]),
 io:format("~p User bet: ~p\n", [self(), usr_bet(50)])
 end),
 spawn(fun() ->
io:format("Process ~p started!\n", [self()]),
 io:format("~p user start: ~p\n", [self(), usr_start()]),
 io:format("~p User bet: ~p\n", [self(), usr_bet(30)]),
 io:format("~p User bet: ~p\n", [self(), usr_bet(50)])
 end),
 ok.

