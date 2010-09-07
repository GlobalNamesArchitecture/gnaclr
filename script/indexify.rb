#!/usr/bin/env ruby

require 'optparse'
require 'sqlite3'
require 'dwc-archive'

OPTIONS = {
  :environment => "development",
  :classification_id => nil,
}

ARGV.options do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: ruby #{script_name} [options]"

  opts.separator ""

  opts.on("-e", "--environment=name", String,
          "Specifies the environment (test/development/production).",
          "Default: development") { |OPTIONS[:environment]| }

  opts.separator ""

  opts.on("-i", "--identifier=classification_id", String,
          "Specifies the id of classification to index",
          "Default: None") { |OPTIONS[:classification_id]| }

  opts.separator ""

  opts.on("-h", "--help",
          "Show this help message.") { puts opts; exit }

  opts.parse!
end

require 'sinatra'

Sinatra::Base.environment == OPTIONS[:environment].to_sym
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false
Sinatra::Application.set :run, false

require File.join(File.dirname(__FILE__), '..', 'application')

class FastDb 
  def initialize
    @db = SQLite3::Database.new( ":memory:" )
    start
  end

  def start
    @db.execute("drop table if exists core")
    @db.execute("create table core (taxon_id varchar primary key, scientific_name varchar, rank varchar)")  
    @db.execute("drop table if exists synonyms")
    @db.execute("create table core (id int primary key autoincrement, taxon_id varchar, scientific_name varchar)")
    @db.execute("drop table if exists vernacular")
    @db.execute("create table core (id int primary key autoincrement, taxon_id varchar, vernacular varchar)")  
  end

  def execute(query)
    @db.execute query
  end
end




classifications = OPTIONS[:classification_id] ? [Classification.first(:id => OPTIONS[:classifications_id])] : Classification.all

classifications.each do |c|
  puts "%s, %s, %s" % [c.id, c.uuid, c.file_name]
end

db = FastDb.new

puts db.execute("select * from core")
