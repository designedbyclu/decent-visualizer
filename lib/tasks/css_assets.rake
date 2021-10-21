# frozen_string_literal: true

require "slim/erb_converter"

def convert_slim_to_erb
  Rails.logger.info "Converting slim to erb…"
  FileUtils.rm_f("tmp/compiled.html.erb")
  File.open(Rails.root.join("tmp/compiled.html.erb"), "w+") do |compiled|
    Dir.glob(Rails.root.join("app/views/**/*.slim")).each do |slim_template|
      File.open(slim_template) do |f|
        slim_code = f.read
        erb_code = Slim::ERBConverter.new.call(slim_code)
        compiled.puts(erb_code)
      end
    end
  end
end

namespace :css_assets do
  task build: :environment do
    convert_slim_to_erb
    path = "app/assets/stylesheets/tailwind-build.css"
    File.delete(path) if File.exist?(path)
    puts "Postcss building…"
    system("yarn build")
    path = "app/assets/stylesheets/tailwind-build-dev.css"
    File.delete(path) if File.exist?(path)
    puts "Postcss building dev…"
    system("yarn build_dev")
  end
end
