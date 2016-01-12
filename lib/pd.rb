require 'ffi'

class Pd 
  extend FFI::Library

  ffi_lib "./libpd.so"

  # from https://github.com/libpd/libpd/blob/master/libpd_wrapper/z_libpd.h
  functions = [
   [:libpd_init, [], :int],
   [:libpd_init_audio, [:int, :int, :int], :int],
   [:libpd_process_float, [:int, :pointer, :pointer], :int],
   [:libpd_openfile, [:string, :string], :int],
   [:libpd_blocksize, [], :int],

   #[:libpd_message, [:string, :string, :int, :pointer], :int],

   [:libpd_start_message, [:int], :int],
   [:libpd_add_float, [:float], :void],
   [:libpd_add_symbol, [:string], :void],
   [:libpd_finish_list, [:string], :int],
   [:libpd_finish_message, [:string, :string], :int]
  ]

  functions.each do |func|
    begin
      attach_function(*func)
      private_class_method func.first
    rescue Object => e
      puts "Could not attach #{func}, #{e.message}"
    end
  end

  def self.init
    check_err libpd_init()
  end

  def self.init_audio(in_channels, out_channels, sample_rate)
    check_err libpd_init_audio(in_channels, out_channels, sample_rate)
  end

  def self.blocksize
    libpd_blocksize()
  end
  def self.openfile(patch, dir)
    id = libpd_openfile(patch, dir)
    raise "error opening patch file #{patch} from #{dir}" if id == 0
    return id
  end

  def self.process_float(ticks, input, output)
    if input then
      input_pointer = FFI::MemoryPointer.new :float, input.size
      input_pointer.put_array_of_float 0, input
    else
      input_pointer = nil
    end
    output_pointer = FFI::MemoryPointer.new :float, output.size
    result = libpd_process_float(ticks, input_pointer, output_pointer)
    output.replace(output_pointer.read_array_of_float(output.size))
    return result
  end

  def self.compute_audio(state)
    send_message("pd", "dsp", state ? 1 : 0) # not working
  end

  def self.send_message(receiver, symbol, *args)
    libpd_start_message(args.size)
    args.each do |arg|
      case 
      when arg.is_a?(String) then libpd_add_symbol(arg)
      when arg.is_a?(Float), arg.is_a?(Integer) then libpd_add_float(arg.to_f)
      else raise "unsupported value #{arg.to_s}, supported are String, Integer or Float"
      end
    end
    libpd_finish_message(receiver, symbol)
  end

private
  def self.check_err(code)
    raise "libpd error #{code}" unless code == 0
  end

end