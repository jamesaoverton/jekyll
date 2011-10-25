require 'set'

require 'tilt'
require 'slim'
Slim::Engine.set_default_options :pretty => true

# Convertible provides methods for converting a pagelike item
# from a certain type of markup into actual content
#
# Requires
#   self.site -> Jekyll::Site
#   self.content
#   self.content=
#   self.data=
#   self.ext=
#   self.output=
module Jekyll
  module Convertible
    # Returns the contents as a String.
    def to_s
      self.content || ''
    end

    # Read the YAML frontmatter.
    #
    # base - The String path to the dir containing the file.
    # name - The String filename of the file.
    #
    # Returns nothing.
    def read_yaml(base, name)
      self.content = File.read(File.join(base, name))

      if self.content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
        self.content = $POSTMATCH

        begin
          self.data = YAML.load($1)
        rescue => e
          puts "YAML Exception reading #{name}: #{e.message}"
        end
      end

      self.data ||= {}
    end

    # Transform the contents based on the content type.
    #
    # Returns nothing.
    def transform
      self.content = converter.convert(self.content)
    end

    # Determine the extension depending on content_type.
    #
    # Returns the String extension for the output file.
    #   e.g. ".html" for an HTML output file.
    def output_ext
      converter.output_ext(self.ext)
    end

    # Determine which converter to use based on this convertible's
    # extension.
    #
    # Returns the Converter instance.
    def converter
      @converter ||= self.site.converters.find { |c| c.matches(self.ext) }
    end

    def render_tilt_in_context(ext, content, params={})
      context = ClosedStruct.new(params)
      Tilt[ext].new{content}.render(context)
    end

    # Add any necessary layouts to this convertible document.
    #
    # payload - The site payload Hash.
    # layouts - A Hash of {"name" => "layout"}.
    #
    # Returns nothing.
    def do_layout(payload, layouts)
      info = { :filters => [Jekyll::Filters], :registers => { :site => self.site } }

      # render and transform content (this becomes the final content of the object)
      payload["pygments_prefix"] = converter.pygments_prefix
      payload["pygments_suffix"] = converter.pygments_suffix

      begin
        self.content = Liquid::Template.parse(self.content).render(payload, info)
      rescue => e
        puts "Liquid Exception: #{e.message} in #{self.name}"
      end

      self.transform

      # output keeps track of what will finally be written
      self.output = self.content

      # recursively render layouts
      layout = layouts[self.data["layout"]]
      used = Set.new([layout])

      while layout
        payload = payload.deep_merge({"content" => self.output, "page" => layout.data})

        # Switch between Tilt and Liquid rendering
        if layout.ext == '.html'
          begin
            self.output = Liquid::Template.parse(layout.content).render(payload, info)
          rescue => e
            puts "Liquid Exception: #{e.message} in #{self.data["layout"]}"
          end
        else
          begin
            self.output = render_tilt_in_context(layout.ext, layout.content,
              :site => ClosedStruct.new(payload["site"]),
              :page => ClosedStruct.new(payload["page"]),
              :content => payload["content"]
            )
          rescue => e
            puts "Tilt Exception processing #{layout.name}#{layout.ext}: #{e.message} in #{self.data["layout"]}"
          end
        end


        if layout = layouts[layout.data["layout"]]
          if used.include?(layout)
            layout = nil # avoid recursive chain
          else
            used << layout
          end
        end
      end
    end
  end
end
