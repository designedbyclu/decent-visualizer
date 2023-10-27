# frozen_string_literal: true

module Parsers
  class Beanconqueror < Base
    DATA_LABELS_MAP = {"weight" => "espresso_weight", "waterFlow" => "espresso_flow", "realtimeFlow" => "espresso_flow_weight", "pressureFlow" => "espresso_pressure", "temperatureFlow" => "espresso_temperature_mix"}.freeze
    DATA_VALUES_MAP = {"weight" => "actual_weight", "waterFlow" => "value", "realtimeFlow" => "flow_value", "pressureFlow" => "actual_pressure", "temperatureFlow" => "actual_temperature"}.freeze

    def parse
      @start_time = Time.at(file.dig("brew", "config", "unix_timestamp").to_i).utc
      @profile_title = file.dig("preparation", "name").presence || "Beanconqueror"
      extract_bean(file["bean"])
      extract_mill(file["mill"])
      extract_brew(file["brew"])
      extract_preparation(file["preparation"])
      extract_water(file["water"])
      extract_data(file["brewFlow"])
    end

    private

    def extract_bean(bean)
      @extra["bean_brand"] = bean.delete("roaster")
      @extra["bean_type"] = bean.delete("name")
      @extra["roast_level"] = bean.delete("roast")
      @extra["roast_date"] = bean.delete("roastingDate")
      @extra["bean_notes"] = "```javascript\n#{JSON.pretty_generate(bean)}\n```"
    end

    def extract_brew(brew)
      @extra["grinder_setting"] = brew.delete("grind_size")
      @extra["drink_weight"] = brew.delete("brew_beverage_quantity")
      @extra["bean_weight"] = brew.delete("grind_weight")
      @extra["espresso_notes"] = "#### Brew:\n\n#{brew.delete("note")}\n\n```javascript\n#{JSON.pretty_generate(brew.except("config"))}\n```\n\n"
    end

    def extract_mill(mill)
      @extra["grinder_model"] = mill.delete("name")
    end

    def extract_preparation(preparation)
      @extra["espresso_notes"] += "#### Preparation:\n\n```javascript\n#{JSON.pretty_generate(preparation)}\n```\n\n"
    end

    def extract_water(water)
      @extra["espresso_notes"] += "#### Water:\n\n```javascript\n#{JSON.pretty_generate(water)}\n```\n\n"
    end

    def extract_data(brew_flow)
      @timeframe = []
      relevant_keys = brew_flow.keys.select { |k| brew_flow[k].size > 1 }
      @data = DATA_LABELS_MAP.values_at(*relevant_keys).index_with { |label| [] }
      brew_flow.each do |label, data|
        data.each do |d|
          d["unix_timestamp"] = Time.strptime(d["timestamp"], "%H:%M:%S.%L").to_f
        end
      end
      longest = brew_flow.keys.max_by { |l| brew_flow[l].size }
      start = brew_flow[longest].first["unix_timestamp"].to_f
      brew_flow[longest].each do |d|
        @timeframe << (d["unix_timestamp"] - start).round(4).to_s
        relevant_keys.each do |key|
          closest = closest_bsearch(brew_flow[key], d["unix_timestamp"], key: "unix_timestamp")
          value = closest[DATA_VALUES_MAP[key]]
          @data[DATA_LABELS_MAP[key]] << (value&.positive? ? value : 0)
        end
      end
    end
  end
end
