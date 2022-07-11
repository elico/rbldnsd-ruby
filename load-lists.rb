#!/usr/bin/env ruby

require "json"

$lists_path = "/var/rbldnsd/db"

$lists = {}

def readListMetaData(filename)
	err = 1
	file = File.read(filename)
	begin
		data_hash = JSON.parse(file)
		err = 0
	rescue => e
		puts e
		puts e.inspect
		return {"err" => err }
	end
	
	return data_hash
end

def readListFile(filename)
	list = []

	File.foreach(filename).with_index do |line, line_num|
   	#	puts "#{line_num}: #{line}"
   		
   		line = line.chomp.strip
		if line.match(/^[a-zA-Z0-9\.\-]+$/) ## valid domain characters
			list << line
		end
	end
	return list
end

Dir.entries($lists_path).select do |entry| 
	next if entry =='.' || entry == '..'

	metadata_filename = "#{(File.join($lists_path, entry))}/metadata.json"

        list_filename = "#{(File.join($lists_path, entry))}/list"

	if File.directory?(File.join($lists_path, entry))
		if File.exists?(metadata_filename) and File.exists?(list_filename)
			metadata = readListMetaData(metadata_filename)
			if metadata.nil? or metadata["err"] == 1
				puts("Error in metadata file: #{metadata_filename}")
				next
			end
			$lists["#{metadata["key"]}"] = metadata

			$lists["#{metadata["key"]}"]["list"] = readListFile(list_filename)
		end
	end
end
