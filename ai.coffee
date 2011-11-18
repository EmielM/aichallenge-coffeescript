#!/usr/bin/env coffee

{AIChallenger} = require "/Users/emiel/Projects/aichallenge-coffeescript/base.coffee"

util = require "util"

log = (line) -> process.stderr.write "#{line}\n"

class MyBot extends AIChallenger
	
	dirs = ["N", "S", "E", "W"]
	
	onReady: ->
		log "onReady"
		@go()
		
	debugMap: (data) ->
		str = ''
		for r in [0...@rows]
			for c in [0...@cols]
				rc = @toRC(r, c)
				val = data[rc]
				if val == true
					str += "XX "
				else if typeof(val) == "number"
					str += String(val).substr(0, 2) + " "
				else if @water[rc]?
					str += "~~ "
				else
					str += ".. "
			str += "\n"
		str


	radiateScore: (rc, score, dist) ->
		
		queue = [ [rc, score, dist] ]
		done = {}
		
		while (queue.length)
			[rc, score, dist] = queue.pop()
			continue if done[rc]? || @water[rc]
			
			done[rc] = true
			
			@score[rc] = (@score[rc] || 0) + score

			dist = dist - 1
			continue if dist == 0
			
			if score > 0
				score = score - (score / dist)
			else
				score = score + (score / dist)
			
			queue.push [@direction(rc, 'N'), score, dist]
			queue.push [@direction(rc, 'S'), score, dist]
			queue.push [@direction(rc, 'E'), score, dist]
			queue.push [@direction(rc, 'W'), score, dist]

	onTurn: ->
		
		# Calculate "coolness" factor of every rc by doing
		# a breadth-first search from interesting objects
		# and radiating scores outward. This accounts for
		# water elements.
		
		# Ultimately, this couldbe done more efficient by
		# not redoing it every turn, but the required
		# differential logic makes it a lot of work and
		# error prone.
		
		@score = {}
		for rc, team of @ants
			if team == 0
				# attracted to own ants
				@radiateScore rc, 5, 2
			else
			 	# repelled from other ants
				@radiateScore rc, -8, 5

		for rc, team of @hills
			if team == 0
				# repelled from own hill
				@radiateScore rc, -4, 4
			else
				# attracted to other hills
				@radiateScore rc, 100, 20
		
		for rc of @food
			# attracted to food
			@radiateScore rc, 50, 15
			
		log "scores:\n#{@debugMap(@score)}"
		
		@eachOwnAnt (rc) =>
			bestScore = -1000
			bestDir = false
			
			dirs.sort () -> Math.random() - 0.5
				# reorder dirs to be more random 
				
			for dir in dirs
				rcTry = @direction(rc, dir)
				log "#{dir} yields #{@score[rcTry]}"
				if @score[rcTry]? && @score[rcTry] > bestScore
					bestDir = dir
					bestScore = @score[rcTry]
			
			if bestDir
				# order ant to new position; prevent other
				# ants from going there
				@order rc, bestDir
				@score[@direction(rc, bestDir)] = -1000
				
				[row, col] = @fromRC(rc)
				log "ant(#{row},#{col}) to #{bestDir}!"
			else
				# don't move; prevent other ants from going
				# here
				@score[rc] = -1000
		
		@go()
		
	onEnd: ->
		log "onEnd"


new MyBot().start()

