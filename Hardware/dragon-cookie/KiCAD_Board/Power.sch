EESchema Schematic File Version 4
LIBS:KiCAD_Board-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 5 5
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
L Connector:Screw_Terminal_01x02 J?
U 1 1 601FC9BE
P 2325 2850
AR Path="/601FC9BE" Ref="J?"  Part="1" 
AR Path="/601FC125/601FC9BE" Ref="J501"  Part="1" 
F 0 "J501" H 2245 2525 50  0000 C CNN
F 1 "Screw_Terminal_01x02" H 2245 2616 50  0000 C CNN
F 2 "TerminalBlock:TerminalBlock_bornier-2_P5.08mm" H 2325 2850 50  0001 C CNN
F 3 "~" H 2325 2850 50  0001 C CNN
	1    2325 2850
	-1   0    0    1   
$EndComp
$Comp
L Device:Fuse F?
U 1 1 601FC9C5
P 2950 2750
AR Path="/601FC9C5" Ref="F?"  Part="1" 
AR Path="/601FC125/601FC9C5" Ref="F501"  Part="1" 
F 0 "F501" V 2753 2750 50  0000 C CNN
F 1 "Fuse" V 2844 2750 50  0000 C CNN
F 2 "Fuse:Fuse_1210_3225Metric_Castellated" V 2880 2750 50  0001 C CNN
F 3 "~" H 2950 2750 50  0001 C CNN
	1    2950 2750
	0    1    1    0   
$EndComp
Wire Wire Line
	2525 2750 2800 2750
$Comp
L power:GND #PWR?
U 1 1 601FC9CD
P 2625 3050
AR Path="/601FC9CD" Ref="#PWR?"  Part="1" 
AR Path="/601FC125/601FC9CD" Ref="#PWR0114"  Part="1" 
F 0 "#PWR0114" H 2625 2800 50  0001 C CNN
F 1 "GND" H 2630 2877 50  0000 C CNN
F 2 "" H 2625 3050 50  0001 C CNN
F 3 "" H 2625 3050 50  0001 C CNN
	1    2625 3050
	1    0    0    -1  
$EndComp
Wire Wire Line
	2525 2850 2625 2850
Wire Wire Line
	2625 2850 2625 3050
$Comp
L power:+VDC #PWR?
U 1 1 601FC9D5
P 3275 2700
AR Path="/601FC9D5" Ref="#PWR?"  Part="1" 
AR Path="/601FC125/601FC9D5" Ref="#PWR0115"  Part="1" 
F 0 "#PWR0115" H 3275 2600 50  0001 C CNN
F 1 "+VDC" H 3275 2975 50  0000 C CNN
F 2 "" H 3275 2700 50  0001 C CNN
F 3 "" H 3275 2700 50  0001 C CNN
	1    3275 2700
	1    0    0    -1  
$EndComp
Wire Wire Line
	3275 2700 3275 2750
Wire Wire Line
	3275 2750 3100 2750
$Comp
L XasParts:ROF-78E3.3-0.5SMD-R PWR501
U 1 1 601FD3D2
P 4000 3100
F 0 "PWR501" H 4000 3715 50  0000 C CNN
F 1 "ROF-78E3.3-0.5SMD-R" H 4000 3624 50  0000 C CNN
F 2 "XasPrints:ROF-78E" H 3900 2650 50  0001 C CNN
F 3 "https://recom-power.com/pdf/Innoline/ROF-78E-0.5.pdf" H 4000 2750 50  0001 C CNN
F 4 "945-1689-1-ND" H 4100 2850 50  0001 C CNN "DigiKey_PN"
	1    4000 3100
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0116
U 1 1 601FD529
P 4000 3325
F 0 "#PWR0116" H 4000 3075 50  0001 C CNN
F 1 "GND" H 4005 3152 50  0000 C CNN
F 2 "" H 4000 3325 50  0001 C CNN
F 3 "" H 4000 3325 50  0001 C CNN
	1    4000 3325
	1    0    0    -1  
$EndComp
Wire Wire Line
	4000 3325 4000 3300
Wire Wire Line
	3275 2750 3550 2750
Connection ~ 3275 2750
$Comp
L power:GND #PWR0117
U 1 1 601FDC22
P 3275 3350
F 0 "#PWR0117" H 3275 3100 50  0001 C CNN
F 1 "GND" H 3280 3177 50  0000 C CNN
F 2 "" H 3275 3350 50  0001 C CNN
F 3 "" H 3275 3350 50  0001 C CNN
	1    3275 3350
	1    0    0    -1  
$EndComp
Wire Wire Line
	4450 2750 4625 2750
Wire Wire Line
	4750 2750 4750 2600
$Comp
L power:+3.3V #PWR0118
U 1 1 601FE285
P 4750 2600
F 0 "#PWR0118" H 4750 2450 50  0001 C CNN
F 1 "+3.3V" H 4765 2773 50  0000 C CNN
F 2 "" H 4750 2600 50  0001 C CNN
F 3 "" H 4750 2600 50  0001 C CNN
	1    4750 2600
	1    0    0    -1  
$EndComp
NoConn ~ 4450 2850
$Comp
L Device:C C501
U 1 1 6036D28B
P 3275 3200
F 0 "C501" H 3390 3246 50  0000 L CNN
F 1 "10uF" H 3390 3155 50  0000 L CNN
F 2 "Capacitor_SMD:C_0805_2012Metric" H 3313 3050 50  0001 C CNN
F 3 "~" H 3275 3200 50  0001 C CNN
	1    3275 3200
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C502
U 1 1 60399841
P 2950 3200
F 0 "C502" H 3068 3246 50  0000 L CNN
F 1 "CP" H 3068 3155 50  0000 L CNN
F 2 "Capacitor_SMD:CP_Elec_10x12.6" H 2988 3050 50  0001 C CNN
F 3 "~" H 2950 3200 50  0001 C CNN
	1    2950 3200
	1    0    0    -1  
$EndComp
Wire Wire Line
	2950 3050 3275 3050
Wire Wire Line
	3275 2750 3275 3050
Connection ~ 3275 3050
$Comp
L power:GND #PWR0148
U 1 1 60399C1D
P 2950 3350
F 0 "#PWR0148" H 2950 3100 50  0001 C CNN
F 1 "GND" H 2955 3177 50  0000 C CNN
F 2 "" H 2950 3350 50  0001 C CNN
F 3 "" H 2950 3350 50  0001 C CNN
	1    2950 3350
	1    0    0    -1  
$EndComp
$Comp
L Device:D_Zener D501
U 1 1 603911DD
P 4625 2975
F 0 "D501" V 4579 3055 50  0000 L CNN
F 1 "D_Zener" V 4670 3055 50  0000 L CNN
F 2 "Diode_SMD:D_SOD-123F" H 4625 2975 50  0001 C CNN
F 3 "~" H 4625 2975 50  0001 C CNN
	1    4625 2975
	0    1    1    0   
$EndComp
Wire Wire Line
	4625 2825 4625 2750
Connection ~ 4625 2750
Wire Wire Line
	4625 2750 4750 2750
Wire Wire Line
	4625 3125 4625 3300
Wire Wire Line
	4625 3300 4000 3300
Connection ~ 4000 3300
Wire Wire Line
	4000 3300 4000 3250
$EndSCHEMATC
