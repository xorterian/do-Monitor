import sys

args = sys.argv[1:]
mode = int(args[-1])
args = [ int(a) for a in args[:-1] ]

if mode==2:
    print(sum(args))

