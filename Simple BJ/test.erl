
-module(test).
-import(game21, [start/0,stop/0, init/0,usr_bet/2,
  usr_double_down/1,usr_hit/1,usr_stand/1,make_deck/0,usr_start/1]).
-export([test/0]).

test() ->
 start(),
 spawn(fun() ->
	 io:format("Process ~p started!\n", [self()]),
	 io:format("~p user start: ~p\n", [self(), usr_start(a)]),
	 io:format("~p User bet: ~p\n", [self(), usr_bet(a,100)]),
	 io:format("~p User hit: ~p\n", [self(), usr_hit(a)]),
	 io:format("~p User stand: ~p\n", [self(), usr_stand(a)])
	 end),
 spawn(fun() ->
	io:format("Process ~p started!\n", [self()]),
	io:format("~p user start: ~p\n", [self(), usr_start(b)]),
	io:format("~p User bet: ~p\n", [self(), usr_bet(b,50)]),
	io:format("~p User double down: ~p\n", [self(), usr_double_down(b)])
	end),
 spawn(fun() ->
	io:format("Process ~p started!\n", [self()]),
	io:format("~p user start: ~p\n", [self(), usr_start(c)]),
	io:format("~p User bet: ~p\n", [self(), usr_bet(c,60)]),
	io:format("~p User stand: ~p\n", [self(), usr_stand(c)])
	end),
  spawn(fun() ->
	io:format("Process ~p started!\n", [self()]),
	io:format("~p user start: ~p\n", [self(), usr_start(d)]),
	io:format("~p User bet: ~p\n", [self(), usr_bet(d,100)]),
	io:format("~p User stand: ~p\n", [self(), usr_hit(d)]),
	io:format("~p User double down: ~p\n", [self(), usr_double_down(d)])
	end),
 ok.

