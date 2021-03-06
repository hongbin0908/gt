#!/usr/bin/env python
import sys,os,json,urllib2
local_path = os.path.dirname(os.path.abspath(sys.argv[0]))
sys.path.append(local_path + "/./")
def print_usage(name):
    print """
name output_dir
    """
def get_sp500():#{{{
    finviz_retry = 3
    while finviz_retry >= 0:
        try:
            resp = urllib2.urlopen("""http://finviz.com/export.ashx?v=152&f=idx_sp500&ft=1&ta=1&p=d&r=1&c=1""")
        except Exception,ex:
            print Exception,":",ex
            retry -= 1
            continue
        break
    symbols = [symbol.strip().strip("\"") for symbol in resp.read().split("\n")[1:]]
    return symbols#}}}

def get_dow30():#{{{
    l=[]
    for line in open('/home/abin/geniustrader/data/dow30.in'):
        l.append(line.strip())
    return l#}}}
def main():
    if len(sys.argv) < 2:
       print_usage(sys.argv[0]);
       sys.exit(1)
    output_dir = sys.argv[1]
    symbols = get_sp500()
    fsp500 = open(os.path.join(output_dir, "sp500.list"), "w")

    for symbol in symbols:
        if (len(symbol.strip()) > 0):
            print >> fsp500, symbol
    fsp500.close()
    for symbol in symbols:
        output_name = os.path.join(output_dir, symbol + ".txt") 
        output = open(output_name + ".bk", "w") 
        yahoo_retry = 6
        while yahoo_retry >=0:
            try:
                resp = urllib2.urlopen("""http://ichart.finance.yahoo.com/table.csv?s=""" + symbol)
            except Exception,ex:
                print Exception,":",ex
                yahoo_retry -=1
                continue
            break
        # Date,Open,High,Low,Close,Volume,Adj Close
        datas = resp.read().split("\n")[1:]
        for data in datas[::-1]:
            tokens = data.split(",")
            if len(tokens) < 7:
                continue
            tok = float(tokens[6])/float(tokens[4])
            openv = float(tokens[1]) * tok
            high = float(tokens[2]) * tok
            low = float(tokens[3]) * tok 
            close = float(tokens[4]) * tok

            print >> output, "%s\t%s\t%s\t%s\t%s\t%s" % (openv, high, low, close, tokens[5], tokens[0])
        output.close()
        os.system("mv %s %s" % (output_name + ".bk", output_name))
        #Open High Low Close Volume Data
if __name__ == '__main__':
   main()
    
