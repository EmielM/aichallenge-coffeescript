#!/usr/bin/env coffee

{AIChallenger} = require "./base.coffee"

util = require "util"

log = (line) -> process.stderr.write "#{line}\n"

class MyBot extends AIChallenger
	
	onReady: ->
		@go()
		
	debugMap: ->
		str = ''
		for r in [0...@rows]
			for c in [0...@cols]
				rc = @toRC(r, c)
				
				attrs = [0,2]
				fg = 37
				bg = 40
				text = "."

				if @score[rc]?
					val = @score[rc]
					if val < 0
						val = -val
						attrs.push(4)
					text = Math.floor((val / 100) * 10)

				if @food[rc]?
					attrs = [0]
					text = "."
					
				if @hills[rc]?
					attrs = [0]
					bg = 31 + @hills[rc]
					text = "#"

				if @ants[rc]?
					attrs = [0]
					fg = 31 + @ants[rc]
					text = "*"
				
				if @water[rc]?
					attrs = [0]
					fg = 34
					bg = 44
					text = " "
				
				str += attrs.map((a) -> "\x1b[#{a}").join("m")
				str += ";#{fg};#{bg}m#{text}"
			str += "\n"
		str += "\x1b[0;0;0m"
		str


	radiateScore: (rc, score, dist) ->
		
		queue = [ [rc, score, dist] ]
		done = {}
		
		while (queue.length)
			[rc, score, dist] = queue.shift()
			continue if done[rc]? || @water[rc]
			
			done[rc] = true
			
			@score[rc] = (@score[rc] || 0) + score

			score = score - (score / dist)

			dist = dist - 1
			continue if dist == 0
			
			queue.push [@direction(rc, 'N'), score, dist]
			queue.push [@direction(rc, 'S'), score, dist]
			queue.push [@direction(rc, 'E'), score, dist]
			queue.push [@direction(rc, 'W'), score, dist]

	dirs = ["N", "S", "E", "W"]

	onTurn: ->
		
		# Calculate "attractiveness" of every rc by doing
		# a breadth-first search from interesting objects
		# and radiating scores outward. This accounts for
		# water elements.
		
		# Ultimately, this could be done more efficient by
		# not redoing it every turn, but the required
		# differential logic makes it a lot of work and
		# error prone.
		
		@score = {}

		for rc, team of @hills
			if team == 0
				# repelled from own hill
				@radiateScore rc, -80, 40
			else
				# attracted to other hills
				@radiateScore rc, 100, 20
		
		for rc of @food
			# attracted to food
			@radiateScore rc, 50, 15
		
		for rc, team of @ants
			if team == 0
				# little attraction to own ants
				@radiateScore rc, 2, 1
			else
			 	# repelled from other ants
				@radiateScore rc, -8, 5

		# repelled from explored stuff
			
		#log "scores:\n#{@debugMap(@score, 100)}"


		colSum = 0
		rowSum = 0
		antCount = 0
		@eachOwnAnt (rc) =>
			[row, col] = @fromRC(rc)
			colSum += col
			rowSum += row
		
		#@radiateScore @toRC(Math.round(rowSum / antCount), Math.round(colSum / antCount)), -10, 50

		blocks = {}
		@eachOwnAnt (rc) =>
			blocks[rc] = true

		@eachOwnAnt (rc) =>
		
			bestRc = false
			bestDir = false
			bestScore = -1000
			#if @score[rc]?
			#	bestScore = @score[rc]
			
			dirs.sort () -> Math.random() - 0.5
			for dir in dirs
				tryRc = @direction(rc, dir)
				if !@water[tryRc]? && !blocks[tryRc]? && (@score[tryRc]||0) > bestScore
					bestRc = tryRc
					bestDir = dir
					bestScore = (@score[tryRc]||0)
			
			if bestRc
				@order rc, bestDir
				blocks[bestRc] = -1000
				delete blocks[rc]
		
		@go()
		
	onEnd: ->
		log "onEnd"


new MyBot().start()

