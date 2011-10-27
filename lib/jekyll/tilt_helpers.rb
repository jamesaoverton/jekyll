module Jekyll

  module TiltHelpers
    # Convert a Markdown string into HTML output.
    #
    # input - The Markdown String to convert.
    #
    # Returns the HTML formatted String.
    def markdownify(input)
      Tilt['md'].new{input}.render
    end
    
    # Create a URL by appending to the site.url.
    #
    # target - The path to append.
    #
    # Returns the new URL String.
    def link(target)
      File.join(site.url, target)
    end
    
    # Truncate the Markdown input after the first paragraph then convert it.
    #
    # input - The Markdown String to truncate and convert.
    #
    # Returns the truncated converted HTML String.
    def markdownjump(input)
      content = ""
      paragraph = false
      for line in input.lines
        break if line.strip.length == 0 and paragraph
        content += line
        next if line.strip.length == 0
        next if line.start_with? "#"
        next if line.start_with? "-"
        paragraph = true
      end
      Tilt['md'].new{content}.render
    end

  end
end
