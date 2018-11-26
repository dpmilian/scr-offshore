# import the necessary packages
from imutils.perspective import four_point_transform
from imutils import contours
import imutils
import cv2 as cv2
import numpy as np
import sys
import math
import string 
import re
import serial
import socket
import threading
#import tkinter             ---> on windows, the module has a different name
import Tkinter as tkinter
#import pickle
#import skimage

## -----------------------------------------------------------
com_port = None
vid_device = 1

debug = False

## Areas of Interest -> Regions that contain digits to recognize
aaoi = []        

aaoi.append([(30,230),(600, 165)])       # (x,y), (w,h)
aaoi.append([(640, 215), (1160, 530)])


logo = cv2.imread("logo.png", cv2.IMREAD_UNCHANGED)
lgalpha = logo[:,:,3]
lgrgb = logo[:,:,:3]

# logo as float
lgrgb = lgrgb.astype(np.float32)
# Alpha factor
alpha_factor = lgalpha[:,:,np.newaxis].astype(np.float32) / 255.0
alpha_factor = np.concatenate((alpha_factor,alpha_factor,alpha_factor), axis=2)
n_alpha_factor = 1 - alpha_factor

lgfg = cv2.multiply(alpha_factor, lgrgb)

lgw, lgh, lgd = logo.shape

class SCR_UI():
    def __init__(self):
        self.top = tkinter.Tk()
        image = tkinter.PhotoImage(file="logo.png")
        self.top.tk.call('wm', 'iconphoto', self.top._w, image)
        self.top.wm_title("SCR Macartney Winch Monitor")

        self.Title = tkinter.Label(self.top, text="Listening on TCP Port 41149, press \"q\" to exit")
        self.Title.grid(row=0, column=1)
        self.checkbool = tkinter.BooleanVar()
        self.checkbool.set(False)
        self.check = tkinter.Checkbutton(self.top, text="debug", variable=self.checkbool)
        self.check.grid(row=0, column=2)

        self.IML1 = tkinter.Label(self.top, image = image).grid(row=0, column=0, rowspan=4)
        self.L1 = tkinter.Label(self.top, text="COM PORT (i.e. \"com1\") If empty, none is used: ").grid(row=1,column=1)
        
        self.comEntry = tkinter.Entry(self.top, bd =5, relief=tkinter.FLAT)
        self.comEntry.grid(row=1, column=2)
        # self.comEntry.insert(0, 'com1')
        # self.comEntry.pack(side = tkinter.RIGHT)
        
        self.L2 = tkinter.Label(self.top, text="VIDEO SRC (1 on laptop, 0 on normal pc): ").grid(row=2, column=1)
        
        self.vidEntry = tkinter.Entry(self.top, bd =5, relief=tkinter.FLAT)
        self.vidEntry.grid(row=2, column=2)
        self.vidEntry.insert(0, '0')

        self.okb = tkinter.Button(self.top , text="Start!", command=self.ok)
        self.okb.grid(row=3, column=2)
        self.cancelb = tkinter.Button(self.top , text="Cancel", command=self.cancel)
        self.cancelb.grid(row=3, column=1)

        for child in self.top.winfo_children():
            child.grid_configure(padx=10, pady=10)

        self.top.bind("<Return>", self.ok)
        self.top.bind("<q>", self.cancel)
        self.top.protocol("WM_DELETE_WINDOW", self.cancel)

        self.top.mainloop()

    def ok(self, event = None):
        global com_port
        global vid_device
        global debug

        debug = self.checkbool.get()
        
        if self.comEntry.get() != "":
            com_port = self.comEntry.get()

        if self.vidEntry.get() != "":
            vid_device = int(self.vidEntry.get())
        self.top.destroy()
    
    def cancel(self, event = None):
        sys.exit()

gui = SCR_UI()

## -----------------------------------------------------------
PORT = 41149
HOST = ''

clients = []

class SocketServer():

    def __init__(self, host, port, clients):
        
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # this is for easy starting/killing the app
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        self.socket.bind((host, port))
        self.socket.listen(5)
        self.clients = clients

        self.thread = threading.Thread(target=self.loop)
        self.thread.daemon = True
        self.thread.start()

    def loop(self):
        while(True):
            print("Waiting for an accept...")
            self.handle_accept()

    def handle_accept(self):
        pair = self.socket.accept()
        if pair is None:
            pass
        else:
            sock, addr = pair
            print ('Incoming connection from ' + repr(addr))
            client = TCPComms(sock)
            self.clients.append(client)

server = SocketServer(HOST, PORT, clients)

learn = False

samples = np.empty((0,100), dtype = np.float32)
responses = np.empty((0,1), dtype = np.float32)
num_keys = [i for i in range(45,58)]
#print (chr(58))
txt_keys = list(string.ascii_lowercase) + list(string.ascii_uppercase)
txt_keys = map(ord, txt_keys)
# print txt_keys
# txt_keys = [ord('s'),ord('t'),ord('o'),ord('n'),ord('m'),ord('e'),ord('r'),ord('p'),ord('l'),ord('y'),ord('d'),ord('c'),ord('a'),ord('b'),ord('w'),ord('i'),ord('h'), ord('D'), ord('C'), ord('W')]


## -----------------------------------------------------------
def addLogo(frame, lgfg, n_alpha_factor, reshape, lgw, lgh, t):

    try:
        bgrw = int((reshape[0][1]+reshape[1][1])/2 + 400 * math.cos(3*t*math.pi/1024 + math.pi/2) )
        
        bgcl = int((reshape[0][0] + reshape[1][0])/2 + (800-lgh) * math.sin(4*t*math.pi/8192))
        #print((bgrw, bgcl))
        bg = frame[bgrw:bgrw+lgw, bgcl:bgcl+lgh].astype(np.float32)
        bg = cv2.multiply(n_alpha_factor, bg)

        frame[bgrw:bgrw+lgw, bgcl:bgcl+lgh] = cv2.add(bg, lgfg)
    except:
        pass


## -----------------------------------------------------------
# also updates current status, uses previous values if current ones aren't valid

def tellEveryone(comms, clients, values, prev_values):

    global debug

    thevalues = MacartneyValues()
    if (values.weight == None):
        thevalues.weight = prev_values.weight
    else:
        thevalues.weight = values.weight

    if (values.cable == None):
        thevalues.cable = prev_values.cable
    else:
        thevalues.cable = values.cable

    if (values.speed == None):
        thevalues.speed = prev_values.speed
    else:
        thevalues.speed = values.speed

    svalues = thevalues.toString()
    
    if comms.isValid():
            comms.sendData(svalues)

    #print ("Send to " + str(len(clients)) + " TCP clients")
    for client in clients:
        ok = client.sendData(svalues)
        if not ok:
            clients.remove(client)

    print ("last > " + values.toString() + "\tsent > " + svalues)
    return thevalues

## -----------------------------------------------------------
class MacartneyValues:
    def __init__(self):
        self.weight = None
        self.cable = None
        self.speed = None

    def toString(self):
        w = self.weight
        if (w == None): w = 0
        c = self.cable
        if (c == None): c = 0
        s = self.speed
        if (s == None): s = 0
        return "$SCR$MAC,\t" + "{:.1f}".format(c) + ",\t" + "{:.3f}".format(w) + ",\t" + "{:.1f}".format(s)

    def allNull(self):
        return (self.weight == None) & (self.cable == None) & (self.speed == None)

## -----------------------------------------------------------
class ContourDigit:
    def __init__(self):
        self.x = 0
        self.y = 0
        self.w = 0
        self.h = 0
        self.contour = None
        self.roi = None

    def area(self):
        return self.w * self.h


## -----------------------------------------------------------
class TCPComms:
    def __init__(self, socket):
        self.client = socket

    def sendData(self, data):
        ok = True
        try:
            data += "\r\n"
            self.client.send(data.encode("utf8"))
            ok = True
        except Exception as e:
            print(e)
            ok = False
        return ok

## -----------------------------------------------------------
class SerialComms:
    def __init__(self, name, baud):
        self.tty = serial.Serial(name, baud)
        self.ttyname = name
 
    def sendData(self, data):
        data += "\r\n"
        self.tty.write(data.encode("utf8"))

    def isValid(self):
        return self.ttyname != None


## -----------------------------------------------------------
def preprocessImage(image):
    #image = imutils.resize(frame, height=1024)
    # cv2.putText(image, "start frame " + str(fcnt), (10, 100), 2, 1, (100,100, 10))
    
    #cv2.imshow('frame', blur)
    # image.convertTo(highcontrast, -1, 2.2, 10);
    # contrast = 40.
    # brightness = 20.
    # image = cv2.addWeighted(image, 1. + contrast/127., image, 0, brightness-contrast)
    
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray,(51,51),1.21)
    #warp = skimage.exposure.rescale_intensity(gray, out_range = (0, 255))

    #ret3,thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY,55,4)
    
    #thresh = cv2.GaussianBlur(thresh, (3,3), .1)
    #kernel=cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2,2))
    kernel1 = np.ones((3,3), np.uint8)
    thresh1 = cv2.dilate(thresh, kernel1, iterations=1)
    kernel2 = np.ones((3,3), np.uint8)
    #kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3,3))
    threshbox = cv2.erode(thresh, kernel2, iterations=4)

    threshnum = cv2.erode(thresh1, kernel1, iterations=2)
    #threshnum = thresh
    
    # close = cv2.morphologyEx(thresh,cv2.MORPH_CLOSE, kernel)
    # close = cv2.dilate(thresh, kernel, iterations=4)
    # close = cv2.erode(close, kernel, iterations=2)
    # div=np.float32(thresh)/(close)
    # thresh=np.uint8(cv2.normalize(div, div, 0, 255, cv2.NORM_MINMAX))
    
    #threshbox = cv2.Canny(threshbox, 20, 150, 255)
    # athresh = cv2.resize(threshnum, (640, 360))
    # cv2.imshow('thresh', athresh)
    # ret,thresh = cv2.threshold(gray,180,255,0)

    return threshbox, threshnum


## -----------------------------------------------------------
def isContourInteresting(c, aaoi):
    
    interesting = False
    index = -1
    x, y, w, h = cv2.boundingRect(c)
    
    for ixa, aoi in enumerate(aaoi):
        
        if x > aoi[0][0]:
            if y > aoi[0][1]:
                if (w > 0.7 * aoi[1][0]) & (w < aoi[1][0]):
                    if (h > 0.6 * aoi[1][1]) & (h < aoi[1][1]):
                        #print (cv2.boundingRect(c))
                        #print ("is interesting!")
                        interesting = True
                        index = ixa
                        break 

    return x,y,w,h, interesting, ixa


## -----------------------------------------------------------
## finds main screen rectangle

def findScreen(threshbox):
    im2, cnts, hierarchy = cv2.findContours(threshbox.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    scnts = sorted(cnts, key=cv2.contourArea, reverse=True)

    foundscreen = False
    reshape = None

    # for c in scnts:
    c = scnts[0]

    perim = cv2.arcLength(c, True)
    shape = cv2.approxPolyDP(c, 0.05 * perim, True)

    if (len(shape) == 4):

        h,w, depth = frame.shape
        
        wbias = 20 #w * 0.02 * 16/9
        hbias = 20 #h * 0.05
        #print(shape)
        shape[0][0][0] = max(shape[0][0][0] -wbias, 0)
        shape[0][0][1] = max(shape[0][0][1] - hbias, 0)
        shape[1][0][0] = max(shape[1][0][0] - wbias, 0)
        shape[1][0][1] = min(shape[1][0][1] + hbias, h)
        shape[2][0][0] = min(shape[2][0][0] + wbias, w)
        shape[2][0][1] = min(shape[2][0][1] + hbias, h)
        shape[3][0][0] = min(shape[3][0][0]  + wbias, w)
        shape[3][0][1] = max(shape[3][0][1] - hbias, 0)
        #print(shape)
        
        reshape = shape.reshape(4,2)

        foundscreen = True

    return foundscreen, reshape


## -----------------------------------------------------------

def reshapeScale(img, reshape, w, h):

    animg = four_point_transform(img, reshape)
    animg = cv2.resize(animg, (w,h))

    return animg


## -----------------------------------------------------------
def sort_contours_by_position(candidates, animage):
    a = []
    b = []

    candidates = sorted(candidates, key=lambda candidate: candidate.y)
    first = None
    rows = []
    row = []

    for c in candidates:
        if first == None :
            first = c
            row.append(c)
        else :
            if (c.y <= first.y + first.h):
                row.append(c)
                
            else :
                # print "new line, previous has " + str(len(row))
                if (len(row) > 1):      ## if not just ignore
                    cv2.line(warpshow, (0, first.y), (1023, first.y), (100,100,0),1)
                    cv2.line(warpshow, (0, first.y+first.h), (1023, first.y + first.h), (0, 100, 0), 1)
                    rows.append(row)
                row = []
                row.append(c)
                first = c

                cv2.line(warpshow, (0, c.y), (1023, c.y), (3*c.ix,100,0),1)
    
    if (len(row) > 1):
        cv2.line(warpshow, (0, first.y+first.h), (1023, first.y + first.h), (0, 100, 0), 1)
        rows.append(row)

    # filter rows
    therows = []
    for ix, row in enumerate(rows):
        if (len(row) < 2): continue
        row = sorted(row, key= lambda candidate: candidate.x)
        
        ymin = min(row, key= lambda candidate: candidate.y)
        ymax = max(row, key= lambda candidate: (candidate.y + candidate.h))
        #print ("Row " + str(ix) + " goes from " + str(ymin.y) + " to " + str(ymax.y + ymax.h))
        cv2.line(animage, (0, ymin.y), (1023, ymin.y), (200 + 20*ix,0,0 + 50*ix),2)
        cv2.line(animage, (0, ymax.y + ymax.h), (1023, ymax.y + ymax.h), (200+20*ix,0,0 + 50*ix),2)

        therows.append(row)

    # print "Total of " + str(len(rows)) + " rows"
    return therows


## -----------------------------------------------------------
def overlay(overlay, bg):
    #loop over all pixels and apply the blending equation, overlay without transparency, into bg

    for i in range(h):
        for j in range(w):
            if x+i >= rows or y+j >= cols:
                continue
            alpha = float(overlay[i][j][3]/255.0) # read the alpha channel 
            src[x+i][y+j] = alpha*overlay[i][j][:3]+(1-alpha)*src[x+i][y+j]
    return src

## -----------------------------------------------------------
def parse_digits_area(warped, model, ixaoi):

    global learn
    global num_keys
    global txt_keys
    global comms
    global clients
    global debug

    numbers = []

    h, w = warped.shape
    out = np.zeros(warped.shape, np.uint8)
    imc, cntsc, hierarchyc = cv2.findContours(warped.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    animage = warped.copy()

    candidates = []
    xr = 0
    yr = 0
    wr = 0
    hr = 0
    if learn or debug:
        cv2.imshow("warped", animage)
    
    for ix, croi in enumerate(cntsc):
        candidate = ContourDigit()
        candidate.ix = ix
        candidate.contour = croi

        #print ("Contour area " + str(cv2.contourArea(croi)))
        if cv2.contourArea(croi) < 100:
            continue
        candidate.hierarchy = hierarchyc[0][ix][3]

        # print ("hierarchy " + str(candidate.hierarchy))
        if ((candidate.hierarchy > 1) or (candidate.hierarchy < 0)):
            # print("not this one")
            continue

        candidate.x, candidate.y, candidate.w, candidate.h = cv2.boundingRect(candidate.contour)
        
        if (learn) & (xr != 0):
            cv2.rectangle(warpshow,(xr,yr),(xr+wr,yr+hr),(100,0, 10),2)   # mark previous one as already learnt
        xr = candidate.x
        yr = candidate.y
        wr = candidate.w
        hr = candidate.h
        candidate.roi = warped[yr: yr + hr, xr: xr + wr]
        # print "y = " + str(yr) + " to " + str(yr + hr) + ", x = " + str(xr) + " to " + str(xr+wr)
        candidates.append(candidate)   

    rows_of_digits = sort_contours_by_position(candidates, animage)
    
    string_out = ""
    for ixrow, row in enumerate(rows_of_digits):
        string_row = ""
        for digit in row:
            #perim = cv2.arcLength(digit.contour, True)
            #approx = cv2.approxPolyDP(digit.contour, 0.004* perim, True)
            #cntsanimage.append(approx)
            #xx,yy, ww, hh = cv2.boundingRect(c)
            cv2.rectangle(animage,(digit.x,digit.y),(digit.x+digit.w,digit.y+digit.h),(100,80, 120),2)   
    
            #cv2.drawContours(animage, [approx], -1, (10*(ixrow), 0 , (150-40) * (ixrow)), 2)

            if learn:
                cv2.rectangle(warpshow,(digit.x,digit.y),(digit.x + digit.w, digit.y+digit.h),(10,0, 200),2)
                cv2.imshow("warped", warpshow)            
                key = user_input_learned_key(digit, out)
                if key == -1 or key == 10:
                    break
                elif key == 20:
                    continue
            else:
                cv2.rectangle(warpshow,(digit.x,digit.y),(digit.x + digit.w, digit.y+digit.h),(10,0, 200),2)
                key = detect_digit(digit, model, out)
            
            string_row += chr(key)

            # if learn:
            #     cv2.imshow("out", out)

            if key == 10:
                continue
        if key == -1:
            break
        #print ("Read string: \"" + string_row + "\"")
        string_out += string_row + ","
    
    #cv2.imshow("animage", animage)
    #cv2.imshow("warped", out) 

    if debug:
        print (str(ixaoi) + " GOT " + string_out)
    
    string_out = re.sub(r"(\.){2,}", ",", string_out)
    n = 1
    while (n > 0):
        string_out, n = re.subn(r",(\.),",",", string_out)
    if debug: print ("NOW " + string_out)
    
    match = re.search(r"(\d+),(\d+)", string_out)

    while  (match):
        # if (match.group(1) != "0") & (match.group(2) != "0"):
        string_out = string_out[:match.start(0)] + match.group(1) + "." + match.group(2) + string_out[match.end(2):]
        if debug: print ("\tFIXED 1 " + string_out)
        match = re.search(r"(\d+),(\d+)", string_out)

    match = re.search(r"(,)(\.)(\d)", string_out)
    while (match):
        #if (match.group(1) != "0") & (match.group(2) != "0"):
        string_out = string_out[:match.start(0)] + "-" + string_out[match.start(2)+1:]
        if debug: print ("\tFIXED 2 " + string_out)
        match = re.search(r"(,)(\.)(\d)", string_out)

    

    if string_out != "":        
        sarray = string_out.split(',')
        for snum in sarray:
            fnum = 0
            if snum == "":
                continue
            if (ixaoi == 1):
                try:
                    snum.index(".")
                except:
                    #print ("no decimal point")
                    continue
            try:
                #print ("\t get a float out of " + snum)
                fnum = float(snum)
                numbers.append(fnum)
            except:
                pass
            
    if debug: print (" ended up with " + str(len(numbers)) + " numbers")
    if learn or debug:
        cv2.imshow("warped", warped)
    
    return numbers


## -----------------------------------------------------------
def detect_digit(digit, model, out):
    
    digitroi = cv2.resize(digit.roi, (10,10))

    digitroi = np.float32(digitroi)
    digitroi = digitroi.reshape((1,100))

    retval, results, neigh_resp, dists = model.findNearest(digitroi, k = 3)

    #string = str(chr((results[0][0])))
    # cv2.putText(out, string, (digit.x, digit.y + digit.h), 0, 1, 255)
    
    return int(retval)


## -----------------------------------------------------------
def user_input_learned_key(digit, out):
    
    global samples
    global responses

    key = cv2.waitKey(0)
    # print "Pressed key " + str(key)

    if key == 65505 or key == 65506:      # shift
        # print "pressed shift, wait!"
        key = cv2.waitKey(0)
        key = key - 65505 - 31
    
    if key == 27:
        return -1

    npkey = np.empty((1,1))
    npkey[(0,0)] = float(key)

    if key in num_keys:
        # print "Pressed # key " + chr(key)
        responses = np.append(responses, npkey, 0)
        digitroi = cv2.resize(digit.roi, (10,10))
        digitroi = np.float32(digitroi)
        sample = digitroi.reshape((1,100))
        samples = np.append(samples, sample, 0)
        
        # string = str(chr(key))
        # cv2.putText(out, string, (digit.x, digit.y + digit.h), 0, 1, 255)
        
    elif key in txt_keys:
        # print "Pressed txt key " + chr(key)
        responses = np.append(responses, npkey, 0)
        digitroi = cv2.resize(digit.roi, (10,10))
        digitroi = np.float32(digitroi)
        sample = digitroi.reshape((1,100))
        samples = np.append(samples, sample, 0)
        
        # string = str(chr(key))
        # cv2.putText(out, string, (digit.x, digit.y + digit.h), 0, 1, 100)

    elif key == 44:
        responses = np.append(responses, npkey, 0)
        digitroi = cv2.resize(digit.roi, (10,10))
        digitroi = np.float32(digitroi)
        sample = digitroi.reshape((1,100))
        samples = np.append(samples, sample, 0)

    elif key == 32 or key == 10:
        return key
        # string = " "
        # cv2.putText(out, string, (digit.x, digit.y + digit.h), 0, 1, 100)

    else :
        # print(key) 
        key = -1

    return key       



################################
################################
## MAIN ########################
################################
################################

# parameters_ok = False

if (len(sys.argv) > 1):
    if sys.argv[1] == "learn":
        # insert learning objects by hand
        learn = True
        model = None
 

#if not learn:
try:
    #######   load model training    ############### 
    samples = np.loadtxt('samples.data',np.float32)
    responses = np.loadtxt('responses.data',np.float32)
    
    responses = responses.reshape((responses.size,1))
    #print (responses.size)
    model = cv2.ml.KNearest_create()
    model.train(samples, cv2.ml.ROW_SAMPLE, responses)

    # if learn:
    #     responses = responses.tolist()
    
except:
    print("Couldn't learn trained samples, are we learning? " + str(learn))
    if not learn: sys.exit()

try:
    comms = SerialComms(com_port, 9600) # Comms('/dev/ttyUSB0', 9600)
except:
    print("Error initializing com port " + com_port + ", correct device?")
    sys.exit()

try:
    cap = cv2.VideoCapture(vid_device)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH,1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT,720)
    #cap = cv2.VideoCapture('winch.mp4')
except:
    print("Error initializing video capture device " + sys.argv[3])
    sys.exit()

fcnt = -1

small = np.zeros((256,256), np.uint8)
cv2.imshow('SCR - Winch Digit Recognition', small)
cv2.waitKey(1)

values = MacartneyValues()
while(cap.isOpened()):

    if cv2.getWindowProperty('SCR - Winch Digit Recognition', 0) < 0:
        print ("WINDOW MUST HAVE BEEN CLOSED")
        sys.exit()

    try:
        ret, frame = cap.read()
    except:
        cv2.waitKey(1)
        continue

    #print("Frame " + str(fcnt))
    #print (ret)
    if ret == False:    
        cv2.waitKey(1)
        continue

    fcnt += 1
  
    ## Intrinsic and distortion coefficients obtained for camera, used for correction of lens effects
    ## google opencv camera calibration

    mtx = np.zeros((3,3), np.float32)
    mtx[(0,0)] = 839.288
    mtx[(1,1)] = 838.725
    mtx[(0,2)] = 604.153
    mtx[(1,2)] = 339.389
    mtx[(2,2)] = 1
    dist = np.zeros(5, np.float32)
    dist[0] = -0.268498
    dist[1] = 0.132113
    dist[2] = 0.000210133
    dist[3] = 0.000169854
    dist[4] = -0.0534662

    w,h, d = frame.shape
    if (fcnt < 2):
        print ("Frame grabbed size:")
        print (frame.shape)
    if debug:
        distorted = cv2.resize(frame, (640, 360))
        cv2.imshow("distorted", distorted)
    
    frame = cv2.undistort(frame, mtx, dist)
    dim = (1820, 1024)
    # newcameramtx, roi = cv2.getOptimalNewCameraMatrix(mtx, dist, (w, h), 1, (w, h))
    # mapx, mapy = cv2.initUndistortRectifyMap(mtx, dist, None, newcameramtx, dim, 5)
    # image = cv2.remap(frame, mapx, mapy, cv2.INTER_LINEAR)
    # x, y, w, h = roi
    # image = image[y:y + h, x:x + w]

    # image = cv2.resize(image, (640, 360))
    # cv2.imshow("animage", image)
    
    
    frame = cv2.resize(frame, (1820, 1024))             # resizing to fixed resolution

    threshbox, threshnum = preprocessImage(frame)
    screen = np.zeros(threshbox.shape, np.uint8)

    ##### FIND SCREEN: SQUARE WITH DATA #####
    prev_values = values
    values = MacartneyValues()

    foundscreen, reshape = findScreen(threshbox)

    if foundscreen:

        threshbox = reshapeScale(threshbox, reshape, 1820,1024)          # where we find areas of interest
        threshnum = reshapeScale(threshnum, reshape, 1820,1024)          # where we find digits        
        screen = reshapeScale(frame, reshape, 1820,1024)                 # for debugging

        cv2.drawContours(frame, [reshape], -1, (12, 96, 222), 20)        # draws recognized screen on image
        image = cv2.resize(frame, (640, 360))       # for user feedback

        if debug:
            athresh = cv2.resize(threshnum, (640,360))
            cv2.imshow('athresh', athresh)                          # for debugging

    else:
        small = cv2.resize(frame, (640, 360))
        cv2.imshow('SCR - Macartney Winch Digit Recognition', small)
        pressed = cv2.waitKey(1)
        if pressed == ord('q'):
            break
        else: continue
    
    thex = -1
    they = -1


    ## ONCE INSIDE THE SCREEN, FIND AND LOOP OVER THE SQUARES FOR AREAS OF INTEREST ##
  
    for ixaoi, aoi in enumerate(aaoi):
        cv2.rectangle(screen, aoi[0], (aoi[0][0] + aoi[1][0], aoi[0][1] + aoi[1][1]), (100 + 50 * ixaoi, 50, 0 + 100*ixaoi), 10)
    
    im2, cnts2, hierarchy = cv2.findContours(threshbox.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    #print ("FOUND " + str(len(cnts2)) + " inner contours")
    scnts2 = sorted(cnts2, key=cv2.contourArea, reverse=True)[:15]
    
    found = 0       # stop at 2 i.e. don't process more contours if we already found the 2 squares we're looking for

    for cix, c in enumerate(scnts2):
    #     # approximate the contour
        if found == 2: break            # already found my two aoi

        perim = cv2.arcLength(c, True)
        
        approx = cv2.approxPolyDP(c, 0.02 * perim, True)
        # if (len(approx) == 4):
        displayCnt = approx

        x,y,w,h, interesting, ixaoi = isContourInteresting(c, aaoi)

        if (not interesting):
            if debug: 
                cv2.putText(screen, "[" + str(x) + ", " + str(y) + "] - " + str(w) + " x " + str(h), (x,y), cv2.FONT_HERSHEY_PLAIN, 3,  (60, 255-50* perim/500 ,200), 4)
                cv2.rectangle(screen, (x,y), (x+w, y+h), (60, 255-50* perim/500 ,200), 3) 
            # cv2.drawContours(screen, [approx], -1, (50* perim/200, 50* perim/200 ,200), 3)
        elif (interesting):
            cv2.rectangle(screen, (x,y), (x+w, y+h), (0, 200 ,0), 10) 
            # cv2.drawContours(screen, [approx], -1, (0, 200, 0), 5)

            thex = x
            they = y
            #cv2.drawContours(screen, scnts, cix, (60, 220,20), 10)
            cv2.putText(screen, "[" + str(x) + ", " + str(y) + "] - " + str(w) + " x " + str(h), (x,y), cv2.FONT_HERSHEY_PLAIN, 3, (60, 140, 5), 4)
            #### THIS ONE LOOKS LIKE DATA SQUARE, PARSE CONTOURS

            warpshow = screen[y: y + h, x: x + w]
            warped = threshnum[y: y + h, x: x + w]
            # warpshow = four_point_transform(screen, displayCnt.reshape(4,2))
            # warped = four_point_transform(threshnum, displayCnt.reshape(4,2))       # FOR NUMBER DETECTION, USE OTHER THRESHOLD
            
            # cv2.imshow("contour_" + str(cix), warped)
            #print ("parse digits area x " + str(x) + " y " + str(y))
            numbers = parse_digits_area(warped, model, ixaoi)
            
            if (debug):
                pressed = cv2.waitKey(0)
                if pressed == ord('q'):
                    sys.exit()

            if (ixaoi == 0):              # constant tension screen, speed
                # speed
                if len(numbers) > 0:
                    values.speed = numbers[0]
                    found += 1
            elif (ixaoi == 1) or (ixaoi == 2) :           # constant tension screen, cable count + tension, or speed mode screen
                nix = 0
                if nix < len(numbers):
                    #if (numbers[nix] != 0): 
                    values.cable = numbers[nix]
                    #print ("cable out " + str(values.cable))
                    nix += 1
                    #    break
                    #nix += 1

                if nix < len(numbers):
                    #if (numbers[nix] != 0):
                    values.weight = numbers[nix]
                    #print ("weight " + str(values.weight))
                    #    break
                    nix += 1
                found += 1



    if (found > 0):
        values = tellEveryone(comms, clients, values, prev_values)
        addLogo(frame, lgfg, n_alpha_factor, reshape, lgw, lgh, fcnt)

    else: 
        if debug: print("No values detected in image")

        
    if learn & (thex != -1):
        # cv2.putText(image, "frame " + str(fcnt) + " finished, press \"q\" to exit or any other key for next frame", (thex, they), cv2.FONT_HERSHEY_PLAIN, 4, (100, 180, 10),4)
        #small = imutils.resize(image, height=512)
        small = image
        cv2.imshow('SCR - Winch Digit Recognition', small)
        print ("press q now!")
        pressed = cv2.waitKey(0)
        print("continue learning")
        if pressed == ord('q'):
            break
    else:
        #print ("HERE!")
        if (thex != -1):
            cv2.putText(screen, "[" + str(fcnt) + "] press q to exit", (10, 10), cv2.FONT_HERSHEY_PLAIN, 4, (100, 180, 10),4)
        else:
            cv2.putText(screen, "[" + str(fcnt) + "] not detected, adjust camera or press q to exit", (10, 10), cv2.FONT_HERSHEY_PLAIN, 4, (100, 10, 180),4)
        
                   

        small = cv2.resize(frame, (640, 360))
        cv2.imshow('SCR - Winch Digit Recognition', small)

        pressed = cv2.waitKey(30)
        if pressed == ord('q'):
            sys.exit()
    if debug:
        asmall = cv2.resize(screen, (640, 360))
        cv2.imshow("screen", asmall)

if learn:
    
    responses = responses.reshape((responses.size, 1))
    print ("learning complete")

    np.savetxt('samples.data',samples)
    np.savetxt('responses.data',responses)

cap.release()
cv2.destroyAllWindows()
