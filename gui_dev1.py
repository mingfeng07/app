import wx
import wx.xrc
 

###########################################################################
## Class MyFrame3
###########################################################################
 
class MyFrame3(wx.Frame):
 
    def __init__(self, parent):
        wx.Frame.__init__(self, parent, id=wx.ID_ANY, title='我的GUI程序', pos=wx.DefaultPosition,
                          size=wx.Size(500, 300), style=wx.DEFAULT_FRAME_STYLE | wx.TAB_TRAVERSAL)
 
        self.SetSizeHints(wx.DefaultSize, wx.DefaultSize)
 
        bSizer2 = wx.BoxSizer(wx.VERTICAL)
 
        self.m_button2 = wx.Button(self, wx.ID_ANY, u"打开文件", wx.DefaultPosition, wx.DefaultSize, 0)
        self.m_button2.SetFont(wx.Font(18, wx.FONTFAMILY_SWISS, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD, False, "微软雅黑"))
        bSizer2.Add(self.m_button2, 1, wx.ALL | wx.EXPAND, 5)



        self.SetSizer(bSizer2)
        self.Layout()
        self.m_statusBar2 = self.CreateStatusBar(1, wx.STB_SIZEGRIP, wx.ID_ANY)
 
        self.Centre(wx.BOTH)
 
        # Connect Events
        self.m_button2.Bind(wx.EVT_BUTTON, self.m_button2OnButtonClick)
 
    def __del__(self):
        pass
 
    # Virtual event handlers, overide them in your derived class
    def m_button2OnButtonClick(self, event):
        openFileDialog = wx.FileDialog(frame, "请选择要打开的文件", "", "",
                                       "word格式 (*.docx)|*.docx",
                                       wx.FD_OPEN | wx.FD_MULTIPLE)

        if openFileDialog.ShowModal() == wx.ID_OK:
            filePath = openFileDialog.GetPaths()
            self.m_textCtrl2.SetValue(str(filePath))            
        openFileDialog.Destroy()
 
 
app = wx.App(False)
frame = MyFrame3(None)
frame.Show()
app.MainLoop()


dd='abc.docx'
dd1=dd[-5:]
print(dd1)

# file = open('C:\\Users\\mingfeng.zhou\\Desktop\\standard_mockup\\file_name.txt','w')
# file.write(str(filePath))
# file.close()
    

