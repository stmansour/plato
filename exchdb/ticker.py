import os

tickers = dict()

tickers["EURUSD"] = 1
tickers["GBPUSD"] = 1
tickers["USDCHF"] = 1
tickers["USDJPY"] = 0
tickers["EURGBP"] = 0
tickers["EURCHF"] = 0
tickers["EURJPY"] = 0
tickers["GBPCHF"] = 0
tickers["GBPJPY"] = 0
tickers["CHFJPY"] = 0
tickers["USDCAD"] = 0
tickers["EURCAD"] = 0
tickers["AUDUSD"] = 0
tickers["AUDJPY"] = 0
tickers["NZDUSD"] = 0
tickers["NZDJPY"] = 0
tickers["XAUUSD"] = 0
tickers["XAGUSD"] = 0
tickers["USDCZK"] = 0
tickers["USDDKK"] = 0
tickers["EURRUB"] = 0
tickers["USDHUF"] = 0
tickers["USDNOK"] = 0
tickers["USDPLN"] = 0
tickers["USDRUB"] = 0
tickers["USDSEK"] = 0
tickers["USDSGD"] = 0
tickers["USDZAR"] = 0
tickers["USDTRY"] = 0
tickers["EURTRY"] = 0
tickers["EURAUD"] = 0
tickers["EURNZD"] = 0
tickers["EURSGD"] = 0
tickers["EURZAR"] = 0
tickers["XAUEUR"] = 0
tickers["XAGEUR"] = 0
tickers["GBPCAD"] = 0
tickers["GBPAUD"] = 0
tickers["GBPNZD"] = 0
tickers["AUDCHF"] = 0
tickers["AUDCAD"] = 0
tickers["AUDNZD"] = 0
tickers["NZDCHF"] = 0
tickers["NZDCAD"] = 0
tickers["CADCHF"] = 0
tickers["CADJPY"] = 0
tickers["USDUAH"] = 0
tickers["WTIUSD"] = 0
tickers["DJIUSD"] = 0
tickers["SPXUSD"] = 0
tickers["NDQUSD"] = 0
tickers["USXUSD"] = 0

def initTicker():
    fname = 'missing.txt'
    if not os.path.exists(fname):
        return

    f = open(fname,'r')
    Lines = f.readlines()
    for line in Lines:
        line = line.rstrip()
        try:
            x = tickers[line]
            print( line + " was found in tickers")
        except KeyError:
            print( "*** ADDING " + line + " to tickers")
            tickers[line] = 0  # it's known to be missing, don't store data


def unknownTicker(s):
    # append the missing ticker to the missing.txt file
    fname = 'missing.txt'
    if os.path.exists(fname):
        opt = 'a' # append if already exists
    else:
        opt = 'w' # make a new file if not

    f = open(fname,opt)
    f.write(s + "\n")
    f.close()
