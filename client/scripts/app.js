document.addEventListener("DOMContentLoaded", function(){
  'use strict';
  
	var data = { round: 0, results:[], cards: [] }, // model
      socket = io();

  var $round = document.getElementById("round"),
      $dealer = document.getElementById("dealer"),
      $player = document.getElementById("player"),
      $prevRound = document.getElementById("prev-round"),
      $prevDealer = document.getElementById("prev-dealer"),
      $prevPlayer = document.getElementById("prev-player");

  window.hit = hit;
  
  window.stand = stand;
    
	socket.on('api', function(d) {

		if(d.results) console.log(d.results[0].type);
    
    if(d.round) data.round = d.round;
    
		// merge results
		if(d.results) data.results = _.sortBy(data.results.concat(d.results), function(c){
			return new Date(c.timeCreated);
		});

		// merge cards
		if(d.cards) data.cards = _.sortBy(data.cards.concat(d.cards), function(c){
			return new Date(c.timeCreated);
		});

    draw();
    
	});

  function draw() {
    $round.innerHTML = 'Round #' + data.round;
    $prevRound.innerHTML = 'Round #' + (data.round - 1) + ' ' + (_.last(data.results) ? _.last(data.results).type : '');
    
    $dealer.innerHTML = _.reduce(_.where(data.cards, { round: data.round, creator: 'dealer' }), toHTML, '');
    $prevDealer.innerHTML = _.reduce(_.where(data.cards, { round: data.round - 1, creator: 'dealer' }), toHTML, '');
    
    $player.innerHTML = _.reduce(_.where(data.cards, { round: data.round, creator: 'player' }), toHTML, '');
    $prevPlayer.innerHTML = _.reduce(_.where(data.cards, { round: data.round - 1, creator: 'player' }), toHTML, '');
    
    function toHTML(memo, card){ return memo + "<img width=100 src='/images/" + card.suit + "-" + card.rank + ".png'>"; }
  }
  
	function hit() {
    socket.emit('api', { type: 'hit' });
	}

	function stand() {
    socket.emit('api', { type: 'stand' });
	}
  
});