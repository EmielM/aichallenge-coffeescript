fs = require 'fs'

class exports.AIChallenger
	
	toRC = (row, col) -> ((row << 16) | col)
	fromRC = (key) -> [(key >> 16), (key & 0xffff)]
	
	toRC: toRC
	fromRC: fromRC
	
	start: ->
		@water = {}
		@hills = {}
		@food = {}
		@ants = {}
		@deads = {}

		@orders = {}
		
		process.stdin.resume()
		process.stdin.setEncoding 'utf8'
		
		buffer = ""
		process.stdin.on 'data', (chunk) => 
			lines = chunk.split("\n")
			lines[0] = buffer + lines[0]
			
			buffer = ""
			if lines[lines.length - 1] != ""
				# incomplete line received; put in buffer
				buffer = lines.pop()
			
			@process line for line in lines
			
	process: (line) ->
		
		line = line.trim().split(' ')
		
		command = line[0]
		
		return if command == ""
		
		switch command
			when "ready" then @onReady()
			when "go" then @onTurn()
			when "end" then @onEnd()
				
			when "turn"
				@turn = parseInt(line[1])
				if @turn > 0
					# reset all but water
					@hills = {}
					@food = {}
					@ants = {}
					@deads = {}
			
			when "w", "f", "a", "h", "d"
				[row, col, owner] = line[1..]
				row = parseInt(row)
				col = parseInt(col)
				key = toRC(row, col)
				val = if owner? then parseInt(owner) else true
				
				switch command
					when "w" then @water[key] = val
					when "f" then @food[key] = val
					when "a" then @ants[key] = val
					when "h" then @hills[key] = val
					when "d" then @deads[key] = val

			else
				if @turn == 0
					value = line[1]
					#log "config[#{command}] = #{value}"
					this[command] = parseInt(value)

	order: (rc, dir) ->
		@orders[rc] = dir
	
	go: ->
		for rc, dir of @orders
			[row, col] = fromRC(rc)
			process.stdout.write "o #{row} #{col} #{dir}\n"
		
		@orders = {}
		process.stdout.write "go\n"
		process.stdout.flush()

	eachOwnAnt: (func) ->
		for rc, team of @ants
			func(rc) if team == 0
	
	direction: (rc, dir) ->
		[row, col] = fromRC(rc)
		switch dir
			when "N" then row = row - 1
			when "S" then row = row + 1
			when "W" then col = col - 1
			when "E" then col = col + 1
		row = (row + @rows) % @rows
		col = (col + @cols) % @cols
		toRC(row, col)
	
	valid: (rc) ->
		!(@water[rc]? || @ants[rc]?)
		
	whatsat: (rc) ->
		what = []
		what.push "water" if @water[rc]?
		what.push "hill" if @hills[rc]?
		what.push "food" if @food[rc]?
		what.push "ant" if @ants[rc]?
		what.push "dead" if @deads[rc]?
		
		what