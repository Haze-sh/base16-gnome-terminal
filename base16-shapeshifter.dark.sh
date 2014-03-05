#!/usr/bin/env bash
# Base16 shapeshifter - Gnome Terminal color scheme install script
# Tyler Benziger (http://tybenz.com)

[[ -z "$PROFILE_NAME" ]] && PROFILE_NAME="Base 16 shapeshifter Dark"
[[ -z "$PROFILE_SLUG" ]] && PROFILE_SLUG="base-16-shapeshifter-dark"
[[ -z "$DCONF" ]] && DCONF=dconf
[[ -z "$UUIDGEN" ]] && UUIDGEN=uuidgen

dset() {
  local key="$1"; shift
  local val="$1"; shift

  if [[ "$type" == "string" ]]; then
	  val="'$val'"
  fi

  "$DCONF" write "$PROFILE_KEY/$key" "$val"
}

# because dconf still doesn't have "append"
dlist_append() {
  local key="$1"; shift
  local val="$1"; shift

  local entries="$(
    {
      "$DCONF" read "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
      echo "'$val'"
    } | head -c-1 | tr "\n" ,
  )"

  "$DCONF" write "$key" "[$entries]"
}

# Newest versions of gnome-terminal use dconf
if which "$DCONF" > /dev/null 2>&1; then
	[[ -z "$BASE_KEY" ]] && BASE_KEY=/org/gnome/terminal/legacy/profiles:

	if [[ -n "`$DCONF list $BASE_KEY/`" ]]; then
		if which "$UUIDGEN" > /dev/null 2>&1; then
			PROFILE_SLUG=`uuidgen`
		fi

    if [[ -n "`$DCONF read $BASE_KEY/default`" ]]; then
      DEFAULT_SLUG=`$DCONF read $BASE_KEY/default | tr -d \'`
    else
      DEFAULT_SLUG=`$DCONF list $BASE_KEY/ | grep '^:' | head -n1 | tr -d :/`
    fi

		DEFAULT_KEY="$BASE_KEY/:$DEFAULT_SLUG"
		PROFILE_KEY="$BASE_KEY/:$PROFILE_SLUG"

		# copy existing settings from default profile
		$DCONF dump "$DEFAULT_KEY/" | $DCONF load "$PROFILE_KEY/"

		# add new copy to list of profiles
    dlist_append $BASE_KEY/list "$PROFILE_SLUG"

		# update profile values with theme options
		dset visible-name "'$PROFILE_NAME'"
        dset palette "['#000000', '#e92f2f', '#0ed839', '#dddd13', '#3b48e3', '#f996e2', '#23edda', '#ababab', '#343434', '#e92f2f', '#0ed839', '#dddd13', '#3b48e3', '#f996e2', '#23edda', '#f9f9f9']"
		dset background-color "'#000000'"
		dset foreground-color "'#ababab'"
		dset bold-color "'#ababab'"
		dset bold-color-same-as-fg "true"
		dset use-theme-colors "false"
		dset use-theme-background "false"

		exit 0
	fi
fi

# Fallback for Gnome 2 and early Gnome 3
[[ -z "$GCONFTOOL" ]] && GCONFTOOL=gconftool
[[ -z "$BASE_KEY" ]] && BASE_KEY=/apps/gnome-terminal/profiles

PROFILE_KEY="$BASE_KEY/$PROFILE_SLUG"

gset() {
  local type="$1"; shift
  local key="$1"; shift
  local val="$1"; shift

  "$GCONFTOOL" --set --type "$type" "$PROFILE_KEY/$key" -- "$val"
}

# Because gconftool doesn't have "append"
glist_append() {
  local type="$1"; shift
  local key="$1"; shift
  local val="$1"; shift

  local entries="$(
    {
      "$GCONFTOOL" --get "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
      echo "$val"
    } | head -c-1 | tr "\n" ,
  )"

  "$GCONFTOOL" --set --type list --list-type $type "$key" "[$entries]"
}

# Append the Base16 profile to the profile list
glist_append string /apps/gnome-terminal/global/profile_list "$PROFILE_SLUG"

gset string visible_name "$PROFILE_NAME"
gset string palette "#000000:#e92f2f:#0ed839:#dddd13:#3b48e3:#f996e2:#23edda:#ababab:#343434:#e92f2f:#0ed839:#dddd13:#3b48e3:#f996e2:#23edda:#f9f9f9"
gset string background_color "#000000"
gset string foreground_color "#ababab"
gset string bold_color "#ababab"
gset bool   bold_color_same_as_fg "true"
gset bool   use_theme_colors "false"
gset bool   use_theme_background "false"