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

  end
end
