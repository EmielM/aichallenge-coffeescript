#!/usr/bin/env coffee

{AIChallenger, log} = require "/Users/emiel/Projects/aichallenge/coffee/base.coffee"
util = require "util"

class MyBot extends AIChallenger
	
	dirs = ["N", "S", "E", "W"]
	
	onReady: ->
		log "onReady"
		@go()
	
	onTurn: ->
		log "onTurn"
		@eachOwnAnt (row, col) =>
			for dir in dirs
				if @validMove(row, col, dir)
					log "ant(#{row},#{col}) to #{dir}!"
					@order(row, col, dir)
					break
					
				else
					log "ant(#{row},#{col}) unable to move #{dir}"
		
		@go()
		
	onEnd: ->
		log "onEnd"


new MyBot().start()

