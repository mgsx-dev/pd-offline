$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'pd-batch'

PdBatch.generate(ARGV[0], ARGV[1], ARGV[2], ARGV[3].to_i, ARGV[4].to_i, ARGV[5].to_f)