#!/usr/bin/env python3
import pandas as pd
import argparse
import sys
import signal

# Handle broken pipes (e.g., when piping to 'head')
try:
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
except AttributeError:
    pass # SIGPIPE doesn't exist on Windows

def main():
    parser = argparse.ArgumentParser(
        description="""
Advanced Table Merger
Merge two files (CSV, TSV, Gzip) with pandas. Supports multiple keys and streaming to console.
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  ./merge_tables.py file1.tsv file2.tsv --on ID --sort
  ./merge_tables.py f1.tsv f2.tsv --on ID --sort Length --descending
        """
    )

    # File arguments
    pos_group = parser.add_argument_group("Positional Arguments")
    pos_group.add_argument("left", help="Path to the 'left' file (supports .gz)")
    pos_group.add_argument("right", help="Path to the 'right' file (supports .gz)")

    # Key selection (Mutually Exclusive)
    key_group = parser.add_argument_group("Join Key Selection (Required)")
    key_exclusive = key_group.add_mutually_exclusive_group(required=True)
    key_exclusive.add_argument("--on", nargs='+', metavar='COL',
                               help="Column name(s) present in BOTH files")
    key_exclusive.add_argument("--left-on", nargs='+', metavar='COL',
                               help="Column name(s) in the left file")
    key_group.add_argument("--right-on", nargs='+', metavar='COL',
                           help="Column name(s) in the right file (Required if --left-on is used)")

    # File Format/Separator options
    fmt_group = parser.add_argument_group("File Format Options")
    fmt_group.add_argument("-o", "--output", help="Output path. If omitted, result is printed to STDOUT.")
    fmt_group.add_argument("--ls", "--left-sep", default="\t", metavar='SEP', 
                           help='Left file separator (default: "\\t" (tab))')
    fmt_group.add_argument("--rs", "--right-sep", default="\t", metavar='SEP', 
                           help='Right file separator (default: "\\t" (tab))')
    fmt_group.add_argument("--os", "--out-sep", default="\t", metavar='SEP', 
                           help='Output separator (default: "\\t" (tab))')

    # Merge Behavior options
    merge_group = parser.add_argument_group("Merge Logic Options")
    merge_group.add_argument("-m", "--how", choices=['inner', 'left', 'right', 'outer', 'cross'], default='inner',
                             help="Join type (default: %(default)s)")
    merge_group.add_argument("--suffixes", nargs=2, default=('_x', '_y'), metavar=('S1', 'S2'),
                             help="Suffix to add to overlapping column names (default: _x _y)")
    merge_group.add_argument("--indicator", action="store_true", 
                             help="Add column '_merge' with information on the source of each row")
    
    # Sorting options
    merge_group.add_argument("--sort", nargs='*', metavar='COL',
                             help="Sort by specified column(s). If no columns provided, sorts by join keys.")
    merge_group.add_argument("--descending", action="store_true", 
                             help="Sort in descending order (default: ascending)")

    args = parser.parse_args()

    # Validation
    if args.left_on and not args.right_on:
        parser.error("--right-on must be specified when using --left-on")

    try:
        # 1. Load Data
        df1 = pd.read_csv(args.left, sep=args.ls, compression='infer')
        df2 = pd.read_csv(args.right, sep=args.rs, compression='infer')

        # 2. Build Arguments
        merge_kwargs = {
            'how': args.how, 
            'suffixes': tuple(args.suffixes), 
            'indicator': args.indicator
        }
        
        if args.on:
            merge_kwargs['on'] = args.on
            join_keys = args.on
        else:
            merge_kwargs['left_on'] = args.left_on
            merge_kwargs['right_on'] = args.right_on
            join_keys = args.left_on

        # 3. Merge
        result = pd.merge(df1, df2, **merge_kwargs)

        # 4. Handle Sorting
        if args.sort is not None:
            # If --sort was used but no columns specified, use join_keys
            sort_cols = args.sort if len(args.sort) > 0 else join_keys
            result = result.sort_values(by=sort_cols, ascending=not args.descending)

        # 5. Handle Output
        if args.output:
            result.to_csv(args.output, sep=args.os, index=False, compression='infer')
            print(f"Success! {len(result)} rows saved to {args.output}", file=sys.stderr)
        else:
            try:
                result.to_csv(sys.stdout, sep=args.os, index=False)
                sys.stdout.flush()
            except BrokenPipeError:
                sys.stderr.close()
                sys.exit(0)

    except Exception as e:
        if "Broken pipe" not in str(e):
            print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()