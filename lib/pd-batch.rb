require 'pd'
require 'wavefile'

class PdBatch

  @@debug = false

  def self.debug(state)
    @@debug = state
  end

  def self.generate(dir, patch, output_file, channels, sample_rate, duration)

    Pd.init()
    Pd.init_audio(0, channels, sample_rate)
    Pd.compute_audio(true)

    ticks = 64
    frames = Pd.blocksize() * ticks
    samples = frames * channels

    Pd.openfile(patch, dir)

    inbuf = samples.times.map{|i| 0.0}
    outbuf = samples.times.map{|i| 0.0}
    WaveFile::Writer.new(output_file, WaveFile::Format.new(channels, :pcm_16, sample_rate)) do |writer|
      requested_frames = (duration * sample_rate).to_i
      total_frames = 0
      (requested_frames.to_f / frames).ceil.times do |i|
          Pd.process_float(ticks, nil, outbuf)
          log{"buffer out : #{outbuf.size}"}
          final = outbuf.slice(0, [samples, (requested_frames - total_frames) * channels].min)
          log{"buffer sliced : #{final.size}"}
          final = final.each_slice(channels).to_a if channels > 1
          log{"buffer repacked : #{final.size}"}
          writer.write(WaveFile::Buffer.new(final, WaveFile::Format.new(channels, :float, sample_rate)))
          total_frames += frames
        end
    end    
  end

  def self.process(dir, patch, input_file, output_file)
    
    info = WaveFile::Reader.info(input_file)

    Pd.init()
    Pd.init_audio(info.channels, info.channels, info.sample_rate)
    Pd.compute_audio(true)

    ticks = 64
    frames = Pd.blocksize() * ticks
    samples = frames * info.channels

    Pd.openfile(patch, dir)

    inbuf = samples.times.map{|i| 0.0}
    outbuf = samples.times.map{|i| 0.0}
    WaveFile::Writer.new(output_file, WaveFile::Format.new(info.channels, :pcm_16, info.sample_rate)) do |writer|
      WaveFile::Reader.new(input_file, WaveFile::Format.new(info.channels, :float, info.sample_rate)).each_buffer(frames) do |buffer|
          log{"buffer origin : #{buffer.samples.size}"}
          buffer.samples.flatten!
          log{"buffer modified : #{buffer.samples.size}"}
          inbuf = buffer.samples + (samples - buffer.samples.size).times.map{|i| 0.0}
          log{"buffer input : #{inbuf.size}"}
          Pd.process_float(ticks, inbuf, outbuf)
          log{"buffer out : #{outbuf.size}"}
          final = outbuf.slice(0, buffer.samples.size)
          log{"buffer sliced : #{final.size}"}
          final = final.each_slice(info.channels).to_a if info.channels > 1
          log{"buffer repacked : #{final.size}"}
          writer.write(WaveFile::Buffer.new(final, WaveFile::Format.new(info.channels, :float, info.sample_rate)))
        end
    end    
  end

private
  def self.log(&block)
    puts yield if @@debug
  end

end


