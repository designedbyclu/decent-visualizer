require "csv"

module ShotInformation::Profile
  JSON_PROFILE_KEYS = %w[title author notes beverage_type steps tank_temperature target_weight target_volume target_volume_count_start legacy_profile_type type lang hidden reference_file changes_since_last_espresso version].freeze
  CSV_PROFILE_HEADERS = %w[information_type elapsed pressure current_total_shot_weight flow_in flow_out water_temperature_boiler water_temperature_in water_temperature_basket metatype metadata comment].freeze

  def tcl_profile_fields
    @tcl_profile_fields ||= profile_fields.except("json")
  end

  def json_profile_fields
    @json_profile_fields ||= profile_fields["json"]
  end

  def tcl_profile
    return if tcl_profile_fields.blank?

    tcl_profile_fields.to_a.sort_by(&:first).map do |k, v|
      v = "Visualizer/#{v}" if k == "profile_title"
      v = "#{v.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if k == "profile_notes"
      v = "{}" if v.blank?
      v = "{#{v}}" if /\w\s\w/.match?(v)

      "#{k} #{v}"
    end.join("\n")
  end

  def json_profile
    return if json_profile_fields.blank?

    json = {}
    JSON_PROFILE_KEYS.each do |key|
      v = profile_fields["json"][key]
      v = "Visualizer/#{v}" if key == "title"
      v = "#{v.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if key == "notes"
      json[key] = v
    end

    JSON.pretty_generate(json)
  end

  def csv_profile
    CSV.generate do |csv|
      csv << CSV_PROFILE_HEADERS

      csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Name", shot.profile_title, "text"]
      csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Date", shot.start_time.iso8601, "ISO8601 formatted date"]
      csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Roasting Date", Date.parse(shot.roast_date)&.iso8601, "ISO8601 formatted date"] if shot.roast_date.present?

      Parsers::SepCsv::MAPPING.each do |key, value|
        metadata_value = extra[value]
        next if metadata_value.blank?

        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, key, metadata_value, "text"]
      end

      csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Attribution", "Visualizer", nil]
      csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Software", "Visualizer", nil]
      csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Url", "https://visualizer.coffee/shots/#{shot.id}", nil]
      csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Export version", "1.0.0", nil]

      timeframe.each.with_index do |time, i|
        csv << ["moment", time, data.dig("espresso_pressure", i), data.dig("espresso_weight", i), data.dig("espresso_flow", i), data.dig("espresso_flow_weight", i), nil, data.dig("espresso_temperature_mix", i), data.dig("espresso_temperature_basket", i), nil, nil, "Visualizer"]
      end
    end
  end
end
