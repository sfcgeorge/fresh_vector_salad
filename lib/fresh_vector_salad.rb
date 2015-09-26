require "fresh_vector_salad/version"
require "vector_salad/export_with_magic"
require "ostruct"

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
      puts "Compiling..."
      start = Time.now

      begin
        File.write "#{@o.naked_file}.svg",
          VectorSalad::ExportWithMagic.new(@o).export
        puts "Compiled in #{Time.now - start} seconds."
        auto_render
      rescue Exception => e
        puts e.inspect
        e.backtrace.each { |l| puts l }
        @callbacks.error
      end
    end

    def auto_render
      puts "Rendering..."
      start = Time.now
      if @ink_i.nil?
        puts "Starting Inkscape"
        @ink_o, @ink_i, _x = start_inkscape
      end

      begin
        @ink_o.expect(">") do |result|
          result.each { |r| puts r }
          @ink_i.puts("\"#{@o.naked_file}.svg\" --export-background=white --export-dpi=#{@o.dpi} --export-png=\"#{@o.naked_file}.png\"")
        end
        @ink_o.expect("Bitmap saved") do |result|
          result.each { |r| puts r }
        end
        @callbacks.success
        puts "Rendered in #{Time.now - start} seconds."
      rescue Exception => e
        puts e.inspect
        e.backtrace.each { |l| puts l }
        @callbacks.error
      end
    end

    def start_inkscape
      ink = "inkscape -z --shell"
      PTY.spawn(ink)
    end
  end
end
