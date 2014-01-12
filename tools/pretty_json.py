#!/usr/bin/env python
import sys,os,json
local_path = os.path.dirname(os.path.abspath(sys.argv[0]))
sys.path.append(local_path + "/./")

def main():
    line = json.loads(open(sys.argv[1]).readline())
    print json.dumps(line, indent=4)
if __name__ == '__main__':
    main()
