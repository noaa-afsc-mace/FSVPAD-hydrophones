# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\rtowler\AFSCsvn\CLAMS\trunk\application\acquisition\serial\ui\SerialConsole.ui'
#
# Created: Wed Nov 10 11:01:01 2010
#      by: PyQt4 UI code generator 4.8
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

class Ui_SerialConsole(object):
    def setupUi(self, SerialConsole):
        SerialConsole.setObjectName(_fromUtf8("SerialConsole"))
        SerialConsole.resize(387, 550)
        SerialConsole.setMinimumSize(QtCore.QSize(325, 550))
        self.centralwidget = QtGui.QWidget(SerialConsole)
        self.centralwidget.setObjectName(_fromUtf8("centralwidget"))
        self.verticalLayout = QtGui.QVBoxLayout(self.centralwidget)
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.label_2 = QtGui.QLabel(self.centralwidget)
        font = QtGui.QFont()
        font.setPointSize(14)
        self.label_2.setFont(font)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.verticalLayout.addWidget(self.label_2)
        self.dataText = QtGui.QTextBrowser(self.centralwidget)
        font = QtGui.QFont()
        font.setPointSize(14)
        self.dataText.setFont(font)
        self.dataText.setObjectName(_fromUtf8("dataText"))
        self.verticalLayout.addWidget(self.dataText)
        self.label = QtGui.QLabel(self.centralwidget)
        font = QtGui.QFont()
        font.setPointSize(14)
        self.label.setFont(font)
        self.label.setObjectName(_fromUtf8("label"))
        self.verticalLayout.addWidget(self.label)
        self.errText = QtGui.QTextBrowser(self.centralwidget)
        self.errText.setMaximumSize(QtCore.QSize(16777215, 100))
        font = QtGui.QFont()
        font.setPointSize(12)
        self.errText.setFont(font)
        self.errText.setObjectName(_fromUtf8("errText"))
        self.verticalLayout.addWidget(self.errText)
        SerialConsole.setCentralWidget(self.centralwidget)

        self.retranslateUi(SerialConsole)
        QtCore.QMetaObject.connectSlotsByName(SerialConsole)

    def retranslateUi(self, SerialConsole):
        SerialConsole.setWindowTitle(QtGui.QApplication.translate("SerialConsole", "Simple Serial Console", None, QtGui.QApplication.UnicodeUTF8))
        self.label_2.setText(QtGui.QApplication.translate("SerialConsole", "Serial Data (Device Name - Data)", None, QtGui.QApplication.UnicodeUTF8))
        self.label.setText(QtGui.QApplication.translate("SerialConsole", "Last Error", None, QtGui.QApplication.UnicodeUTF8))

