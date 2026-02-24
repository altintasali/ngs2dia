#!/usr/bin/env python3
import pandas as pd
import argparse
import sys
import signal

# Handle broken pipes (e.g., when piping to 'head')
try:
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
except AttributeError:
    pass 

def main():
    parser = argparse.ArgumentParser(
        description="""
Advanced Table Merger
Merge two files (CSV, TSV, Gzip) with pandas. Supports multiple keys and streaming to console.
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  ./merge_tables.py f1.tsv f2.tsv --on ID
  ./merge_tables.py f1.tsv f2.tsv --no-header-left --on 1 2
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
                               help="Column name(s) or 1-based indices present in BOTH files")
    key_exclusive.add_argument("--left-on", nargs='+', metavar='COL',
                               help="Column name(s) or 1-based indices in the left file")
    key_group.add_argument("--right-on", nargs='+', metavar='COL',
                           help="Column name(s) or 1-based indices in the right file")

    # File Format Options
    fmt_group = parser.add_argument_group("File Format Options")
    fmt_group.add_argument("-o", "--output", help="Output path. If omitted, result is printed to STDOUT.")
    fmt_group.add_argument("--no-header-left", action="store_true", help="Left file has no header (uses 1-based indexing)")
    fmt_group.add_argument("--no-header-right", action="store_true", help="Right file has no header (uses 1-based indexing)")
    fmt_group.add_argument("--ls", "--left-sep", default="\t", metavar='SEP', help='Left separator (default: "\\t")')
    fmt_group.add_argument("--rs", "--right-sep", default="\t", metavar='SEP', help='Right separator (default: "\\t")')
    fmt_group.add_argument("--os", "--out-sep", default="\t", metavar='SEP', help='Output separator (default: "\\t")')

    # Merge Behavior options
    merge_group = parser.add_argument_group("Merge Logic Options")
    merge_group.add_argument("-m", "--how", choices=['inner', 'left', 'right', 'outer', 'cross'], default='inner',
                             help="Join type (default: %(default)s)")
    merge_group.add_argument("--suffixes", nargs=2, default=('_x', '_y'), metavar=('S1', 'S2'),
                             help="Suffix for overlapping columns (default: _x _y)")
    merge_group.add_argument("--indicator", action="store_true", help="Add column '_merge'")
    
    # Sorting options
    merge_group.add_argument("--sort", nargs='*', metavar='COL',
                             help="Sort by column(s). Default: join keys.")
    merge_group.add_argument("--descending", action="store_true", help="Sort in descending order")

    args = parser.parse_args()

    if args.left_on and not args.right_on:
        parser.error("--right-on must be specified when using --left-on")

    def process_key_indices(keys, is_no_header):
        """Converts 1-based user input to 0-based pandas indices if no-header is active."""
        if not keys: return keys
        processed = []
        for k in keys:
            if is_no_header and k.isdigit():
                idx = int(k) - 1
                processed.append(idx if idx >= 0 else 0)
            else:
                processed.append(k)
        return processed

    try:
        # 1. Load Data
        df1 = pd.read_csv(args.left, sep=args.ls, header=None if args.no_header_left else 0, compression='infer')
        df2 = pd.read_csv(args.right, sep=args.rs, header=None if args.no_header_right else 0, compression='infer')

        # 2. Prepare Keys (applying 1-based to 0-based logic where applicable)
        l_keys = process_key_indices(args.on or args.left_on, args.no_header_left)
        r_keys = process_key_indices(args.on or args.right_on, args.no_header_right)

        # 3. Build Merge Arguments
        merge_kwargs = {'how': args.how, 'suffixes': tuple(args.suffixes), 'indicator': args.indicator}
        
        if args.on:
            # Note: Using left_on/right_on internally allows different indexing states
            merge_kwargs['left_on'], merge_kwargs['right_on'] = l_keys, r_keys
        else:
            merge_kwargs['left_on'], merge_kwargs['right_on'] = l_keys, r_keys

        # 4. Merge
        result = pd.merge(df1, df2, **merge_kwargs)

        # 5. Handle Sorting
        if args.sort is not None:
            # Sort keys: check left-side logic for default keys
            sort_cols = process_key_indices(args.sort, args.no_header_left) if len(args.sort) > 0 else l_keys
            result = result.sort_values(by=sort_cols, ascending=not args.descending)

        # 6. Handle Output (Keep header if either file had one)
        write_header = not (args.no_header_left and args.no_header_right)
        
        if args.output:
            result.to_csv(args.output, sep=args.os, index=False, header=write_header, compression='infer')
            print(f"Success! {len(result)} rows saved to {args.output}", file=sys.stderr)
        else:
            try:
                result.to_csv(sys.stdout, sep=args.os, index=False, header=write_header)
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