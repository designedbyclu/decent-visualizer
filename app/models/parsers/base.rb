# frozen_string_literal: true

module Parsers
  class Base
    prepend MemoWise

    PROFILE_FIELDS = %w[advanced_shot author beverage_type espresso_decline_time espresso_hold_time espresso_pressure espresso_temperature espresso_temperature_0 espresso_temperature_1 espresso_temperature_2 espresso_temperature_3 espresso_temperature_steps_enabled final_desired_shot_volume final_desired_shot_volume_advanced final_desired_shot_volume_advanced_count_start final_desired_shot_weight final_desired_shot_weight_advanced flow_profile_decline flow_profile_decline_time flow_profile_hold flow_profile_hold_time flow_profile_minimum_pressure flow_profile_preinfusion flow_profile_preinfusion_time maximum_flow maximum_flow_range maximum_flow_range_advanced maximum_flow_range_default maximum_pressure maximum_pressure_range maximum_pressure_range_advanced maximum_pressure_range_default original_profile_title preinfusion_flow_rate preinfusion_guarantee preinfusion_stop_pressure preinfusion_time pressure_end profile_filename profile_language profile_notes profile_title profile_to_save settings_profile_type tank_desired_water_temperature].freeze
    EXTRA_DATA_METHODS = %w[drink_weight grinder_model grinder_setting bean_brand bean_type roast_level roast_date drink_tds drink_ey espresso_enjoyment espresso_notes bean_notes].freeze
    EXTRA_DATA_CAPTURE = (EXTRA_DATA_METHODS + %w[bean_weight DSx_bean_weight grinder_dose_weight enable_fahrenheit my_name skin]).freeze

    attr_reader :file, :start_time, :data, :extra, :metadata, :timeframe, :profile_title, :profile_fields, :json

    def self.parser_for(file)
      if file.start_with?("{")
        json = parse_json(file)
        if json.key?("mill") || json.key?("brewFlow")
          Beanconqueror.new(json)
        else
          DecentJson.new(json)
        end
      elsif file.start_with?("clock", "sequence_id", "filename")
        DecentTcl.new(file)
      elsif file.start_with?("information_type")
        SepCsv.new(file)
      else
        new(file)
      end
    end

    def self.parse_json(file)
      Oj.load(file)
    end

    def initialize(file)
      @file = file
      @data = {}
      @extra = {}
      @profile_fields = {}
      @metadata = {}
    end

    def build_shot(user)
      parse
      sha = Digest::SHA256.base64digest(data.sort.to_json) if data.present?
      shot = Shot.find_or_initialize_by(user:, sha:)
      shot.profile_title = profile_title
      shot.start_time = start_time
      add_information(shot)

      if shot.valid?
        extract_fields_from_extra(shot)
        shot.duration = calculate_duration
      elsif file.start_with?("advanced_shot")
        shot.errors.add(:base, :profile_file, message: "This is a profile file, not a shot file")
      elsif Rails.env.production?
        s3_response = Aws::S3::Client.new.put_object(acl: "private", body: file, bucket: "visualizer-coffee", key: "debug/#{Time.zone.now.iso8601}.json")
        Rails.logger.warn("Something is wrong with this file #{s3_response.etag} | User ID: #{user.id}")
      end
      shot
    end

    def parse
      nil
    rescue SystemStackError, StandardError => e
      Rails.env.development? ? raise(e) : new(file)
    end

    private

    def add_information(shot)
      shot.information ||= shot.build_information
      shot.information.data = data
      shot.information.extra = extra
      shot.information.timeframe = timeframe
      shot.information.profile_fields = profile_fields
      shot.information.metadata = metadata
      shot.information.metadata["parser"] = self.class.name
    end

    def calculate_duration
      index = if data["espresso_flow"]
        [data["espresso_flow"].size, timeframe.size].min
      else
        timeframe.size
      end
      timeframe[index - 1].to_f
    end

    def closest_bsearch(array, timestamp, key: nil)
      index = array.bsearch_index { |x| (key ? x.dig(key) : x[0]) >= timestamp } || array.size
      [array[index], array[index - 1]].compact.min_by { |x| (timestamp - (key ? x.dig(key) : x[0])).abs }
    end

    def extract_fields_from_extra(shot)
      EXTRA_DATA_METHODS.each do |attr|
        shot.public_send(:"#{attr}=", extra[attr].presence)
      end
      shot.bean_weight = extra.slice("DSx_bean_weight", "grinder_dose_weight", "bean_weight").values.find { |v| v.to_i.positive? }
      shot.barista = extra["my_name"].presence
    end
  end
end
