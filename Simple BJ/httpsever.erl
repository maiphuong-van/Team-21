
-module(httpsever).
-export([start/0]).


start() -> 
inets:start(),

Port = 10111,
  {Httpd_State, _Httpd_Pid} = inets:start(httpd, [{port, Port},
    {server_name, "localhost"}, {document_root, "."},
    {modules,[mod_esi]},{server_root, "."},
    {erl_script_alias, {"/esi", [game21, io]}}]),
  io:format("Webserver started at port ~p. Status ~p.~n", [Port, Httpd_State]).
  %http://localhost/esi/game21:start