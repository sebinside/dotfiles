#!/usr/bin/env bash
# Custom Claude Code status line.
# Format: dir:~/path · branch:foo · model:Opus 4.8 · effort:high · ctx:72% · 5h:32% (1h46m) · 7d:4%
# Segments with no data (e.g. effort or rate_limits) are omitted gracefully.

input=$(cat)

# Parse the 7 fields we need, one per line, order-sensitive (empty lines kept).
# Picks the best JSON parser available so the bar works on any box with NO install:
#   jq → node → python3 → awk (last-resort regex, best-effort)
# The first three are real JSON parsers; awk only runs when nothing better exists.
parse_payload() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '
      def pct: if . == null then "" else (round | tostring) end;
      ( .workspace.current_dir // .cwd // "" ),
      ( .model.display_name // "" ),
      ( .effort.level // "" ),
      ( .context_window.used_percentage | pct ),
      ( .rate_limits.five_hour.used_percentage | pct ),
      ( .rate_limits.five_hour.resets_at // "" ),
      ( .rate_limits.seven_day.used_percentage | pct )
    '
  elif command -v node >/dev/null 2>&1; then
    node -e '
      let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
        let j={};try{j=JSON.parse(s)}catch(e){}
        const g=(o,...k)=>k.reduce((a,x)=>(a==null?a:a[x]),o);
        const pct=v=>(v==null?"":String(Math.round(v)));
        const rl=j.rate_limits||{};
        process.stdout.write([
          g(j,"workspace","current_dir") ?? j.cwd ?? "",
          g(j,"model","display_name") ?? "",
          g(j,"effort","level") ?? "",
          pct(g(j,"context_window","used_percentage")),
          pct(g(rl,"five_hour","used_percentage")),
          g(rl,"five_hour","resets_at") ?? "",
          pct(g(rl,"seven_day","used_percentage")),
        ].join("\n"));
      });
    '
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
try: j = json.load(sys.stdin)
except Exception: j = {}
def g(o, *ks):
    for k in ks:
        if not isinstance(o, dict): return None
        o = o.get(k)
    return o
def pct(v): return "" if v is None else str(round(v))
rl = j.get("rate_limits") or {}
print("\n".join([
    g(j, "workspace", "current_dir") or j.get("cwd") or "",
    g(j, "model", "display_name") or "",
    g(j, "effort", "level") or "",
    pct(g(j, "context_window", "used_percentage")),
    pct(g(rl, "five_hour", "used_percentage")),
    str(g(rl, "five_hour", "resets_at") or ""),
    pct(g(rl, "seven_day", "used_percentage")),
]))
'
  else
    # No JSON parser present. Best-effort regex extraction — assumes flat
    # sub-objects and may mishandle exotic escaping, but keeps the bar alive.
    awk '
      function strval(s, key,   re, rest, i, c, val) {
        re = "\"" key "\"[ \t]*:[ \t]*\"";
        if (match(s, re)) {
          rest = substr(s, RSTART + RLENGTH); val = "";
          for (i = 1; i <= length(rest); i++) {
            c = substr(rest, i, 1);
            if (c == "\\") { val = val substr(rest, i, 2); i++; continue }
            if (c == "\"") break;
            val = val c;
          }
          return val;
        }
        return "";
      }
      function numnear(s, parent, key,   rest, re, m) {
        if (match(s, "\"" parent "\"")) {
          rest = substr(s, RSTART);
          re = "\"" key "\"[ \t]*:[ \t]*[0-9.]+";
          if (match(rest, re)) {
            m = substr(rest, RSTART, RLENGTH);
            sub(/^.*:[ \t]*/, "", m);
            return m;
          }
        }
        return "";
      }
      function rnd(x) { return x == "" ? "" : sprintf("%.0f", x + 0) }
      { s = s $0 "\n" }
      END {
        dir = strval(s, "current_dir"); if (dir == "") dir = strval(s, "cwd");
        print dir;
        print strval(s, "display_name");
        print strval(s, "level");
        print rnd(numnear(s, "context_window", "used_percentage"));
        print rnd(numnear(s, "five_hour", "used_percentage"));
        print numnear(s, "five_hour", "resets_at");
        print rnd(numnear(s, "seven_day", "used_percentage"));
      }
    '
  fi
}

# One field per line (mapfile preserves empty lines; `read` would collapse them).
mapfile -t f < <(printf '%s' "$input" | parse_payload)
cur_dir="${f[0]}"
model="${f[1]}"
effort="${f[2]}"
ctx_used="${f[3]}"
five_pct="${f[4]}"
five_reset="${f[5]}"
seven_pct="${f[6]}"

# Directory: collapse $HOME to ~
if [ -n "$HOME" ] && [[ "$cur_dir" == "$HOME"* ]]; then
  dir="~${cur_dir#"$HOME"}"
else
  dir="$cur_dir"
fi

# Git branch (fall back to short SHA when detached)
branch=""
if [ -n "$cur_dir" ]; then
  branch=$(git -C "$cur_dir" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cur_dir" rev-parse --short HEAD 2>/dev/null)
fi

# Humanize seconds -> "1h46m" / "46m"
fmt_remaining() {
  local reset="$1" now rem h m
  [ -z "$reset" ] && return
  now=$(date +%s)
  rem=$(( reset - now ))
  [ "$rem" -le 0 ] && return
  h=$(( rem / 3600 ))
  m=$(( (rem % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

# --- Colors (ANSI) ---
RST=$'\033[0m'; DIM=$'\033[2m'
CYAN=$'\033[36m'; MAG=$'\033[1;95m'; BLU=$'\033[1;34m'
GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'

# Color a usage percentage: green < 50, yellow < 80, red >= 80
pctcolor() {
  local n="${1%%.*}"   # strip any decimals for the comparison
  [ -z "$n" ] && n=0
  if   [ "$n" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$n" -ge 50 ]; then printf '%s' "$YEL"
  else printf '%s' "$GRN"; fi
}

# Color an effort level: low/medium green, high yellow, xhigh/max red
effcolor() {
  case "$1" in
    xhigh|max) printf '%s' "$RED" ;;
    high)      printf '%s' "$YEL" ;;
    *)         printf '%s' "$GRN" ;;
  esac
}

# add <label> <colored-value>  -> "label:value" with a dim label
segs=()
add() { segs+=("${DIM}$1:${RST}$2${RST}"); }

[ -n "$dir" ]      && add "dir"    "${CYAN}${dir}"
[ -n "$branch" ]   && add "branch" "${MAG}${branch}"
# Model + effort share one segment ("model:Opus 4.8 (1M context), high") — they're
# related and merging them saves width. Effort keeps its own severity color.
if [ -n "$model" ]; then
  mval="${BLU}${model}"
  [ -n "$effort" ] && mval="${mval}${RST}, $(effcolor "$effort")${effort}"
  add "model" "$mval"
elif [ -n "$effort" ]; then
  add "effort" "$(effcolor "$effort")${effort}"
fi
[ -n "$ctx_used" ] && add "ctx"    "$(pctcolor "$ctx_used")${ctx_used}%"

if [ -n "$five_pct" ]; then
  rem=$(fmt_remaining "$five_reset")
  if [ -n "$rem" ]; then add "5h" "$(pctcolor "$five_pct")${five_pct}% ${DIM}(${rem})"
  else add "5h" "$(pctcolor "$five_pct")${five_pct}%"; fi
fi
[ -n "$seven_pct" ] && add "7d" "$(pctcolor "$seven_pct")${seven_pct}%"

# Join with a dim " · "
out=""
sep="${DIM} · ${RST}"
for s in "${segs[@]}"; do
  if [ -z "$out" ]; then out="$s"; else out="${out}${sep}${s}"; fi
done
printf '%s' "$out"
