# -*- coding: utf-8 -*-
from datetime import timedelta
from itertools import izip_longest as zip_longest
from PIL import Image, ImageFont, ImageDraw, ImageWin
import qrcode
import win32ui
from conf import config


class Printer(object):
    def __init__(self, name='Zebra  888-TT', page_width=400, page_height=640):
        self.name = name
        self.page_width = page_width
        self.page_height = page_height
    
    def __startDoc(self, key):
        if config.debug:
            return None
        # create a dc (Device Context) object (actually a PyCDC)
        hdc = win32ui.CreateDC()
        hdc.CreatePrinterDC(self.name)
        hdc.StartDoc(key)
        return hdc
    
    def __endDoc(self, hdc):
        if config.debug:
            return
        hdc.EndDoc()
        hdc.DeleteDC()
    
    def printRecord(self, name, key, preLeft, usage, preExpiry, useTime):
        hdc = self.__startDoc(key)
        if preLeft >= usage:
            self.__singleBottleLabel(name, key, usage, preLeft - usage, useTime, preExpiry, hdc)
            self.__singleWarningPage(name, hdc)
        else:
            demand = usage - preLeft
            if preLeft != 0:
                self.__singleBottleLabel(name, key, preLeft, 0, useTime, preExpiry, hdc)
                self.__singleWarningPage(name, hdc)
            newDrugExpiryDate = useTime + timedelta(days=config.drug_shelf_life)
            while demand > config.single_bottle_dosage:
                demand -= config.single_bottle_dosage
                self.__singleBottleLabel(name, key, config.single_bottle_dosage, 0, useTime, newDrugExpiryDate, hdc)
                self.__singleWarningPage(name, hdc)
            if demand > 0:
                self.__singleBottleLabel(name, key, demand, config.single_bottle_dosage-demand, useTime, newDrugExpiryDate, hdc)
                self.__singleWarningPage(name, hdc)
        self.__endDoc(hdc)

    def __singleBottleLabel(self, name, key_id, usage, left, useTime, expiryTime, hdc=None):
        openTime = expiryTime - timedelta(days=config.drug_shelf_life)
        image = Image.new('RGB', (self.page_width, self.page_height), (255,255,255))
        normal_font = ImageFont.truetype('simsun.ttc', 25)
        title_font = ImageFont.truetype('simsun.ttc', 20)
        emph_font = ImageFont.truetype('simhei.ttf', 26)
        draw = ImageDraw.Draw(image)
        black = (0,0,0)
        xpad, ypad = 20, 10
        x, y = xpad, ypad
        keys = [u"患者姓名:", u"使用剂量:", u"剩余剂量:", u"使用日期:", u"开封时间:", u"过期时间:", u"护士/患方签名", u"护士签名:", " ", " ", u"患方签名:", " ", " "]
        values = [name, str(usage) + " mg ("+ self.transfer(usage) + ' ml)', str(left)+' mg', useTime.strftime("%Y-%m-%d %H:%M"), 
                    openTime.strftime("%Y-%m-%d %H:%M"), expiryTime.strftime("%Y-%m-%d %H:%M")]
        # title
        text = u"上海瑞金医院乳腺疾病诊治中心--赫赛汀"
        draw.text((x, y), text, font=title_font, fill=black)
        y += title_font.getsize(text)[1]
        line_end = x + title_font.getsize(text)[0]
        draw.line((x,y, line_end, y), fill=black)
        y += ypad
        # items
        for key, value in zip_longest(keys, values, fillvalue=""):
            draw.text((x, y), key, fill=black, font=normal_font)
            draw.text((x+normal_font.getsize(key)[0], y), value, fill=black, font=emph_font)
            y += normal_font.getsize(key)[1] + ypad
        draw.line((x, y, line_end, y), fill=black)
        y += ypad
        # qrcode image
        xstart = self.page_width // 3
        qr = qrcode.QRCode(version=1,
                           error_correction=qrcode.constants.ERROR_CORRECT_L,
                           box_size=2, border=0)
        if config.debug:
            print("In devide", key_id is None, type(key_id), key_id)
        qr.add_data(key_id)
        qr.make(fit=True)
        qr_img = qr.make_image()
        image.paste(qr_img, (xstart, y))
        image = image.transpose(Image.ROTATE_90)
        self.__printImage(hdc, image)
    
    def __singleWarningPage(self, name, hdc=None):
        image = Image.new('RGB', (self.page_width, self.page_height), (255,255,255))
        normal_font = ImageFont.truetype('simsun.ttc', 50)
        title_font = ImageFont.truetype('simsun.ttc', 20)
        emph_font = ImageFont.truetype('simhei.ttf', 50)
        draw = ImageDraw.Draw(image)
        black = (0,0,0)
        xpad, ypad = 20, 10
        x, y = xpad, ypad
        keys = [" ", " ", " ", " ", " ", " ", " "] #" " is used for empty line
        values = ["", "", name, "", "", " ", u"请勿拆封"]
        # title
        text = u"上海瑞金医院乳腺疾病诊治中心--赫赛汀"
        draw.text((x, y), text, font=title_font, fill=black)
        y += title_font.getsize(text)[1]
        line_end = x + title_font.getsize(text)[0]
        draw.line((x,y, line_end, y), fill=black)
        y += ypad
        # items
        for key, value in zip_longest(keys, values, fillvalue=""):
            draw.text((x, y), key, fill=black, font=normal_font)
            draw.text((x+normal_font.getsize(key)[0], y), value, fill=black, font=emph_font)
            y += normal_font.getsize(key)[1] + ypad
        y = self.page_height - ypad - title_font.getsize(" ")[1]
        draw.line((x, y, line_end, y), fill=black)
        image = image.transpose(Image.ROTATE_90)
        self.__printImage(hdc, image)
    
    def transfer(self, mg):
        # transfer mg to ml
        return str(round(21.0/440*mg, 1))

    def __printImage(self, hdc, image):
        if config.debug:
            image.show()
            return
        hdc.StartPage()
        dib = ImageWin.Dib(image)
        dib.draw(hdc.GetHandleOutput(), (0, 0, self.page_height, self.page_width))
        hdc.EndPage()


def debug():
    from datetime import datetime
    device = Printer()
    device.printRecord(u"张三", None, 20, 100, datetime.now(), datetime.now())


if __name__ == "__main__":
    debug()