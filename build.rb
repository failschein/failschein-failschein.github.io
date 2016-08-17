#!/usr/bin/ruby
# 
# make sure you have pandoc, imagemagick and optipng installed
# maybe you need to adjust font_size and font_width for your system
# if you changed these values do not push them!
#
require "digest/md5"

class String
    def string_between_markers marker1, marker2
		self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
    end

    def draw_screenshot font_size, font_width, target_filename, main_color, stroke_color
		estimated_width = self.length * font_width
	    estimated_rows  = self.count("\n") + 1

	    params = [
	    	"-size #{estimated_width}x#{estimated_rows * font_size * 1.2}",
	    	"xc:transparent",
	    	"-pointsize #{font_size}",
	    	"-fill #{main_color}",
	    	"-stroke #{stroke_color}",
	    	"-draw \"text #{font_size*0.05},#{font_size*0.95} '#{self}'\""
	    ]

	    puts "\t\tinvoke imagemagick"
	    system("convert #{params.join ' '} #{Dir.pwd}/#{target_filename}")

	    puts "\t\tinvoke optipng"
	    old_size = File.size target_filename
	    system("optipng -zc8-9 -zm8-9 -zs3-4 -quiet #{Dir.pwd}/#{target_filename}")
	    new_size = File.size target_filename
	    puts "\t\t\tsaved #{(old_size-new_size).fdiv(old_size) * 100}%"
	    puts "\t\t\timage is now #{new_size.fdiv(1000).round} kb"
    end
end

tempfile    = "/tmp/readme.md"
used_quotes = []

puts "read input file..."
filecontent = File.read("readme.md")

puts "rewrite quotes..."
while filecontent.include? "IMGQUOTE" do
	puts "\t processing quote (#{filecontent.scan('<IMGQUOTE>').size - 1} more to do)"

   	quote           = filecontent.string_between_markers "<IMGQUOTE>", "</IMGQUOTE>"
   	quote_md5       = Digest::MD5.hexdigest(quote)
   	screenshot_path = "quotes/#{quote_md5}.png"

    unless File.exist? screenshot_path
    	font_size  = 100
    	font_width =  41
    	quote.strip.draw_screenshot font_size, font_width, screenshot_path, "'#B5E853'", "black"
    end

    replacement = "> \n"+
                  "> ![Zitat](#{screenshot_path}) \n"+
                  "> \n"

    filecontent.gsub!("<IMGQUOTE>#{quote}</IMGQUOTE>", replacement)

    used_quotes << screenshot_path
end

puts "cleanup"
all_stored_quotes = Dir["quotes/*"].to_a
all_stored_quotes.each do |file|
	unless used_quotes.include? file
		puts "\tdeleted #{file}"
		File.delete file
	end
end

puts "write output markdown..."
File.open(tempfile, 'w') do |file| 
	file.write(filecontent)
end

puts "invoke pandoc..."
include_formats=["footnotes", "fenced_code_attributes", "simple_tables", "markdown_in_html_blocks"]
pandoc_params  =[
	"--smart",
	"--toc",
	"--normalize",
	"-f markdown_github+#{include_formats.join '+'}",
	"--highlight-style=espresso",
	"--template=template.html"
]
system("pandoc #{pandoc_params.join ' '} #{tempfile} -o index.html")
