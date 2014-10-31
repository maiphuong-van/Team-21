var _ = require('underscore'),
    http = require('http'),
    mime = require('mime'),
    path = require('path'),
    url = require('url'),
    fs = require('fs');

var server = http.createServer(httpHandler),
    io = require('socket.io')(server);

io.on('connection', wsHandler);

server.listen(1338);

console.log('hosting web app on http://127.0.0.1:1338');

function wsHandler(socket){

  var deck = [],
      round = 0,
      dealerHand = [],
      playerHand = [];

  nextRound();

  socket.on('api', function(d){

    if(d.type === 'hit') {
      var cards = addRound(deck.splice(0, 1)); // get a single card for a player
      playerHand = playerHand.concat(cards); // add it to server memory
      socket.emit('api', { cards: cards }); // send it to client
    }

    var dealerValue = getIdealValue(dealerHand),
        playerValue = getIdealValue(playerHand);

    // on hit
    if(d.type === 'hit') {
      if(playerValue <= 21) return;
      
      socket.emit('api', { results: [{
        type: 'lose',
        timeCreated: new Date().toJSON()
      }] });
      
      return nextRound();
    }

    if(d.type === 'stand') {
      socket.emit('api', { cards: [dealerHand[1]] });
      
      (function check(take){
        if(take) {
          var cards = _.map(addRound(deck.splice(0, 1)), function(c){ c.creator = 'dealer'; return c; });
          dealerHand = dealerHand.concat(cards);
          socket.emit('api', { cards: cards });
          dealerValue = getIdealValue(dealerHand);
        }
        
        if(dealerValue < 17) return setTimeout(check, 1000, true);
        
        if(dealerValue < 21 && dealerValue > playerValue){
          socket.emit('api', { results: [{ type: 'lose', timeCreated: new Date().toJSON() }] });
          return nextRound();
        }
        
        if(dealerValue > 21) socket.emit('api', { results: [{ type: 'win', timeCreated: new Date().toJSON() }] });
        else if(playerValue > dealerValue) socket.emit('api', { results: [{ type: 'win', timeCreated: new Date().toJSON() }] });
        else socket.emit('api', { results: [{ type: 'draw', timeCreated: new Date().toJSON() }] });
        
        return nextRound();
      }());
    }

  });

  function nextRound(){
  
    console.log(getIdealValue(dealerHand), getIdealValue(playerHand))
    
    round += 1;
    
    if(deck.length < 20) deck = getDeck(); // check if deck needs to be reshuffled

    // we update the dealer card creators from the default "player" to "dealer"
    dealerHand = addRound(_.map(deck.splice(0, 2), function(c){ c.creator = 'dealer'; return c; }));
    
    // get cards for player
    playerHand = addRound(deck.splice(0, 2));

    // add the two player cards to the one open dealer card
    var cards = playerHand.concat([dealerHand[0]]);

     // check if dealer has blackjack (aces are counted as having a value of 1)
    if(dealerHand[0].value + dealerHand[1].value === 11 && _.findWhere(dealerHand, { rank: 1 })) {
      cards.push(dealerHand[1]);
      nextRound();
    }
  
    socket.emit('api', { round: round, cards: cards }); // send cards to client
  }

  function getDeck() {

    var array = [];

    for(var i = 1; i <= 13; i++){
      for(var s = 0; s <= 3; s++){
        array.push({
          value: i > 10 ? 10 : i, // blackjack value for a card
          rank: i, // 1 = Ace, 2 = 2, ...., 11 = Jack, 12 = Queen, 13 = King
          creator: "player", // default creator of a card
          suit: ["hearts", "spades", "diamonds", "clubs"][s]
        });
      }
    }
    return _.shuffle(array);

  }
  
  // calculates the highest score, still below or equal to 21
  function getIdealValue(hand) {
  
    // calculate minimum value of this hand, with all aces counting as 1
    var min = _.reduce(hand, function(memo, c){ return memo + c.value; }, 0);
     
    // for every ace you find, add 10 points to the total value if it will not exceed 21
    return _.reduce(hand, function(memo, c){
      return c.rank === 1 && memo + 10 <= 21 ? memo + 10 : memo;
    }, min);
  
  }

  function addRound(cards){ return _.map(cards, function(c){ c.round = round; return c; }); }
    
}


function httpHandler(req, res) {

  var pathname = url.parse(req.url).pathname,
    filename = path.join(process.cwd(), 'client' + pathname);

  fs.exists(filename, function(exists) {

    if(!exists || fs.lstatSync(filename).isDirectory()) {
      filename = path.join(process.cwd(), 'client/index.html');
    }

    var type = mime.lookup(filename);

    fs.readFile(filename, 'binary', function(err, file) {
      if(err) {
        res.writeHead(500, {'Content-Type': 'text/plain'});
        res.write(err + '\n');
        res.end();
        return;
      }

      res.writeHead(200, {'Content-Type': type});
      res.write(file, 'binary');
      res.end();
    });
  });
}
