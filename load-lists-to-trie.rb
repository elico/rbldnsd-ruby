#!/usr/bin/env ruby

require 'json'
require "trie"

$lists_path = '/var/rbldnsd/db'

$lists = {}

def readListMetaData(filename)
  err = 1
  file = File.read(filename)
  begin
    data_hash = JSON.parse(file)
    err = 0
  rescue StandardError => e
    puts e
    puts e.inspect
    return { 'err' => err }
  end

  data_hash
end

def readListFile(filename)
  
  list = Trie.new()

  File.foreach(filename).with_index do |line, _line_num|
    #	puts "#{line_num}: #{line}"

    line = line.chomp.strip
    list.insert(line,1) if line.match(/^[a-zA-Z0-9.\-]+$/) ## valid domain characters
  end
  return list
end

Dir.entries($lists_path).select do |entry|
  next if ['.', '..'].include?(entry)

  metadata_filename = "#{File.join($lists_path, entry)}/metadata.json"

  list_filename = "#{File.join($lists_path, entry)}/list"

  next unless File.directory?(File.join($lists_path, entry))

  next unless File.exist?(metadata_filename) and File.exist?(list_filename)

  metadata = readListMetaData(metadata_filename)
  if metadata.nil? or metadata['err'] == 1
    puts("Error in metadata file: #{metadata_filename}")
    next
  end
  $lists["#{metadata['key']}"] = metadata

  $lists["#{metadata['key']}"]['list'] = readListFile(list_filename)
end
