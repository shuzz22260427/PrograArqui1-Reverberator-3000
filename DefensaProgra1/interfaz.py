from funciones_aux import *
import PySimpleGUI as sg
from funciones_aux import *
import os

# Variables de audio
alpha = 0.6
k = 0.05

# Conversion variables
sample_rate = 44100
audio_bits = 8

file_name = "polka"
file_name2 = "tetris"

sg.theme('BlueMono')   # El color seleccionado para la interfaz

# Manejo primario de como van a estar ubicados los componentes dentro de la ventana. Son solo botones y labels
distribucion = [  [sg.Text('Audios iniciales')],
               [sg.Text('Audio 1 = Polka con eco'), sg.Button('Play Polka_eco')  ],
               [sg.Text('Audio 2 = Tetris'), sg.Button('Play Tetris') ],
               
               [sg.Text('Audios con procesos')],

               [sg.Text('Audio 1 procesado = Polka sin eco'), sg.Button('Play polka normal')],
               [sg.Text('Audio 2 procesado = Tetris con eco'), sg.Button('Play Tetris eco') ] ]

#Creacion de la ventana con nombre
window = sg.Window('Reverberator 3000', distribucion)

#Ciclo que mantiene la ventana funcionando a menos que yo la cierre
while True:
    #Se encarga de leer los inputs de la ventana
    event, values = window.read()
    if event == sg.WIN_CLOSED: # Si se cierra la ventana se sale del ciclo y se termina el while
        break
    if event == 'Play Polka_eco':
        playEcoSong(file_name)
    if event == 'Play Tetris':
        playSong(file_name2)
    if event == 'Play polka normal':
        wav_to_txt(file_name + '_eco',file_name + '_eco.txt', audio_bits)
        os.system('./Proga1_partex86NOECO')
        texto_sonido(file_name + '_noeco.txt', file_name + "_noeco", sample_rate, audio_bits)
        playSong(file_name + '_noeco')
    if event == 'Play Tetris eco':
        wav_to_txt(file_name2 , file_name2 + ".txt", audio_bits)
        os.system('./Proga1_partex86ECO')
        texto_sonido(file_name2 + '_eco.txt', file_name2 + "_eco", sample_rate, audio_bits)
        playSong(file_name2 + '_eco')

window.close()




