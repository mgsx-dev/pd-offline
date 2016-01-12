$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'pd-batch'

PdBatch.process(ARGV[0], ARGV[1], ARGV[2], ARGV[3])