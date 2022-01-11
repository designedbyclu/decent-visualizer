# frozen_string_literal: true

require "slim/erb_converter"

namespace :slim_to_erb do
  task convert: :environment do
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
end

Rake::Task["tailwindcss:build"].enhance(["slim_to_erb:convert"])
