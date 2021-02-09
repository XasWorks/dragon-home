EESchema Schematic File Version 4
LIBS:KiCAD_Board-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 3 5
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Sensor_Humidity:Si7020-A20 U?
U 1 1 601F87E2
P 3350 2800
AR Path="/601F87E2" Ref="U?"  Part="1" 
AR Path="/601F78D4/601F87E2" Ref="U302"  Part="1" 
F 0 "U302" H 3625 2525 50  0000 L CNN
F 1 "Si7020-A20" H 3625 2450 50  0000 L CNN
F 2 "Package_DFN_QFN:DFN-6-1EP_3x3mm_P1mm_EP1.5x2.4mm" H 3350 2400 50  0001 C CNN
F 3 "https://www.silabs.com/documents/public/data-sheets/Si7020-A20.pdf" H 3150 3100 50  0001 C CNN
	1    3350 2800
	1    0    0    -1  
$EndComp
$Comp
L Sensor_Optical:LTR-303ALS-01 U?
U 1 1 601F87E9
P 3350 1400
AR Path="/601F87E9" Ref="U?"  Part="1" 
AR Path="/601F78D4/601F87E9" Ref="U301"  Part="1" 
F 0 "U301" H 3575 1025 50  0000 L CNN
F 1 "LTR-303ALS-01" H 3575 950 50  0000 L CNN
F 2 "OptoDevice:Lite-On_LTR-303ALS-01" H 3350 1850 50  0001 C CNN
F 3 "http://optoelectronics.liteon.com/upload/download/DS86-2013-0004/LTR-303ALS-01_DS_V1.pdf" H 3050 1750 50  0001 C CNN
	1    3350 1400
	1    0    0    -1  
$EndComp
$Comp
L Device:LED D?
U 1 1 601F96E5
P 3350 4575
AR Path="/601F96E5" Ref="D?"  Part="1" 
AR Path="/601F78D4/601F96E5" Ref="D301"  Part="1" 
F 0 "D301" V 3388 4457 50  0000 R CNN
F 1 "SFH 4240-Z" V 3297 4457 50  0000 R CNN
F 2 "XasPrints:SFH 4240" H 3350 4575 50  0001 C CNN
F 3 "~" H 3350 4575 50  0001 C CNN
	1    3350 4575
	0    -1   -1   0   
$EndComp
$Comp
L Device:Q_NMOS_GSD Q?
U 1 1 601F96EC
P 3250 5025
AR Path="/601F96EC" Ref="Q?"  Part="1" 
AR Path="/601F78D4/601F96EC" Ref="Q301"  Part="1" 
F 0 "Q301" H 3455 5071 50  0000 L CNN
F 1 "DMN3404L-7" H 3455 4980 50  0000 L CNN
F 2 "Package_TO_SOT_SMD:SOT-23" H 3450 5125 50  0001 C CNN
F 3 "~" H 3250 5025 50  0001 C CNN
	1    3250 5025
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 4725 3350 4825
$Comp
L power:GND #PWR?
U 1 1 601F96F4
P 3350 5300
AR Path="/601F96F4" Ref="#PWR?"  Part="1" 
AR Path="/601F78D4/601F96F4" Ref="#PWR0109"  Part="1" 
F 0 "#PWR0109" H 3350 5050 50  0001 C CNN
F 1 "GND" H 3355 5127 50  0000 C CNN
F 2 "" H 3350 5300 50  0001 C CNN
F 3 "" H 3350 5300 50  0001 C CNN
	1    3350 5300
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 5300 3350 5225
$Comp
L Device:R R?
U 1 1 601F96FB
P 3350 4150
AR Path="/601F96FB" Ref="R?"  Part="1" 
AR Path="/601F78D4/601F96FB" Ref="R301"  Part="1" 
F 0 "R301" H 3420 4196 50  0000 L CNN
F 1 "12R" H 3420 4105 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric" V 3280 4150 50  0001 C CNN
F 3 "~" H 3350 4150 50  0001 C CNN
	1    3350 4150
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 4300 3350 4425
$Comp
L power:+3.3V #PWR?
U 1 1 601F9703
P 3350 3925
AR Path="/601F9703" Ref="#PWR?"  Part="1" 
AR Path="/601F78D4/601F9703" Ref="#PWR0110"  Part="1" 
F 0 "#PWR0110" H 3350 3775 50  0001 C CNN
F 1 "+3.3V" H 3365 4098 50  0000 C CNN
F 2 "" H 3350 3925 50  0001 C CNN
F 3 "" H 3350 3925 50  0001 C CNN
	1    3350 3925
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 3925 3350 4000
Text Label 2575 5025 0    50   ~ 0
IR_SIG_OUT
Wire Wire Line
	2575 5025 3050 5025
$Comp
L dk_Optical-Sensors-Photo-Detectors-Remote-Receiver:TSSP58038 U303
U 1 1 601CCD99
P 5025 4600
F 0 "U303" H 5328 4646 50  0000 L CNN
F 1 "TSSP58038" H 5328 4555 50  0000 L CNN
F 2 "digikey-footprints:TO-92-3_Formed_Leads" H 5225 4800 60  0001 L CNN
F 3 "http://www.vishay.com/docs/82479/tssp58038.pdf" H 5225 4900 60  0001 L CNN
F 4 "TSSP58038-ND" H 5225 5000 60  0001 L CNN "Digi-Key_PN"
F 5 "TSOP322..." H 5225 5100 60  0001 L CNN "MPN"
F 6 "Sensors, Transducers" H 5225 5200 60  0001 L CNN "Category"
F 7 "Optical Sensors - Photo Detectors - Remote Receiver" H 5225 5300 60  0001 L CNN "Family"
F 8 "http://www.vishay.com/docs/82479/tssp58038.pdf" H 5225 5400 60  0001 L CNN "DK_Datasheet_Link"
F 9 "/product-detail/en/vishay-semiconductor-opto-division/TSSP58038/TSSP58038-ND/4695717" H 5225 5500 60  0001 L CNN "DK_Detail_Page"
F 10 "SENSOR REMOTE REC 38.0KHZ 25M" H 5225 5600 60  0001 L CNN "Description"
F 11 "Vishay Semiconductor Opto Division" H 5225 5700 60  0001 L CNN "Manufacturer"
F 12 "Active" H 5225 5800 60  0001 L CNN "Status"
	1    5025 4600
	1    0    0    -1  
$EndComp
Text GLabel 2675 2700 0    50   Input ~ 0
I2C_SDA
Text GLabel 2675 2900 0    50   Input ~ 0
I2C_SCL
Wire Wire Line
	2675 2700 2850 2700
Wire Wire Line
	2675 2900 2850 2900
Wire Wire Line
	3250 3100 3350 3100
$Comp
L power:GND #PWR0125
U 1 1 601CE540
P 3350 3100
F 0 "#PWR0125" H 3350 2850 50  0001 C CNN
F 1 "GND" H 3355 2927 50  0000 C CNN
F 2 "" H 3350 3100 50  0001 C CNN
F 3 "" H 3350 3100 50  0001 C CNN
	1    3350 3100
	1    0    0    -1  
$EndComp
Connection ~ 3350 3100
Wire Wire Line
	3350 3100 3450 3100
$Comp
L power:+3.3V #PWR0126
U 1 1 601CE68A
P 3350 2425
F 0 "#PWR0126" H 3350 2275 50  0001 C CNN
F 1 "+3.3V" H 3365 2598 50  0000 C CNN
F 2 "" H 3350 2425 50  0001 C CNN
F 3 "" H 3350 2425 50  0001 C CNN
	1    3350 2425
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 2425 3350 2500
$Comp
L power:+3.3V #PWR0127
U 1 1 601CE81A
P 3350 950
F 0 "#PWR0127" H 3350 800 50  0001 C CNN
F 1 "+3.3V" H 3365 1123 50  0000 C CNN
F 2 "" H 3350 950 50  0001 C CNN
F 3 "" H 3350 950 50  0001 C CNN
	1    3350 950 
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0128
U 1 1 601CE831
P 3350 1875
F 0 "#PWR0128" H 3350 1625 50  0001 C CNN
F 1 "GND" H 3355 1702 50  0000 C CNN
F 2 "" H 3350 1875 50  0001 C CNN
F 3 "" H 3350 1875 50  0001 C CNN
	1    3350 1875
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 1875 3350 1800
Wire Wire Line
	3350 1000 3350 950 
Text GLabel 2675 1300 0    50   Input ~ 0
I2C_SDA
Text GLabel 2675 1500 0    50   Input ~ 0
I2C_SCL
Wire Wire Line
	2675 1500 2950 1500
Wire Wire Line
	2675 1300 2950 1300
NoConn ~ 3750 1400
$EndSCHEMATC
