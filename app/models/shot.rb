# frozen_string_literal: true

class Shot < ApplicationRecord
  belongs_to :user, optional: true

  DATA_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_resistance].freeze
  EXTRA_DATA = %w[bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_level roast_date drink_tds drink_ey espresso_enjoyment espresso_notes].freeze

  def self.from_file(user, file: nil, content: nil)
    if file.present?
      file_content = File.read(file)
    elsif content.present?
      file_content = content
    else
      return
    end

    parsed_shot = ShotParser.new(file_content)
    find_or_create_by(user: user, sha: parsed_shot.sha) do |shot|
      shot.profile_title = parsed_shot.profile_title
      shot.start_time = parsed_shot.start_time
      shot.timeframe = parsed_shot.timeframe
      shot.data = parsed_shot.data
      shot.extra = parsed_shot.extra
    end
  end

  def screenshot_path
    @screenshot_path ||= Rails.root.join("public/screenshots/#{id}.png")
  end

  def extra
    @extra ||= super.presence || {}
  end

  (EXTRA_DATA - ["bean_weight"]).each do |data|
    define_method data do
      attributes[data].presence || extra[data]
    end
  end

  def bean_weight
    attributes["bean_weight"].presence || extra["DSx_bean_weight"].presence || extra["grinder_dose_weight"].presence || extra["bean_weight"].presence
  end

  def chart_data
    chart_from_data + calculated_chart_data
  end

  def stages
    indices = []
    data.select { |label, _| label.end_with?("_goal") }.each do |_label, data|
      data = data.map(&:to_f)
      data.each.with_index do |a, i|
        next if i < 5

        b = data[i - 1]
        c = data[i - 2]
        diff2 = ((a - b) - (b - c))
        indices << i if diff2.abs > 0.1
      end
    end

    return [] if indices.empty?

    indices = indices.sort.uniq
    selected = [indices.first]
    indices.each do |index|
      selected << index if (index - selected.last) > 5
    end

    chart_from_data.first[:data].values_at(*selected).pluck(:t)
  end

  private

  def chart_from_data
    timeframe_count = timeframe.count
    timeframe_last = timeframe.last.to_f
    timeframe_diff = (timeframe_last + timeframe.first.to_f) / timeframe.count.to_f
    @chart_from_data ||= data.map do |label, data|
      data = data.map.with_index do |v, i|
        t = i < timeframe_count ? timeframe[i] : timeframe_last + ((i - timeframe_count + 1) * timeframe_diff)

        {t: t.to_f * 1000, y: (v.to_f.negative? ? nil : v)}
      end
      {label: label, data: data}
    end.compact
  end

  def calculated_chart_data
    @calculated_chart_data ||= [resistance_chart]
  end

  def resistance_chart
    data = pressure_data.map.with_index do |v, i|
      f = flow_data[i][:y].to_f
      if f.zero?
        {t: v[:t], y: nil}
      else
        r = v[:y].to_f / f
        {t: v[:t], y: (r > 16 ? nil : r)}
      end
    end

    {label: "espresso_resistance", data: data}
  end

  def pressure_data
    @pressure_data ||= chart_from_data.find { |d| d[:label] == "espresso_pressure" }[:data]
  end

  def flow_data
    @flow_data ||= chart_from_data.find { |d| d[:label] == "espresso_flow" }[:data]
  end
end

# == Schema Information
#
# Table name: shots
#
#  id                 :uuid             not null, primary key
#  bean_brand         :string
#  bean_type          :string
#  bean_weight        :string
#  data               :jsonb
#  drink_ey           :string
#  drink_tds          :string
#  drink_weight       :string
#  espresso_enjoyment :string
#  espresso_notes     :text
#  extra              :jsonb
#  grinder_model      :string
#  grinder_setting    :string
#  profile_title      :string
#  roast_date         :string
#  sha                :string
#  start_time         :datetime
#  timeframe          :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :uuid
#
# Indexes
#
#  index_shots_on_sha      (sha)
#  index_shots_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
