show_window_current_format() {
  local number="#I"
  local color=$(get_tmux_option "@catppuccin_window_current_color" "$thm_orange")
  local background=$(get_tmux_option "@catppuccin_window_current_background" "$thm_bg")
  local text="$(get_tmux_option "@catppuccin_window_current_text" "#{b:pane_current_path}")" # use #W for application instead of directory
  local fill="$(get_tmux_option "@catppuccin_window_current_fill" "number")"                 # number, all, none
  local invert_middle_separator=$(get_tmux_option "@ostentus_window_current_invert_middle_separator" "yes")

  local current_window_format=$(build_window_format "$number" "$color" "$background" "$text" "$fill" "$invert_middle_separator")

  echo "$current_window_format"
}
