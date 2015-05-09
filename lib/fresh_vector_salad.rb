require "fresh_vector_salad/version"
require 'vector_salad/export_with_magic'
require 'ostruct'

module FreshVectorSalad
  class Fresh
    def initialize(options, callbacks)
      @o = options
      @callbacks = callbacks
    end

    def auto
      auto_compile
      auto_render
    end

    def auto_compile
      puts 'Compiling...'
      start = Time.now

      #_, _, stderr = start_vector_salad
      #if e = stderr.gets
        #puts e
        #@callbacks.error
      #else
        #puts "Compiled in #{Time.now - start} seconds."
        #auto_render
      #end

      begin
        options = OpenStruct.new
        options.file = "#{@o.path}/#{@o.file}.rb"
        options.width = @o.width
        options.height = @o.height
        o = VectorSalad::ExportWithMagic.new(options).export
        File.open("#{@o.path}/#{@o.file}.svg", 'w') do |file|
          file.sync = true
          file.write(o)
          file.fsync
        end
        File.write("#{@o.path}/#{@o.file}.svg", o)
        puts "Compiled in #{Time.now - start} seconds."
        auto_render
      rescue Exception => e
        puts e.inspect
        e.backtrace.each{ |l| puts l }
        @callbacks.error
      end
    end

    def start_vector_salad
      vs = "vector_salad -f \"#{@o.path}/#{@o.file}.rb\" > \"#{@o.path}/#{@o.file}.svg\""
      return Open3.popen3(vs)
    end

    def auto_render
      puts 'Rendering...'
      start = Time.now
      if @ink_i.nil?
        puts 'Starting Inkscape'
        @ink_o, @ink_i, _ = start_inkscape
      end

      begin
        @ink_o.expect(">") do |result|
          result.each{ |r| puts r }
          @ink_i.puts("\"#{@o.path}/#{@o.file}.svg\" --export-background=white --export-dpi=#{@o.dpi} --export-png=\"#{@o.path}/#{@o.file}.png\"")
        end
        @ink_o.expect("Bitmap saved") do |result|
          result.each{ |r| puts r }
        end
        @callbacks.success
        puts "Rendered in #{Time.now - start} seconds."
      rescue Exception => e
        puts e.inspect
        e.backtrace.each{ |l| puts l }
        @callbacks.error
      end
    end

    def start_inkscape
      ink = "inkscape -z --shell"
      #Open3.popen3(ink)
      PTY.spawn(ink)
    end
  end
end
