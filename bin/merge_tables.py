#!/usr/bin/env python3
import pandas as pd
import argparse
import sys
import signal

# This prevents the "Exception ignored" message when piping to 'head'
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

def main():
    parser = argparse.ArgumentParser(description="Merge tables (Pipe-safe, Gzip, Multiple Keys)")

    # File paths
    parser.add_argument("left", help="Left file (supports .gz)")
    parser.add_argument("right", help="Right file (supports .gz)")
    parser.add_argument("-o", "--output", help="Output file. If omitted, prints to console.")

    # Separators
    parser.add_argument("--ls", "--left-sep", default="\t", help="Left separator (default: tab)")
    parser.add_argument("--rs", "--right-sep", default="\t", help="Right separator (default: tab)")
    parser.add_argument("--os", "--out-sep", default="\t", help="Output separator (default: tab)")

    # Key selection
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--on", nargs='+', help="Column(s) to merge on")
    group.add_argument("--left-on", nargs='+', help="Column(s) for the left file")
    parser.add_argument("--right-on", nargs='+', help="Column(s) for the right file")
    
    # Pandas Options
    parser.add_argument("-m", "--how", choices=['inner', 'left', 'right', 'outer', 'cross'], 
                        default='inner', help="Merge type")
    parser.add_argument("--suffixes", nargs=2, default=('_x', '_y'))
    parser.add_argument("--indicator", action="store_true")
    parser.add_argument("--sort", action="store_true")

    args = parser.parse_args()

    if args.left_on and not args.right_on:
        print("❌ Error: --right-on is required when using --left-on", file=sys.stderr)
        sys.exit(1)

    try:
        # 1. Load Data
        df1 = pd.read_csv(args.left, sep=args.ls, compression='infer')
        df2 = pd.read_csv(args.right, sep=args.rs, compression='infer')

        # 2. Build Merge Arguments
        merge_kwargs = {
            'how': args.how, 
            'suffixes': tuple(args.suffixes), 
            'indicator': args.indicator,
            'sort': args.sort
        }
        
        if args.on:
            merge_kwargs['on'] = args.on
        else:
            merge_kwargs['left_on'] = args.left_on
            merge_kwargs['right_on'] = args.right_on

        # 3. Execute Merge
        result = pd.merge(df1, df2, **merge_kwargs)

        # 4. Handle Output
        if args.output:
            result.to_csv(args.output, sep=args.os, index=False, compression='infer')
            print(f"✅ Success! Merged {len(result)} rows to {args.output}", file=sys.stderr)
        else:
            # Catch broken pipe for commands like 'head'
            try:
                result.to_csv(sys.stdout, sep=args.os, index=False)
                sys.stdout.flush()
            except BrokenPipeError:
                # Python 3 handles this, but we force an exit to be clean
                sys.stderr.close()
                sys.exit(0)

    except Exception as e:
        # Only print error if it wasn't a broken pipe
        if str(e) != "[Errno 32] Broken pipe":
            print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()