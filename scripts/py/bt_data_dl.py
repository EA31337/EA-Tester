#!/usr/bin/env python3
# Script to download Forex historical data and convert into CSV format.
# Sample usage:
#   ./bt_data_dl.py -p EURUSD -y 2017,2018

import sys
import os
import argparse
import datetime
import time
import urllib.request, socket
from urllib.error import HTTPError,ContentTooShortError
try:
    import lzma
except ImportError:
    from backports import lzma
from struct import *
import csv
import subprocess

intlist = lambda l: list(map(int, l))

# Create a mapping of currencies.
all_currencies = {
    # Currency pairs.
    "AUDJPY": 1175270400, # starting from 2007.03.30 16:00
    "AUDNZD": 1229961600, # starting from 2008.12.22 16:00
    "AUDUSD": 1175270400, # starting from 2007.03.30 16:00
    "CADJPY": 1175270400, # starting from 2007.03.30 16:00
    "CHFJPY": 1175270400, # starting from 2007.03.30 16:00
    "EURAUD": 1175270400, # starting from 2007.03.30 16:00
    "EURCAD": 1222167600, # starting from 2008.09.23 11:00
    "EURCHF": 1175270400, # starting from 2007.03.30 16:00
    "EURGBP": 1175270400, # starting from 2007.03.30 16:00
    "EURJPY": 1175270400, # starting from 2007.03.30 16:00
    "EURNOK": 1175270400, # starting from 2007.03.30 16:00
    "EURSEK": 1175270400, # starting from 2007.03.30 16:00
    "EURUSD": 1175270400, # starting from 2007.03.30 16:00
    "GBPCHF": 1175270400, # starting from 2007.03.30 16:00
    "GBPJPY": 1175270400, # starting from 2007.03.30 16:00
    "GBPUSD": 1175270400, # starting from 2007.03.30 16:00
    "NZDUSD": 1175270400, # starting from 2007.03.30 16:00
    "USDCAD": 1175270400, # starting from 2007.03.30 16:00
    "USDCHF": 1175270400, # starting from 2007.03.30 16:00
    "USDJPY": 1175270400, # starting from 2007.03.30 16:00
    "USDNOK": 1222639200, # starting from 2008.09.28 22:00
    "USDSEK": 1222642800, # starting from 2008.09.28 23:00
    "USDSGD": 1222642800, # starting from 2008.09.28 23:00
    "AUDCAD": 1266318000, # starting from 2010.02.16 11:00
    "AUDCHF": 1266318000, # starting from 2010.02.16 11:00
    "CADCHF": 1266318000, # starting from 2010.02.16 11:00
    "EURNZD": 1266318000, # starting from 2010.02.16 11:00
    "GBPAUD": 1266318000, # starting from 2010.02.16 11:00
    "GBPCAD": 1266318000, # starting from 2010.02.16 11:00
    "GBPNZD": 1266318000, # starting from 2010.02.16 11:00
    "NZDCAD": 1266318000, # starting from 2010.02.16 11:00
    "NZDCHF": 1266318000, # starting from 2010.02.16 11:00
    "NZDJPY": 1266318000, # starting from 2010.02.16 11:00
    "XAGUSD": 1289491200, # starting from 2010.11.11 16:00
    "XAUUSD": 1305010800, # starting from 2011.05.10 07:00

    "ADSDEEUR": 1426201200, # starting from 2015.03.13 00:00
    "ALVDEEUR": 1429394400, # starting from 2015.04.19 00:00
    "AUSIDXAUD": 1402524000, # starting from 2014.06.12 00:00
    "BASDEEUR": 1429678800, # starting from 2015.04.22 07:00
    "BAYNDEEUR": 1426806000, # starting from 2015.03.20 00:00
    "BEIDEEUR": 1428444000, # starting from 2015.04.08 00:00
    "BMWDEEUR": 1427151600, # starting from 2015.03.24 00:00
    "BRENTCMDUSD": 1291244400, # starting from 2010.12.02 00:00
    "CHEIDXCHF": 1356994800, # starting from 2013.01.01 00:00
    "CONDEEUR": 1428444000, # starting from 2015.04.08 00:00
    "DAIDEEUR": 1427410800, # starting from 2015.03.27 00:00
    "DB1DEEUR": 1428962400, # starting from 2015.04.14 00:00
    "DBKDEEUR": 1427238000, # starting from 2015.03.25 00:00
    "DEUIDXEUR": 1356994800, # starting from 2013.01.01 00:00
    "DTEDEEUR": 1427752800, # starting from 2015.03.31 00:00
    "EOANDEEUR": 1429480800, # starting from 2015.04.20 00:00
    "ESPIDXEUR": 1427238000, # starting from 2015.03.25 00:00
    "EUSIDXEUR": 1433196000, # starting from 2015.06.02 00:00
    "FMEDEEUR": 1427839200, # starting from 2015.04.01 00:00
    "FRAIDXEUR": 1356994800, # starting from 2013.01.01 00:00
    "FREDEEUR": 1428616800, # starting from 2015.04.10 00:00
    "HEIDEEUR": 1427925600, # starting from 2015.04.02 00:00
    "HEN3DEEUR": 1429567200, # starting from 2015.04.21 00:00
    "HKGIDXHKD": 1370210400, # starting from 2013.06.03 00:00
    "IFXDEEUR": 1428876000, # starting from 2015.04.13 00:00
    "JPNIDXJPY": 1356994800, # starting from 2013.01.01 00:00
    "LHADEEUR": 1429567200, # starting from 2015.04.21 00:00
    "LIGHTCMDUSD": 1427839200, # starting from 2015.04.01 00:00
    "LINDEEUR": 1429567200, # starting from 2015.04.21 00:00
    "LXSDEEUR": 1429567200, # starting from 2015.04.21 00:00
    "MRKDEEUR": 1427151600, # starting from 2015.03.24 00:00
    "MUV2DEEUR": 1429567200, # starting from 2015.04.21 00:00
    "PAH3DEEUR": 1429567200, # starting from 2015.04.21 00:00
    "PSMDEEUR": 1429480800, # starting from 2015.04.20 00:00
    "RWEDEEUR": 1429135200, # starting from 2015.04.16 00:00
    "SAPDEEUR": 1429135200, # starting from 2015.04.16 00:00
    "SDFDEEUR": 1429048800, # starting from 2015.04.15 00:00
    "SIEDEEUR": 1429480800, # starting from 2015.04.20 00:00
    "TKADEEUR": 1428962400, # starting from 2015.04.14 00:00
    "TUI1DEEUR": 1429048800, # starting from 2015.04.15 00:00
    "USA30IDXUSD": 1356994800, # starting from 2013.01.01 00:00
    "USA500IDXUSD": 1356994800, # starting from 2013.01.01 00:00
    "USATECHIDXUSD": 1356994800, # starting from 2013.01.01 00:00
    "VNADEEUR": 1428962400, # starting from 2015.04.14 00:00
    "VOW3DEEUR": 1428962400, # starting from 2015.04.14 00:00


    # commodities - energy
    #"E_Light": 1324375200, # Light starting from 2011.12.20 10:00
    #"E_Brent": 1326988800, # Brent starting from 2012.01.19 16:00
    # commodities - metals
    #"E_Copper": 1326988800, # Copper starting from 2012.01.19 16:00
    #"E_Palladium": 1326988800, # Palladium starting from 2012.01.19 16:00
    #"E_Platinum": 1326988800, # Platinum starting from 2012.01.19 16:00
    # indices - Europe
    #"E_DJE50XX": 1326988800, # Europe 50 starting from 2012.01.19 16:00
    #"E_CAAC40": 1326988800, # France 40 starting from 2012.01.19 16:00
    #"E_Futsee100": 1326988800, # UK 100 starting from 2012.01.19 16:00
    #"E_DAAX": 1326988800, # Germany 30 starting from 2012.01.19 16:00
    #"E_SWMI": 1326988800, # Switzerland 20 starting from 2012.01.19 16:00
    # indices - Americas
    #"E_NQcomp": 1326988800, # US Tech Composite starting from 2012.01.19 16:00
    "E_Nysseecomp": 1326988800, # US Composite starting from 2012.01.19 16:00
    #"E_DJInd": 1326988800, # US 30 starting from 2012.01.19 16:00
    #"E_NQ100": 1326988800, # US 100 Tech starting from 2012.01.19 16:00
    #"E_SandP500": 1326988800, # US 500 starting from 2012.01.19 16:00
    #"E_AMMEKS": 1326988800, # US Average starting from 2012.01.19 16:00
    # indices - Asia / Pacific
    #"E_HKong": 1328475600, # Hong Kong 40 starting from 2012.02.05 21:00
    "E_SCKorea": 1326988800, # Korea 200 starting from 2012.01.19 16:00
    #"E_N225Jap": 1328486400, # Japan 225 starting from 2012.02.06 00:00
    # stocks - Australia
    #"E_ANZASX": 1348146000, # Australia & Nz Banking starting from 2012.09.20 13:00
    #"E_BHPASX": 1348156800, # Bhp Billiton starting from 2012.09.20 16:00
    #"E_CBAASX": 1348156800, # Commonwealth Bank Of Australia starting from 2012.09.20 16:00
    #"E_NABASX": 1348156800, # National Australia Bank starting from 2012.09.20 16:00
    #"E_WBCASX": 1348156800, # Westpac Banking starting from 2012.09.20 16:00
    # stocks - Hungary
    #"E_EGISBUD": 1348146000, # Egis Nyrt starting from 2012.09.20 13:00
    #"E_MOLBUD": 1348146000, # Mol Hungarian Oil & Gas Nyrt starting from 2012.09.20 13:00
    #"E_MTELEKOMBUD": 1348146000, # Magyar Telekom Telecommunications starting from 2012.09.20 13:00
    #"E_OTPBUD": 1348146000, # Ot Bank Nyrt starting from 2012.09.20 13:00
    #"E_RICHTERBUD": 1348146000, # Richter Gedeon Nyrt starting from 2012.09.20 13:00
    # stocks - France
    #"E_BNPEEB": 1341594000, # BNP Paribas starting from 2012.07.06 17:00
    #"E_FPEEB": 1341594000, # Total starting from 2012.07.06 17:00
    #"E_FTEEEB": 1341594000, # France Telecom starting from 2012.07.06 17:00
    #"E_MCEEB": 1341594000, # LVMH Moet Hennessy Louis Vuitton starting from 2012.07.06 17:00
    #"E_SANEEB": 1341594000, # Sanofi starting from 2012.07.06 17:00
    # stocks - Netherlands
    #"E_MTEEB": 1333101600, # ArcelorMittal starting from 2012.03.30 10:00
    #"E_PHIA": 1341406800, # Koninklijke Philips Electronics starting from 2012.07.04 13:00
    #"E_RDSAEEB": 1333101600, # Royal Dutch Shell starting from 2012.03.30 10:00
    #"E_UNAEEB": 1333101600, # Unilever starting from 2012.03.30 10:00
    # stocks - Germany
    #"E_BAY": 1330948800, # Bayer starting from 2012.03.05 12:00
    #"E_BMWXET": 1333101600, # BMW starting from 2012.03.30 10:00
    #"E_EOANXET": 1333101600, # E.On starting from 2012.03.30 10:00
    #"E_SIEXET": 1341604800, # Siemens starting from 2012.07.06 20:00
    #"E_VOWXET": 1341604800, # Volkswagen starting from 2012.07.06 20:00
    # stocks - Hong Kong
    #"E_0883HKG": 1341781200, # CNOOC starting from 2012.07.08 21:00
    #"E_0939HKG": 1341784800, # China Construction Bank starting from 2012.07.08 22:00
    #"E_0941HKG": 1341781200, # China Mobile starting from 2012.07.08 21:00
    #"E_1398HKG": 1341781200, # ICBC starting from 2012.07.08 21:00
    #"E_3988HKG": 1341784800, # Bank Of China starting from 2012.07.08 22:00
    # stocks - UK
    #"E_BLTLON": 1333101600, # BHP Billiton starting from 2012.03.30 10:00
    #"E_BP": 1326988800, # BP starting from 2012.01.19 16:00
    #"E_HSBA": 1326988800, # HSBC Holdings starting from 2012.01.19 16:00
    #"E_RIOLON": 1333101600, # Rio Tinto starting from 2012.03.30 10:00
    #"E_VODLON": 1333101600, # Vodafone starting from 2012.03.30 10:00
    # stocks - Spain
    #"E_BBVAMAC": 1348149600, # BBVA starting from 2012.09.20 14:00
    #"E_IBEMAC": 1348149600, # Iberdrola starting from 2012.09.20 14:00
    #"E_REPMAC": 1348149600, # Repsol starting from 2012.09.20 14:00
    #"E_SANMAC": 1348149600, # Banco Santander starting from 2012.09.20 14:00
    #"E_TEFMAC": 1348149600, # Telefonica starting from 2012.09.20 14:00
    # stocks - Italy
    #"E_EN": 1348146000, # Enel starting from 2012.09.20 13:00
    #"E_ENIMIL": 1348146000, # Eni starting from 2012.09.20 13:00
    #"E_FIA": 1348146000, # Fiat starting from 2012.09.20 13:00
    #"E_GMIL": 1348146000, # Generali starting from 2012.09.20 13:00
    #"E_ISPMIL": 1348146000, # Intesa Sanpaolo starting from 2012.09.20 13:00
    #"E_UCGMIL": 1348146000, # Unicredit starting from 2012.09.20 13:00
    # stocks - Denmark
    #"E_CARL_BOMX": 1348149600, # Carlsberg starting from 2012.09.20 14:00
    #"E_DANSKEOMX": 1348149600, # Danske Bank starting from 2012.09.20 14:00
    #"E_MAERSK_BOMX": 1348149600, # Moeller Maersk B starting from 2012.09.20 14:00
    #"E_NOVO_BOMX": 1348149600, # Novo Nordisk starting from 2012.09.20 14:00
    #"E_VWSOMX": 1348149600, # Vestas Wind starting from 2012.09.20 14:00
    # stocks - Sweden
    #"E_SHB_AOMX": 1348149600, # Svenska Handelsbanken starting from 2012.09.20 14:00
    #"E_SWED_AOMX": 1348149600, # Swedbank starting from 2012.09.20 14:00
    #"E_TLSNOMX": 1348149600, # Teliasonera starting from 2012.09.20 14:00
    #"E_VOLV_BOMX": 1348149600, # Volvo B starting from 2012.09.20 14:00
    #"E_NDAOMX": 1348149600, # Nordea Bank starting from 2012.09.20 14:00
    # stocks - Norway
    #"E_DNBOSL": 1348146000, # DNB starting from 2012.09.20 13:00
    #"E_SDRLOSL": 1348146000, # Seadrill starting from 2012.09.20 13:00
    #"E_STLOSL": 1348146000, # StatoilHydro starting from 2012.09.20 13:00
    #"E_TELOSL": 1348146000, # Telenor starting from 2012.09.20 13:00
    #"E_YAROSL": 1348146000, # Yara starting from 2012.09.20 13:00
    # stocks - Singapore
    #"E_C07SES": 1348149600, # Jardine Matheson starting from 2012.09.20 14:00
    #"E_D05SES": 1348149600, # DBS Group starting from 2012.09.20 14:00
    #"E_O39SES": 1348153200, # Oversea-Chinese Banking starting from 2012.09.20 15:00
    #"E_U11SES": 1348149600, # United Overseas Bank starting from 2012.09.20 14:00
    #"E_Z74SES": 1348149600, # Singapore Telecommunications starting from 2012.09.20 14:00
    # stocks - Switzerland
    #"E_CSGN": 1326988800, # Cs Group starting from 2012.01.19 16:00
    #"E_NESN": 1326988800, # Nestle starting from 2012.01.19 16:00
    #"E_NOVNSWX": 1333101600, # Novartis starting from 2012.03.30 10:00
    #"E_UBSN": 1326988800, # UBS starting from 2012.01.19 16:00
    # stocks - Austria
    #"E_ANDRVIE": 1348149600, # Andritz starting from 2012.09.20 14:00
    #"E_EBS": 1348149600, # Erste Group Bank starting from 2012.09.20 14:00
    #"E_OMVVIE": 1348149600, # OMV starting from 2012.09.20 14:00
    #"E_RBIVIE": 1348149600, # Raiffeisen Bank starting from 2012.09.20 14:00
    #"E_VOE": 1348149600, # Voestalpine starting from 2012.09.20 14:00
    # stocks - Poland
    #"E_KGHWAR": 1348146000, # KGHM Polska Miedz starting from 2012.09.20 13:00
    #"E_PEOWAR": 1348146000, # Bank Pekao starting from 2012.09.20 13:00
    #"E_PKNWAR": 1348146000, # Polski Koncern Naftowy Orlen starting from 2012.09.20 13:00
    #"E_PKOBL1WAR": 1348146000, # Powszechna Kasa Oszczednosci Bank Polski starting from 2012.09.20 13:00
    #"E_PZUWAR": 1348146000, # Powszechny Zaklad Ubezpieczen starting from 2012.09.20 13:00
    # stocks - US
    #"E_AAPL": 1333101600, # Apple starting from 2012.03.30 10:00
    #"E_AMZN": 1324375200, # Amazon starting from 2011.12.20 10:00
    #"E_AXP": 1326988800, # American Express starting from 2012.01.19 16:00
    #"E_BAC": 1324375200, # Bank Of America starting from 2011.12.20 10:00
    #"E_CL": 1333101600, # Colgate Palmolive starting from 2012.03.30 10:00
    #"E_CSCO": 1324375200, # Cisco starting from 2011.12.20 10:00
    #"E_DELL": 1326988800, # Dell starting from 2012.01.19 16:00
    #"E_DIS": 1324375200, # Disney Walt starting from 2011.12.20 10:00
    #"E_EBAY": 1326988800, # Ebay starting from 2012.01.19 16:00
    #"E_GE": 1324375200, # General Electric starting from 2011.12.20 10:00
    #"E_GM": 1324375200, # General Motors starting from 2011.12.20 10:00
    #"E_GOOGL": 1324375200, # Google starting from 2011.12.20 10:00
    #"E_HD": 1326988800, # Home Depot starting from 2012.01.19 16:00
    #"E_HPQ": 1324375200, # Hewlett Packard starting from 2011.12.20 10:00
    #"E_IBM": 1324375200, # IBM starting from 2011.12.20 10:00
    #"E_INTC": 1324375200, # Intel starting from 2011.12.20 10:00
    #"E_JNJ": 1324375200, # Johnson & Johnson starting from 2011.12.20 10:00
    #"E_JPM": 1324375200, # JPMorgan Chase starting from 2011.12.20 10:00
    #"E_KO": 1324375200, # Coca Cola starting from 2011.12.20 10:00
    #"E_MCD": 1324375200, # McDonalds starting from 2011.12.20 10:00
    #"E_MMM": 1324375200, # 3M starting from 2011.12.20 10:00
    #"E_MSFT": 1324375200, # Microsoft starting from 2011.12.20 10:00
    #"E_ORCL": 1324375200, # Oracle starting from 2011.12.20 10:00
    #"E_PG": 1324375200, # Procter & Gamble starting from 2011.12.20 10:00
    #"E_PM": 1333105200, # Philip Morris starting from 2012.03.30 11:00
    #"E_SBUX": 1326988800, # Starbucks starting from 2012.01.19 16:00
    #"E_T": 1324378800, # AT&T starting from 2011.12.20 11:00
    #"E_UPS": 1333105200, # UPS starting from 2012.03.30 11:00
    "E_VIXX": 1326988800, # Cboe Volatility Index starting from 2012.01.19 16:00
    #"E_WMT": 1326988800, # Wal-Mart Stores starting from 2012.01.19 16:00
    #"E_XOM": 1324375200, # Exxon Mobil starting from 2011.12.20 10:00
    #"E_YHOO": 1326988800, # Yahoo starting from 2012.01.19 16:00
}

class Dukascopy:
    url_tpl = "http://www.dukascopy.com/datafeed/%s/%04d/%02d/%02d/%02dh_ticks.bi5"

    def __init__(self, pair, year, month, day, hour, dest = "download/dukascopy"):
        if not os.path.exists(dest):
            os.makedirs(dest)
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.url = self.url_tpl % (pair, int(year), month - 1, day, hour)
        self.path = "%s/%04d/%02d/%04d-%02d-%02d--%02dh_ticks.bi5" % (dest, year, month, year, month, day, hour)

    def download(self):
        print("Downloading %s into: %s..." % (self.url, self.path))
        if os.path.isfile(self.path):
            print("File (%s) exists, so skipping." % (self.path));
            return True
        else:
            if not os.path.exists(os.path.dirname(self.path)):
                os.makedirs(os.path.dirname(self.path))
            i = 1
            while i <= 5:
                try:
                    urllib.request.urlretrieve(self.url, filename=self.path)
                    break
                except HTTPError as err:
                    print("Error: %s, reason: %s. Retrying (%i).." % (err.code, err.reason, i));
                    i += 1
                except IOError as err:
                    print("Error: %s, reason: %s. Retrying (%i).." % (err.errno, err.strerror, i));
                    i += 1
                except socket.timeout as err:
                    print("Network error: %s. Retrying (%i).." % (err.strerror, i));
                    i += 1
                except socket.error as err:
                    print("Network error: %s. Retrying (%i).." % (err.strerror, i));
                    i += 1
                except ContentTooShortError as err:
                    print("Error: The downloaded data is less than the expected amount, so skipping.")
                    i += 1

            if i == 5:
                return False

        return True

    def bt5_to_csv(self):
        try:
            fileSize = os.stat(self.path).st_size
            if fileSize == 0:
                print("File (%s) is empty" % (self.path))
                return
        except FileNotFoundError:
            return False

        new_path = self.path.replace("bi5", "csv")
        if os.path.isfile(new_path):
            print("CSV file (%s) exists, so skipping." % (new_path));

        print("Converting into CSV (%s)..." % (new_path))

        # Opening, uncompressing & reading raw data
        try:
            with lzma.open(self.path) as f:
                data = f.read()
        # Workaround for liblzma bug (https://bugs.python.org/issue21872)
        except EOFError:
            print("Info: Ran into liblzma decompressor bug, falling back to command line decompression...")
            try:
                pipe = subprocess.Popen(['xz', '-dc', self.path], stdout=subprocess.PIPE)
            except FileNotFoundError:
                print("Error: Unable to find the 'xz' LZMA decompressor utility in your PATH, moving on.")
                return False
            data, error = pipe.communicate()

        # Opening output CSV file for write
        f = open(new_path, 'w', newline='')
        w = csv.writer(f, quoting = csv.QUOTE_NONE)

        for i in range(0, len(data)//20):
            row = bytearray()
            for j in range(0, 20):
                row.append(data[i*20 + j])

            # Big-endian to Little-endian conversion
            row = unpack('>iiiff', row)

            # Calculating & formatting column values
            minute = row[0]/1000//60
            second = row[0]/1000 - minute*60
            timestamp = "%d.%02d.%02d %02d:%02d:%06.3f" % (self.year, self.month, self.day, self.hour, minute, second)
            bidPrice = row[2]/1e5
            askPrice = row[1]/1e5
            bidVolume = "%.2f" % (row[4])
            askVolume = "%.2f" % (row[3])

            # Writing one row in CSV format
            w.writerow([timestamp, bidPrice, askPrice, bidVolume, askVolume])
        f.close()

if __name__ == '__main__':

    # Parse arguments.
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-?", "--help",         action="help",                          help="Show this help message and exit." )
    parser.add_argument("-v", "--verbose",      action="store_true",  dest="verbose",   help="Increase output verbosity." )
    parser.add_argument("-D", "--download-dir", action="store",       dest="dest",      help="Directory to download files.", default="download/dukascopy")
    parser.add_argument("-c", "--csv-convert",  action="store_true",  dest="csv",       help="Perform CSV conversion.")
    parser.add_argument("-p", "--pairs",        action="store",       dest="pairs",     help="Pair(s) to download (separated by comma).", default="all")
    parser.add_argument("-h", "--hours",        action="store",       dest="hours",     help="Hour(s) to download (separated by comma).", default="all")
    parser.add_argument("-d", "--days",         action="store",       dest="days",      help="Day(s) to download (separated by comma).", default="all")
    parser.add_argument("-m", "--months",       action="store",       dest="months",    help="Month(s) to download (separated by comma).", default="all")
    parser.add_argument("-y", "--years",        action="store",       dest="years",     help="Year(s) to download (separated by comma).", default="all")
    args = parser.parse_args()

    curr_year = datetime.date.today().year
    pairs =  list(all_currencies.keys()) if args.pairs  == "all" else args.pairs.split(',')
    hours  = range(0, 23+1)              if args.hours  == "all" else intlist(args.hours.split(','))
    days   = range(1, 31+1)              if args.days   == "all" else intlist(args.days.split(','))
    months = range(1, 12+1)              if args.months == "all" else intlist(args.months.split(','))
    years  = range(1997, curr_year+1)    if args.years  == "all" else intlist(args.years.split(','))

    try:
        currencies = []
        for pair in sorted(pairs):
            for year in sorted(years):
                for month in sorted(months):
                    for day in sorted(days):
                        for hour in sorted(hours):
                            try:
                                dt = datetime.datetime(year=year, month=month, day=day, hour=hour)
                                unix = time.mktime(dt.timetuple())
                                if unix > all_currencies.get(pair) and unix < time.time(): # Validate dates.
                                    ds = Dukascopy(pair, year, month, day, hour, dest=args.dest + "/" + pair)
                                    ds.download()
                                    if args.csv:
                                        ds.bt5_to_csv()
                                    #raise KeyboardInterrupt # perform one record for testing
                            except ValueError: # Ignore invalid dates.
                                continue
    except KeyboardInterrupt:
        sys.exit()
