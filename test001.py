import wx
import wx.xrc
import os
import traceback
###########################################################################
## Class MyFrame1
#Modification:Add protocol ID bosizer
###########################################################################

class MyFrame1 ( wx.Frame ):

	def __init__( self, parent ):
		wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = wx.EmptyString, pos = wx.DefaultPosition, size = wx.Size( 500,300 ), style = wx.DEFAULT_FRAME_STYLE|wx.TAB_TRAVERSAL )

		self.SetSizeHints( wx.DefaultSize, wx.DefaultSize )



		bSizer1 = wx.BoxSizer( wx.VERTICAL )

		gSizer2 = wx.GridSizer( 2, 0, 0, 0 )

		self.m_staticText1 = wx.StaticText( self, wx.ID_ANY, u"Project Name", wx.DefaultPosition, (200,28), 0 )
		self.m_staticText1.Wrap( -1 )

		gSizer2.Add( self.m_staticText1, 0, wx.ALL, 5 )

		self.m_textCtrl2 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, (150, 28), 0 )
		gSizer2.Add( self.m_textCtrl2, 0, wx.ALL, 5 )


		bSizer1.Add( gSizer2, 0, wx.ALL, 5 )


		# self.m_staticText1 = wx.StaticText( self, wx.ID_ANY, u"Project Name", wx.DefaultPosition, wx.DefaultSize, 0)
		# self.m_staticText1.Wrap( -1 )
		# bSizer1.Add( self.m_staticText1, 0, wx.ALL, 5 )

		self.m_button3 = wx.Button( self, wx.ID_ANY, u"Select File", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer1.Add( self.m_button3, 0, wx.ALL, 5 )

		self.m_textCtrl3 = wx.TextCtrl( self,  wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.TE_READONLY|wx.TE_MULTILINE)
		bSizer1.Add( self.m_textCtrl3, 1, wx.ALL|wx.EXPAND, 5 )

		self.m_button5 = wx.Button( self, wx.ID_ANY, u"Run", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer1.Add( self.m_button5, 0, wx.ALL, 5 )

		self.SetSizer( bSizer1 )
		self.Layout()
		self.m_menubar2 = wx.MenuBar( 0 )
		self.SetMenuBar( self.m_menubar2 )

		self.m_statusBar2 = self.CreateStatusBar( 1, wx.STB_SIZEGRIP, wx.ID_ANY )

		self.Centre( wx.BOTH )

		# Connect Events
		self.m_button3.Bind( wx.EVT_BUTTON, self.m_button3OnButtonClick )
		self.m_button5.Bind( wx.EVT_BUTTON, self.m_button5OnButtonClick )		

	def __del__( self ):
		pass

	# Virtual event handlers, overide them in your derived class
	def m_button3OnButtonClick(self, event):
		openFileDialog = wx.FileDialog(frame, "please select file", "", "",
									   "*.*",
									   wx.FD_OPEN | wx.FD_MULTIPLE)
		if openFileDialog.ShowModal() == wx.ID_OK:
			filePath = openFileDialog.GetDirectory()
			filename=openFileDialog.GetFilenames()
			self.m_textCtrl3.SetValue(filePath+'\n') 
			self.m_textCtrl3.AppendText('\n'.join(filename)) 

	def m_button5OnButtonClick(self, event):
			file_all=self.m_textCtrl3.GetValue()
			file_list=file_all.split('\n')
			files=[]
			docx_num=0
			xlsx_num=0
			for fl in file_list[1:]:
				files.append(os.path.join(file_list[0],fl))
				if fl[-5:]=='.docx':
					docx_num=docx_num+1
				if fl[-5:]=='.xlsx':
					xlsx_num=xlsx_num+1
			if docx_num==len(files):
				self.m_statusBar2.SetStatusText("Reading Mockup beginning ...")


app = wx.App(False)
frame = MyFrame1(None)
frame.Show()
app.MainLoop()