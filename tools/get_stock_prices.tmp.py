#!/usr/bin/env python
import sys,os,json,urllib2
local_path = os.path.dirname(os.path.abspath(sys.argv[0]))
sys.path.append(local_path + "/./")
def print_usage(name):
	print """
name output_dir
	"""
def main():
	if len(sys.argv) < 2:
	   print_usage(sys.argv[0]);
	   sys.exit(1)
	output_dir = sys.argv[1]
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
	symbols=["QQQ"]
	for symbol in symbols:
		output = open(os.path.join(output_dir, symbol + ".txt"), "w") 
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
			print >> output, "%s\t%s\t%s\t%s\t%s\t%s" % (tokens[1], tokens[2], tokens[3],tokens[4],tokens[5],tokens[0])
		output.close()
		#Open High Low Close Volume Data
if __name__ == '__main__':
   main()
	
