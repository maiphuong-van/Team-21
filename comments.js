var request = require('request'),
	cheerio = require('cheerio'),
	fs = require ('fs'),
	id = "YTzxzC728BA",
	tar = "https://www.youtube.com/all_comments?v=" + id,
	comments = [];

request(tar,function(err, resp, body){
	if(!err&&resp.statusCode==200){
		var $ = cheerio.load(body);
		$('.comment-text-content').each(function(){
			var content = $(this).text();
			comments.push(content);		
		});
		fs.writeFile("./comments.js", JSON.stringify(comments), function(err) {
if(err) {
        console.log(err);
  } 
  else {
    console.log("saved");
    }
}); 
	}
});
