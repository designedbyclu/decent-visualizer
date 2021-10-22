advanced_shot {{exit_if 1 flow 8.0 volume 100 max_flow_or_pressure_range 0.6 transition fast exit_flow_under 0 temperature 88.5 name preinfusion pressure 1 sensor coffee pump flow exit_type pressure_over exit_flow_over 6 max_flow_or_pressure 0 exit_pressure_over 4.00 seconds 20.00 exit_pressure_under 0} {exit_if 1 flow 0 volume 100 max_flow_or_pressure_range 0.6 transition fast exit_flow_under 0 temperature 68.5 name {dynamic bloom} pressure 6.0 sensor coffee pump flow exit_type pressure_under exit_flow_over 6 max_flow_or_pressure 0 exit_pressure_over 11 seconds 40.00 exit_pressure_under 2.20} {exit_if 0 flow 2.2 volume 100 max_flow_or_pressure_range 1.2 transition smooth exit_flow_under 0 temperature 78.5 name ramp pressure 7.0 sensor coffee pump pressure exit_type pressure_under exit_flow_over 6 max_flow_or_pressure 0.0 exit_pressure_over 11 seconds 4.00 exit_pressure_under 0} {exit_if 0 flow 2.2 volume 100 max_flow_or_pressure_range 1.2 transition fast exit_flow_under 0 temperature 74.5 name {flat flow} pressure 7.0 sensor coffee pump pressure exit_type pressure_under exit_flow_over 6 max_flow_or_pressure 4.5 exit_pressure_over 11 seconds 2.00 exit_pressure_under 0} {exit_if 0 flow 3.200000000000001 volume 100 max_flow_or_pressure_range 1.2 transition smooth exit_flow_under 0 temperature 70.5 name decline pressure 4.00 sensor coffee pump pressure exit_type pressure_under exit_flow_over 6 max_flow_or_pressure 4.2 exit_pressure_over 11 seconds 40.00 exit_pressure_under 0}}
author Stéphane
beverage_type espresso
espresso_decline_time 30
espresso_hold_time 15
espresso_pressure 6.0
espresso_temperature 88.0
espresso_temperature_0 88.0
espresso_temperature_1 88.0
espresso_temperature_2 88.0
espresso_temperature_3 88.0
espresso_temperature_steps_enabled 0
final_desired_shot_volume 0
final_desired_shot_volume_advanced 0
final_desired_shot_volume_advanced_count_start 2
final_desired_shot_weight 0
final_desired_shot_weight_advanced 36.0
flow_profile_decline 1.2
flow_profile_decline_time 17
flow_profile_hold 2
flow_profile_hold_time 8
flow_profile_minimum_pressure 4
flow_profile_preinfusion 4
flow_profile_preinfusion_time 5
maximum_flow 0
maximum_flow_range 0.6
maximum_flow_range_advanced 1.2
maximum_flow_range_default 1.0
maximum_pressure 0
maximum_pressure_range 0.6
maximum_pressure_range_advanced 0.6
maximum_pressure_range_default 0.9
original_profile_title TurboBloom
preinfusion_flow_rate 4
preinfusion_guarantee 0
preinfusion_stop_pressure 4.0
preinfusion_time 20
pressure_end 4.0
profile_filename TurboBloom
profile_language en
profile_notes {...

Downloaded from Visualizer}
profile_title {TurboBloom from Visualizer}
profile_to_save TurboBloom
settings_profile_type settings_2c
tank_desired_water_temperature 0