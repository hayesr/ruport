module Ruport::Format

  # PDF generation plugin
  #
  #  layout options:
  #     General:
  #       * paper_size  #=> "LETTER"
  #       * orientation #=> :center
  #     
  #     Table:
  #       * table_width
  #       * max_table_width #=> 500
  #
  class PDF < Plugin
    attr_writer :pdf_writer
    attr_accessor :table_header_proc
    attr_accessor :table_footer_proc

    def initialize
      require "pdf/writer"
      require "pdf/simpletable"
    end

    def pdf_writer
      @pdf_writer ||= 
        ::PDF::Writer.new( :paper => layout.paper_size || "LETTER" )
    end

    def build_table_header
       table_header_proc[pdf_writer] if table_header_proc
    end

    def build_table_body
      draw_table
    end

    def build_table_footer
      table_footer_proc[pdf_writer] if table_footer_proc
    end

    def finalize_table
      output << pdf_writer.render
    end

    def add_text(*args)
      pdf_writer.text(*args)
    end
       
    def rounded_text_box(text)
       opts = OpenStruct.new
       yield(opts)
       
       loop do
         sz = pdf_writer.text_width( text, opts.font_size )
         opts.x + sz > opts.x + opts.width or break
         opts.font_size -= 1
       end

       pdf_writer.fill_color(opts.fill_color || Color::RGB::White)
       pdf_writer.stroke_color(opts.stroke_color || Color::RGB::Black)
       pdf_writer.rounded_rectangle( opts.x, opts.y, 
                                     opts.width, opts.height, opts.radius).fill_stroke
       pdf_writer.fill_color(Color::RGB::Black)
       pdf_writer.stroke_color(Color::RGB::Black)     
       pdf_writer.y = opts.y
       add_text( text,  :absolute_left  => opts.x,
                        :absolute_right => opts.x + opts.width,
                        :justification => opts.justification || :center,
                        :font_size => opts.font_size )     
    end

    def move_cursor(n) 
      pdf_writer.y += n
    end

    def move_cursor_to(n)
      pdf_writer.y = n
    end

    def pad(y,&block)
      move_cursor -y
      block.call
      move_cursor -y
    end

    def draw_table
      m = "Sorry, cant build PDFs from array like things (yet)"
      raise m if data.column_names.empty?
      ::PDF::SimpleTable.new do |table|
        table.maximum_width = layout.max_table_width || 500
        table.width         = layout.table_width if layout.table_width
        table.orientation   = layout.orientation || :center
        table.data          = data
        table.column_order  = data.column_names
        table.render_on(pdf_writer)
      end
    end


  end
end
