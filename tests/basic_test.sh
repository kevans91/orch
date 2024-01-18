#!/bin/sh

scriptdir=$(dirname $(realpath "$0"))
orchbin="$(which orch)"
if [ -n "$orchbin" ]; then
	orchdir="$(dirname "$orchbin")"
else
	orchdir="$scriptdir/.."
	orchbin="$orchdir/orch"
fi

fails=0
testid=1

set -- "$scriptdir"/*.orch
echo "1..$#"

ok()
{
	echo "ok $testid - $f"
	testid=$((testid + 1))
}

not_ok()
{
	msg="$1"

	echo "not ok $testid - $f: $msg"
	testid=$((testid + 1))
}

for f in "$@" ;do
	f=$(basename "$f" .orch)
	testf="$scriptdir/$f.orch"
	expected_rc=0
	spawn="cat"

	case "$f" in
	timeout_*)
		expected_rc=1
		expected_timeout=$(grep '^-- TIMEOUT:' "$testf" | grep -Eo '[0-9]+')
		if [ "$expected_timeout" -le 0 ]; then
			not_ok "invalid timeout $expected_timeout"
			continue
		fi
		;;
	spawn_*)
		spawn=""
		;;
	esac

	start=$(date +"%s")
	if [ -x "$testf" ]; then
		env PATH="$orchdir":"$PATH" "$testf"
	else
		"$orchbin" -f "$testf" -- $spawn
	fi
	rc="$?"
	end=$(date +"%s")

	if [ "$rc" -ne "$expected_rc" ]; then
		not_ok "expected $expected_rc, exited with $rc"
		continue
	fi

	case "$f" in
	timeout_*)
		;;
	*)
		ok
		continue
		;;
	esac

	elapsed=$((end - start))
	if [ "$elapsed" -lt "$expected_timeout" ]; then
		not_ok "expected $expected_timeout seconds, finished in $elapsed"
		continue
	fi

	# Also make sure it wasn't excessively long... this could be flakey.
	excessive_timeout=$((expected_timeout + 3))
	if [ "$elapsed" -ge "$excessive_timeout" ]; then
		not_ok "expected $expected_timeout seconds, finished excessively in $elapsed"
		continue
	fi

	ok
done

exit "$fails"
