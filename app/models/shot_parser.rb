# frozen_string_literal: true

class ShotParser
  EXTRA_DATA_CAPTURE = (Shot::EXTRA_DATA_METHODS + %w[bean_weight DSx_bean_weight grinder_dose_weight]).freeze
  JSON_MAPPING = {
    "_weight" => "by_weight",
    "_weight_raw" => "by_weight_raw",
    "_goal" => "goal"
  }.freeze

  attr_reader :start_time, :data, :extra, :timeframe, :profile_title, :sha

  def initialize(file)
    @file = file
    @data = {}
    @extra = {}
    @start_chars_to_ignore = %i[c b]
    parse_file

    @sha = Digest::SHA256.base64digest(data.sort.to_json) if data.present?
  end

  private

  def parse_file
    json_parse || tcl_parse
  rescue SystemStackError, StandardError => e
    Rollbar.error(e, file: @file)
  end

  def json_parse
    parsed = JSON.parse(@file)

    extract_clock(parsed["timestamp"])
    extract_espresso_elapsed(parsed["elapsed"])
    @profile_title = parsed["profile"]["title"]

    %w[pressure flow resistance].each do |key|
      @data["espresso_#{key}"] = parsed.dig(key, key)

      JSON_MAPPING.each do |suffix, subkey|
        value = parsed.dig(key, subkey)
        next if value.blank?

        @data["espresso_#{key}#{suffix}"] = value
      end
    end

    %w[basket mix goal].each do |key|
      @data["espresso_temperature_#{key}"] = parsed.dig("temperature", key)
    end

    %w[weight water_dispensed].each do |key|
      @data["espresso_#{key}"] = parsed.dig("totals", key)
    end

    @data["espresso_state_change"] = parsed["state_change"]

    settings = parsed.dig("app", "data", "settings")
    EXTRA_DATA_CAPTURE.each do |key|
      @extra[key] = settings[key]
    end
  rescue JSON::ParserError, TypeError
    false
  end

  def tcl_parse
    parsed = Tickly::Parser.new.parse(@file)
    parsed.each do |name, data|
      extract_data_from(name, data)
      next unless name == "settings"

      data.each do |setting_name, setting_data|
        next if @start_chars_to_ignore.include?(setting_name)

        extract_data_from("setting_#{setting_name.strip}", setting_data)
      end
    end
  end

  def extract_data_from(name, data)
    return if data.blank?

    method = "extract_#{name}"
    data = @start_chars_to_ignore.include?(data.first) ? data[1..] : data
    __send__(method, data) if respond_to?(method, true)
  end

  def extract_clock(data)
    @start_time = Time.at(data.to_i).utc
  end

  def extract_espresso_elapsed(data)
    @timeframe = data
  end

  def extract_setting_profile_title(data)
    @profile_title = handle_array_string(data).force_encoding("UTF-8")
  end

  Shot::DATA_LABELS.each do |name|
    define_method("extract_#{name}") do |data|
      @data[name] = data
    end
  end

  EXTRA_DATA_CAPTURE.each do |name|
    define_method("extract_setting_#{name}") do |data|
      @extra[name] = handle_array_string(data).force_encoding("UTF-8")
    end
  end

  def handle_array_string(data)
    return data unless data.is_a?(Array)

    if data.all?(Array)
      data.map { |line| line.join(" ") }.join("\n")
    else
      data.join(" ")
    end
  end
end
