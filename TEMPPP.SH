# Paste into a real terminal (not some cursed “rich text” box).
# 256-color ANSI: blue=27, yellow=226, grey=245, white=15

B=$'\e[38;5;27m'    # blue
Y=$'\e[38;5;226m'   # yellow
G=$'\e[38;5;245m'   # grey
W=$'\e[38;5;15m'    # white
R=$'\e[0m'          # reset

cat <<'EOF' | awk -v B="$B" -v Y="$Y" -v G="$G" -v W="$W" -v R="$R" '
{
  line=$0

  # Flower (top): make dots yellow, curves blue
  if (NR <= 6) {
    gsub(/[.]/, Y "&" R, line)
    gsub(/[()\-]/, B "&" R, line)
    print line
    next
  }

  # Stem/connector: grey
  if (NR >= 7 && NR <= 9) {
    gsub(/[\/\\|_]/, G "&" R, line)
    print line
    next
  }

  # Body: outline grey, face/details white
  gsub(/[\/\\_\-]/, G "&" R, line)   # shell lines
  gsub(/[()^]/, W "&" R, line)       # eyes + nose
  print line
}'
             .-(.-)-..
           (   .-.     )
             `-(   )-,
                `-'
               __|__
            _/       \_
          _/  _   _    \_
         /   ( ) ( )     \
         \      ^        /
          \_   ___     _/
            \_/   \____/
EOF
