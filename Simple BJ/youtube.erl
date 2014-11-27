 -module (youtube).
 %-export ([fetch_parallel/0,fetch_seq/0]).
 -compile(export_all).
-include_lib("xmerl/include/xmerl.hrl").

 get_feed() -> 
  { ok, {_Status, _Headers, Body }} = httpc:request("http://gdata.youtube.com/feeds/api/videos/SHnTocdD7sk/comments"),  
  { Xml, _Rest } = xmerl_scan:string(Body),
  xmerl_xpath:string("//entry/title/text()", Xml).
 



get_comments(Comment) ->
%#xmlText{value=Id} = Comment,
URL = Comment,
{ok, {_Status,_Headers, Body} } = httpc:request(URL),
{Xml, _Rest} = xmerl_scan:string(Body),
[#xmlText{value = Name}] = xmerl_xpath:string("//author/name/text()",Xml),
[#xmlText{value = Content}] = xmerl_xpath:string("//content/text()",Xml),
{Name,Content, Comment}.

fetch_seq() ->
lists:map(fun get_comments/1,get_feed()).
