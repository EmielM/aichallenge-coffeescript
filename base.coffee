fs = require 'fs'

logFd = fs.openSync "ai-log", "a"
exports.log = (line) ->
	fs.writeSync logFd, "#{line}\n"

class exports.AIChallenger
	
	rowColToKey = (row, col) -> ((row << 16) | col)
	keyToRowCol = (key) -> [(key >> 16), (key & 0xffff)]
	
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
				key = rowColToKey(row, col)
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

	order: (row, col, dir) ->
		key = rowColToKey(row, col)
		@orders[key] = dir
	
	go: ->
		for key, dir of @orders
			[row, col] = keyToRowCol(key)
			fs.writeSync process.stdout.fd, "o #{row} #{col} #{dir}\n"
		
		@orders = {}
		fs.writeSync process.stdout.fd, "go\n"
		process.stdout.flush()

	eachOwnAnt: (func) ->
		for key, team of @ants
			return if team != 0
			rowCol = keyToRowCol(key)
			func(rowCol[0], rowCol[1])
	
	direction: (row, col, dir) ->
		switch dir
			when "N" then row = row - 1
			when "S" then row = row + 1
			when "W" then col = col - 1
			when "E" then col = col + 1
		row = (row + @rows) % @rows
		col = (col + @cols) % @cols
		[row, col]
	
	validMove: (row, col, dir) ->
		[row, col] = @direction(row, col, dir)
		key = rowColToKey(row, col)
		!(@water[key]? || @ants[key]?)
		
	whatsat: (row, col) ->
		key = rowColToKey(row, col)
		
		what = []
		what.push "water" if @water[key]?
		what.push "hill" if @hills[key]?
		what.push "food" if @food[key]?
		what.push "ant" if @ants[key]?
		what.push "dead" if @deads[key]?
		
		what