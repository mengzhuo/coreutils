module main

import os
import flag
import common

const (
	app_name = 'kill'
	description = 'Send a signal to a process (default: SIGTERM)'
	help_text = 'Usage: kill [options] <pid>...\n\nOptions:\n  -s, --signal <sig>  specify the signal to send (e.g. SIGKILL, 9, SIGTERM, 15)\n  -l, --list          list all signal names\n  -L, --table         list all signal names in a table\n  -q, --quiet         do not report errors for invalid pids\n      --help          display this help and exit\n      --version       output version information and exit\n'
)

fn print_help() {
	println(help_text)
}

fn print_version() {
	println('kill (V coreutils) 0.0.1')
}

fn print_signals_table() {
	mut i := 1
	for s in os.Signal.values() {
		print('${int(s):2}: ${s.str().to_upper().pad_right(7)}\t')
		if i % 4 == 0 {
			println('')
		}
		i++
	}
	println('')
}

fn print_signals_list() {
	println(os.Signal.values().map(it.str().to_upper()).join(' '))
}

fn parse_signal(sig string) ?os.Signal {
	// Accepts signal names (with or without SIG prefix) and numbers
	upper := sig.to_upper()
	for s in os.Signal.values() {
		if upper == s.str().to_upper() || upper == 'SIG' + s.str().to_upper() {
			return s
		}
	}
	if sig.len > 0 && sig[0].is_digit() {
		val := sig.int()
		return os.Signal.from(val) or {
			return error('Unknown signal: $sig')
		}
	}
	return error('Unknown signal: $sig')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application(app_name)
	fp.description(description)
	fp.skip_executable()

	signal_str := fp.string('signal', `s`, '', 'specify the signal to send (e.g. SIGKILL, 9, SIGTERM, 15)')
	list_signals := fp.bool('list', `l`, false, 'list all signal names')
	table_signals := fp.bool('table', `L`, false, 'list all signal names in a table')
	quiet := fp.bool('quiet', `q`, false, 'do not report errors for invalid pids')
	help := fp.bool('help', 0, false, 'display this help and exit')
	version := fp.bool('version', 0, false, 'output version information and exit')

	args := fp.finalize() or {
		eprintln(err)
		print_help()
		exit(1)
	}

	if help {
		print_help()
		exit(0)
	}
	if version {
		print_version()
		exit(0)
	}
	if table_signals {
		print_signals_table()
		exit(0)
	}
	if list_signals {
		print_signals_list()
		exit(0)
	}

	if args.len == 0 {
		eprintln('no PID specified')
		print_help()
		exit(1)
	}

	sig := if signal_str != '' {
		parse_signal(signal_str) or {
			eprintln(err)
			exit(1)
		}
	} else {
		os.Signal.term // Default SIGTERM
	}

	for pid_str in args {
		pid := pid_str.int()
		if pid <= 0 {
			if !quiet {
				eprintln('invalid PID: $pid_str')
			}
			continue
		}
		res := os.kill(pid, int(sig))
		if res != 0 && !quiet {
			eprintln('failed to send signal ${int(sig)} (${sig.str().to_upper()}) to process $pid')
		}
	}
} 