require 'pd-batch'
require 'benchmark'

# Benchmark default settings
#
folder = 'benchmark/patches'
out_channels = 2
sample_rate = 48000
scale = 100

# Benchmark user settings
#
folder = ARGV.first if ARGV.first

## Benchmark script
#

Pd.init()
Pd.init_audio(0, out_channels, sample_rate)
Pd.compute_audio(true)

requested_frames = sample_rate
ticks = ((scale * requested_frames).to_f / Pd.blocksize()).ceil
frames = ticks * Pd.blocksize()

out_samples = frames * out_channels
out_buffer = out_samples.times.map{|i| 0.0}

puts "requested #{requested_frames} frames with scale #{scale}, actual frames #{frames}"

patches = Dir.glob("#{folder}/*.pd").sort.map{|path| File.basename(path)}
label_size = patches.map{|path| path.size}.max + 1

Benchmark.bm (label_size) do |x|
	patches.each do |path|
		patch = Pd.openfile(path, folder)
	  	x.report (path) {
	  		Pd.process_float(ticks, nil, out_buffer)
	  	}
	  	Pd.closefile(patch)
	end
end
