#!/usr/bin/env bash
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_option() {
  local option="$1"
  local default="$2"
  local value

  value=$(tmux show-option -gqv "$option" 2>/dev/null)

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "$default"
  else
    echo "$value"
  fi
}

set() {
  local option=$1
  local value=$2
  tmux_commands+=(set-option -gq "$option" "$value" ";")
}

setw() {
  local option=$1
  local value=$2
  tmux_commands+=(set-window-option -gq "$option" "$value" ";")
}

build_window_icon() {
  local window_status_icon_enable=$(get_tmux_option "@catppuccin_window_status_icon_enable" "yes")

  local show_window_status="#F"

  if [ "$window_status_icon_enable" = "no" ]; then
    echo "$show_window_status"
    return
  fi

  local custom_icon_window_last=$(get_tmux_option "@catppuccin_icon_window_last" "󰖰")
  local custom_icon_window_current=$(get_tmux_option "@catppuccin_icon_window_current" "󰖯")
  local custom_icon_window_zoom=$(get_tmux_option "@catppuccin_icon_window_zoom" "󰁌")
  local custom_icon_window_mark=$(get_tmux_option "@catppuccin_icon_window_mark" "󰃀")
  local custom_icon_window_silent=$(get_tmux_option "@catppuccin_icon_window_silent" "󰂛")
  local custom_icon_window_activity=$(get_tmux_option "@catppuccin_icon_window_activity" "󰖲")
  local custom_icon_window_bell=$(get_tmux_option "@catppuccin_icon_window_bell" "󰂞")

  show_window_status="#{?window_activity_flag,${custom_icon_window_activity},}#{?window_bell_flag,${custom_icon_window_bell},}#{?window_silence_flag,${custom_icon_window_silent},}#{?window_active,${custom_icon_window_current},}#{?window_last_flag,${custom_icon_window_last},}#{?window_marked_flag,${custom_icon_window_mark},}#{?window_zoomed_flag,${custom_icon_window_zoom},}"

  echo "$show_window_status"
}

build_pane_format() {
  local number=$1
  local color=$2
  local background=$3
  local text=$4
  local fill=$5

  if [ "$pane_status_enable" != "yes" ]; then
    return
  fi

  local show_left_separator show_number show_middle_separator show_text show_right_separator final_pane_format

  local default_fg="$thm_fg"
  local default_bg="$thm_gray"
  local separator_style="nobold,nounderscore,noitalics"

  case "$fill" in
  "none")
    show_left_separator="#[fg=$thm_gray,bg=$thm_bg,$separator_style]$pane_left_separator"
    show_number="#[fg=$default_fg,bg=$default_bg]$number"
    show_middle_separator="#[fg=$default_fg,bg=$default_bg,$separator_style]$pane_middle_separator"
    show_text="#[fg=$default_fg,bg=$default_bg]$text"
    show_right_separator="#[fg=$thm_gray,bg=$thm_bg]$pane_right_separator"
    ;;
  "all")
    show_left_separator="#[fg=$color,bg=$thm_bg,$separator_style]$pane_left_separator"
    show_number="#[fg=$background,bg=$color]$number"
    show_middle_separator="#[fg=$background,bg=$color,$separator_style]$pane_middle_separator"
    show_text="#[fg=$background,bg=$color]$text"
    show_right_separator="#[fg=$color,bg=$thm_bg]$pane_right_separator"
    ;;
  "number")
    show_number="#[fg=$background,bg=$color]$number"
    show_middle_separator="#[fg=$color,bg=$background,$separator_style]$pane_middle_separator"
    show_text="#[fg=$default_fg,bg=$background]$text"

    if [ "$pane_number_position" = "right" ]; then
      show_left_separator="#[fg=$background,bg=$thm_bg,$separator_style]$pane_left_separator"
      show_right_separator="#[fg=$color,bg=$thm_bg]$pane_right_separator"
    else
      show_left_separator="#[fg=$color,bg=$thm_bg]$pane_left_separator"
      show_right_separator="#[fg=$background,bg=$thm_bg,$separator_style]$pane_right_separator"
    fi
    ;;
  esac

  if [ "$pane_number_position" = "right" ]; then
    final_pane_format="$show_left_separator$show_text$show_middle_separator$show_number$show_right_separator"
  else
    final_pane_format="$show_left_separator$show_number$show_middle_separator$show_text$show_right_separator"
  fi

  echo "$final_pane_format"
}

build_window_format() {
  local number=$1
  local color=$2
  local background=$3
  local text=$4
  local fill=$5

  if [ "$window_status_enable" = "yes" ]; then
    local icon="$(build_window_icon)"
    text="$text $icon"
  fi

  local default_fg="$thm_fg"
  local default_bg="$thm_gray"
  local default_statusbar="default"
  local separator_style="nobold,nounderscore,noitalics"

  if [ "$fill" = "none" ]; then
    local show_left_separator="#[fg=$thm_gray,bg=$default_statusbar,$separator_style]$window_left_separator"
    local show_number="#[fg=$default_fg,bg=$default_bg]$number"
    local show_middle_separator="#[fg=$default_fg,bg=$default_bg,$separator_style]$window_middle_separator"
    local show_text="#[fg=$default_fg,bg=$default_bg]$text"
    local show_right_separator="#[fg=$thm_gray,bg=$default_statusbar]$window_right_separator"
  fi

  if [ "$fill" = "all" ]; then
    local show_left_separator="#[fg=$color,bg=$default_statusbar,$separator_style]$window_left_separator"
    local show_number="#[fg=$background,bg=$color]$number"
    local show_middle_separator="#[fg=$background,bg=$color,$separator_style]$window_middle_separator"
    local show_text="#[fg=$background,bg=$color]$text"
    local show_right_separator="#[fg=$color,bg=$default_statusbar]$window_right_separator"
  fi

  if [ "$fill" = "number" ]; then
    local show_number="#[fg=$background,bg=$color]$number"
    local show_middle_separator="#[fg=$color,bg=$background,$separator_style]$window_middle_separator"
    local show_text="#[fg=$default_fg,bg=$background]$text"

    if [ "$window_number_position" = "right" ]; then
      local show_left_separator="#[fg=$background,bg=$default_statusbar,$separator_style]$window_left_separator"
      local show_right_separator="#[fg=$color,bg=$default_statusbar]$window_right_separator"
    fi

    if [ "$window_number_position" = "left" ]; then
      local show_right_separator="#[fg=$background,bg=$default_statusbar,$separator_style]$window_right_separator"
      local show_left_separator="#[fg=$color,bg=$default_statusbar]$window_left_separator"
    fi
  fi

  local final_window_format

  if [ "$window_number_position" = "right" ]; then
    final_window_format="$show_left_separator$show_text$show_middle_separator$show_number$show_right_separator"
  fi

  if [ "$window_number_position" = "left" ]; then
    final_window_format="$show_left_separator$show_number$show_middle_separator$show_text$show_right_separator"
  fi

  echo "$final_window_format"
}

build_status_module() {
  local index=$1
  local icon=$2
  local color=$3
  local text=$4
  local bg_color=$thm_gray     # Default background color
  local sep_bg_color=$bg_color # Separator background color, may change based on conditions
  local status_bg_color=$(get_tmux_option "@ostentus_theme_status_background" ${thm_bg})

  # Default formatting options
  local nobold="nobold"
  local nounderscore="nounderscore"
  local noitalics="noitalics"

  # Initial left and right separator settings
  local show_left_separator="#[fg=$color,bg=$status_bg_color,$nobold,$nounderscore,$noitalics]$status_left_separator"
  local show_right_separator="#[fg=$thm_gray,bg=$status_bg_color,$nobold,$nounderscore,$noitalics]$status_right_separator"

  # Configure module based on status_fill
  case "$status_fill" in
  "icon")
    show_icon="#[fg=$thm_gray,bg=$color,$nobold,$nounderscore,$noitalics]$icon "
    show_text="#[fg=$thm_fg,bg=$bg_color] $text"
    ;;
  "all")
    bg_color="$color"
    show_icon="#[fg=$thm_gray,bg=$bg_color,$nobold,$nounderscore,$noitalics]$icon "
    show_text="#[fg=$thm_gray,bg=$bg_color]$text"
    ;;
  esac

  # Adjust separators for connected separators
  if [ "$status_connect_separator" = "yes" ]; then
    sep_bg_color="$color"
    show_left_separator="#[fg=$color,bg=$bg_color,$nobold,$nounderscore,$noitalics]$status_left_separator"
    show_right_separator="#[fg=$bg_color,bg=$sep_bg_color,$nobold,$nounderscore,$noitalics]$status_right_separator"
  fi

  # Inverse right separator color when specified
  [ "$status_right_separator_inverse" = "yes" ] && show_right_separator="#[fg=$thm_gray,bg=$color,$nobold,$nounderscore,$noitalics]$status_right_separator"

  # Special case for the first module
  [ "$index" -eq 0 ] && show_left_separator="#[fg=$color,bg=$status_bg_color,$nobold,$nounderscore,$noitalics]$status_left_separator"

  # Output the constructed status module
  echo "$show_left_separator$show_icon$show_text$show_right_separator"
}

load_modules() {
  local modules_list=$1
  shift
  local module_directories=("$@")

  local module_index=0
  local loaded_modules=""
  local IN=$modules_list

  local iter module_name module_path

  local add_space_between=$(get_tmux_option "@catppuccin_add_space_between" "yes")
  local space=""

  if [ "$add_space_between" = "yes" ]; then
    space=" "
  fi

  # https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash#15988793
  while [ "$IN" != "$iter" ]; do
    iter=${IN%% *}    # extract the substring from start of string up to delimiter.
    IN="${IN#$iter }" # delete this first "element" AND next separator, from $IN.
    module_name=$iter # Print (or doing anything with) the first "element".

    module_path=$modules_custom_path/$module_name.sh
    if source $module_path 2>/dev/null; then
      loaded_modules="${loaded_modules}${space}$(show_$module_name $module_index)"
      ((module_index++))
      continue
    fi

    module_path=$modules_status_path/$module_name.sh
    if source $module_path 2>/dev/null; then
      loaded_modules="${loaded_modules}${space}$(show_$module_name $module_index)"
      ((module_index++))
      continue
    fi

    module_path=$modules_window_path/$module_name.sh
    if source $module_path 2>/dev/null; then
      loaded_modules="${loaded_modules}${space}$(show_$module_name $module_index)"
      ((module_index++))
    fi
  done

  if [ "$add_space_between" = "yes" ]; then
    loaded_modules=${loaded_modules#$space}
  fi

  echo "$loaded_modules"
}

main() {
  local thm_bg=$(get_tmux_option "@ostentus_theme_background" "#1e1e2e")
  local thm_fg=$(get_tmux_option "@ostentus_theme_foreground" "#cdd6f4")
  local thm_cyan=$(get_tmux_option "@ostentus_theme_cyan" "#89dceb")
  local thm_black=$(get_tmux_option "@ostentus_theme_black" "#181825")
  local thm_gray=$(get_tmux_option "@ostentus_theme_gray" "#313244")
  local thm_magenta=$(get_tmux_option "@ostentus_theme_magenta" "#cba6f7")
  local thm_pink=$(get_tmux_option "@ostentus_theme_pink" "#f5c2e7")
  local thm_red=$(get_tmux_option "@ostentus_theme_red" "#f38ba8")
  local thm_green=$(get_tmux_option "@ostentus_theme_green" "#a6e3a1")
  local thm_yellow=$(get_tmux_option "@ostentus_theme_yellow" "#f9e2af")
  local thm_blue=$(get_tmux_option "@ostentus_theme_blue" "#89b4fa")
  local thm_orange=$(get_tmux_option "@ostentus_theme_orange" "#fab387")
  local thm_black4=$(get_tmux_option "@ostentus_theme_black4" "#585b70")

  local status_bg_color="$(get_tmux_option "@ostentus_theme_status_background" $thm_bg)"

  # Aggregate all commands in one array
  local tmux_commands=()

  # module directories
  local custom_path="$(get_tmux_option "@catppuccin_custom_plugin_dir" "${PLUGIN_DIR}/custom")"
  local modules_custom_path=$custom_path
  local modules_status_path=$PLUGIN_DIR/status
  local modules_window_path=$PLUGIN_DIR/window
  local modules_pane_path=$PLUGIN_DIR/pane

  # status
  set status "on"
  set status-bg "${status_bg_color}"
  set status-justify "left"
  set status-left-length "100"
  set status-right-length "100"
  set status-left-style "fg=${status_bg_color},bg=${status_bg_color}"


  # messages
  set message-style "fg=${thm_cyan},bg=${status_bg_color},align=centre"
  set message-command-style "fg=${thm_cyan},bg=${status_bg_color},align=centre"

  # panes
  local pane_status_enable=$(get_tmux_option "@catppuccin_pane_status_enabled" "no") # yes
  local pane_border_status=$(get_tmux_option "@catppuccin_pane_border_status" "off") # bottom
  local pane_border_style=$(get_tmux_option "@catppuccin_pane_border_style" "fg=${thm_gray}")
  local pane_active_border_style=$(get_tmux_option "@catppuccin_pane_active_border_style" "fg=${thm_orange}")
  local pane_left_separator=$(get_tmux_option "@catppuccin_pane_left_separator" "█")
  local pane_middle_separator=$(get_tmux_option "@catppuccin_pane_middle_separator" "█")
  local pane_right_separator=$(get_tmux_option "@catppuccin_pane_right_separator" "█")
  local pane_number_position=$(get_tmux_option "@catppuccin_pane_number_position" "left") # right, left
  local pane_format=$(load_modules "pane_default_format" "$modules_custom_path" "$modules_pane_path")

  setw pane-border-status "$pane_border_status"
  setw pane-active-border-style "$pane_active_border_style"
  setw pane-border-style "$pane_border_style"
  setw pane-border-format "$pane_format"

  # windows
  setw window-status-activity-style "fg=${thm_fg},bg=${status_bg_color},none"
  setw window-status-separator ""
  setw window-status-style "fg=${thm_fg},bg=${status_bg_color},none"
  setw window-status-current-style fg=${status_bg_color},bg=${status_bg_color}
  # --------=== Statusline

  local window_left_separator=$(get_tmux_option "@catppuccin_window_left_separator" "█")
  local window_right_separator=$(get_tmux_option "@catppuccin_window_right_separator" "█")
  local window_middle_separator=$(get_tmux_option "@catppuccin_window_middle_separator" "█ ")
  local window_number_position=$(get_tmux_option "@catppuccin_window_number_position" "left") # right, left
  local window_status_enable=$(get_tmux_option "@catppuccin_window_status_enable" "no")       # right, left

  local window_format=$(load_modules "window_default_format" "$modules_custom_path" "$modules_window_path")
  local window_current_format=$(load_modules "window_current_format" "$modules_custom_path" "$modules_window_path")

  setw window-status-format "$window_format"
  setw window-status-current-format "$window_current_format"

  local status_left_separator=$(get_tmux_option "@catppuccin_status_left_separator" "")
  local status_right_separator=$(get_tmux_option "@catppuccin_status_right_separator" "█")
  local status_right_separator_inverse=$(get_tmux_option "@catppuccin_status_right_separator_inverse" "no")
  local status_connect_separator=$(get_tmux_option "@catppuccin_status_connect_separator" "yes")
  local status_fill=$(get_tmux_option "@catppuccin_status_fill" "icon")

  local status_modules_right=$(get_tmux_option "@catppuccin_status_modules_right" "application session")
  local loaded_modules_right=$(load_modules "$status_modules_right" "$modules_custom_path" "$modules_status_path")

  local status_modules_left=$(get_tmux_option "@catppuccin_status_modules_left" "")
  local loaded_modules_left=$(load_modules "$status_modules_left" "$modules_custom_path" "$modules_status_path")

  set status-left "$loaded_modules_left"
  set status-right "$loaded_modules_right"

  # --------=== Modes
  #
  setw clock-mode-colour "${thm_blue}"
  setw mode-style "fg=${thm_pink} bg=${thm_black4} bold"

  tmux "${tmux_commands[@]}"
}

main "$@"
