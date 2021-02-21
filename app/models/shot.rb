# frozen_string_literal: true

class Shot < ApplicationRecord
  extend Memoist

  SKINS = ["Classic", "DSx", "White DSx"].freeze
  DATA_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_resistance espresso_resistance_weight espresso_state_change].freeze
  DATA_LABELS_TO_IGNORE = %w[espresso_resistance espresso_resistance_weight espresso_state_change].freeze
  EXTRA_DATA_METHODS = %w[drink_weight grinder_model grinder_setting bean_brand bean_type roast_level roast_date drink_tds drink_ey espresso_enjoyment espresso_notes bean_notes].freeze
  EXTRA_DATA_CAPTURE = (EXTRA_DATA_METHODS + %w[bean_weight DSx_bean_weight grinder_dose_weight]).freeze
  MAX_RESISTANCE_VALUE = 16

  belongs_to :user, optional: true

  scope :visible, -> { joins(:user).where(users: {public: true}) }

  after_create :schedule_screenshot

  after_destroy_commit -> { broadcast_remove_to user }

  validates :start_time, :data, :sha, presence: true

  def self.from_file(user, file)
    return if file.blank?

    parsed_shot = ShotParser.new(File.read(file))
    shot = find_or_initialize_by(user: user, sha: parsed_shot.sha)
    shot.profile_title = parsed_shot.profile_title
    shot.start_time = parsed_shot.start_time
    shot.timeframe = parsed_shot.timeframe
    shot.data = parsed_shot.data
    shot.extra = parsed_shot.extra
    shot.extract_fields_from_extra
    shot
  end

  def extract_fields_from_extra
    EXTRA_DATA_METHODS.each do |attr|
      public_send("#{attr}=", extra[attr].presence)
    end
    self.bean_weight = extra["DSx_bean_weight"].presence || extra["grinder_dose_weight"].presence || extra["bean_weight"].presence
  end

  memoize def extra
    super.presence || {}
  end

  memoize def duration
    index = [data["espresso_flow"].size, timeframe.size].min
    timeframe[index - 1].to_f
  end

  memoize def chart_data
    chart_from_data + [resistance_chart]
  end

  memoize def stages
    indices = []
    if data.key?("espresso_state_change")
      current = data["espresso_state_change"].find { |s| !s.to_i.zero? }
      data["espresso_state_change"].each.with_index do |s, i|
        next if s.to_i.zero? || s == current

        indices << i
        current = s
      end
      selected = indices
    else
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

      if indices.any?
        indices = indices.sort.uniq
        selected = [indices.first]
        indices.each do |index|
          selected << index if (index - selected.last) > 5
        end
      end
    end

    chart_data.first[:data].values_at(*selected).pluck(:t)
  end

  private

  def schedule_screenshot
    ScreenshotTakerJob.perform_later(self)
  end

  memoize def chart_from_data
    timeframe_count = timeframe.count
    timeframe_last = timeframe.last.to_f
    timeframe_diff = (timeframe_last + timeframe.first.to_f) / timeframe.count.to_f
    data.map do |label, data|
      next if DATA_LABELS_TO_IGNORE.include?(label)

      data = data.map.with_index do |v, i|
        t = i < timeframe_count ? timeframe[i] : timeframe_last + ((i - timeframe_count + 1) * timeframe_diff)

        {t: t.to_f * 1000, y: (v.to_f.negative? ? nil : v)}
      end
      {label: label, data: data}
    end.compact
  end

  memoize def resistance_chart
    pressure_data = chart_from_data.find { |d| d[:label] == "espresso_pressure" }[:data]
    flow_data = chart_from_data.find { |d| d[:label] == "espresso_flow" }[:data]
    data = pressure_data.map.with_index do |v, i|
      f = flow_data[i][:y].to_f
      if f.zero?
        {t: v[:t], y: nil}
      else
        r = v[:y].to_f / f
        {t: v[:t], y: (r > MAX_RESISTANCE_VALUE ? nil : r)}
      end
    end

    {label: "espresso_resistance", data: data}
  end
end

# == Schema Information
#
# Table name: shots
#
#  id                 :uuid             not null, primary key
#  bean_brand         :string
#  bean_notes         :text
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
#  roast_level        :string
#  sha                :string
#  start_time         :datetime
#  timeframe          :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  cloudinary_id      :string
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
